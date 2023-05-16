// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared
import Core

class BookmarksPanelViewModel: NSObject {

    enum BookmarksSection: Int, CaseIterable {
        case bookmarks
    }

    var isRootNode: Bool {
        return bookmarkFolderGUID == BookmarkRoots.MobileFolderGUID
    }

    let profile: Profile
    let bookmarkFolderGUID: GUID
    var bookmarkFolder: FxBookmarkNode?
    var bookmarkNodes = [FxBookmarkNode]()
    private var flashLastRowOnNextReload = false
    private let bookmarksExchange: BookmarksExchangable
    private var documentPickerPresentingViewController: UIViewController?
    private var onImportDoneHandler: ((URL?, Error?) -> Void)?
    private var onExportDoneHandler: ((Error?) -> Void)?
    
    /// Error case at the moment is setting data to nil and showing nothing
    private func setErrorCase() {
        self.bookmarkFolder = nil
        self.bookmarkNodes = []
    }

    /// By default our root folder is the mobile folder. Desktop folders are shown in the local desktop folders.
    init(
        profile: Profile,
        bookmarkFolderGUID: GUID = BookmarkRoots.MobileFolderGUID
    ) {
        self.profile = profile
        self.bookmarkFolderGUID = bookmarkFolderGUID
        self.bookmarksExchange = BookmarksExchange(profile: profile)
    }

    var shouldFlashRow: Bool {
        guard flashLastRowOnNextReload else { return false }
        flashLastRowOnNextReload = false

        return true
    }

    func reloadData(completion: @escaping () -> Void) {
        // Can be called while app backgrounded and the db closed, don't try to reload the data source in this case
        if profile.isShutdown { return }

        if bookmarkFolderGUID == BookmarkRoots.MobileFolderGUID {
            setupMobileFolderData(completion: completion)

        } else if bookmarkFolderGUID == LocalDesktopFolder.localDesktopFolderGuid {
            setupLocalDesktopFolderData(completion: completion)

        } else {
            setupSubfolderData(completion: completion)
        }
    }

    func didAddBookmarkNode() {
        flashLastRowOnNextReload = true
    }
    
    func bookmarkExportSelected(in viewController: BookmarksPanel, onDone: @escaping (Error?) -> Void) {
        Task {
            self.onExportDoneHandler = onDone
            do {
                let bookmarks = try await getBookmarksForExport()
                try await bookmarksExchange.export(bookmarks: bookmarks, in: viewController, barButtonItem: viewController.moreButton)
                await notifyExportDone(nil)
            } catch {
                await notifyExportDone(error)
            }
        }
    }
    
    func bookmarkImportSelected(in viewController: UIViewController, onDone: @escaping (URL?, Error?) -> Void) {
        self.documentPickerPresentingViewController = viewController
        self.onImportDoneHandler = onDone
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.html"], in: .open)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = self
        viewController.present(documentPicker, animated: true)
    }

    // MARK: - Private
    private func getBookmarksForExport() async throws -> [Core.BookmarkItem] {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                return continuation.resume(returning: [])
            }
            
            profile.places
                .getBookmarksTree(rootGUID: BookmarkRoots.MobileFolderGUID, recursive: true)
                .uponQueue(.main) { result in
                    guard let mobileFolder = result.successValue as? BookmarkFolderData else {
                        self.setErrorCase()
                        return
                    }

                    self.bookmarkFolder = mobileFolder
                    let bookmarkNodes = mobileFolder.fxChildren ?? []

                    let items: [Core.BookmarkItem] = bookmarkNodes
                        .compactMap { $0 as? BookmarkNodeData }
                        .compactMap { bookmarkNode in
                            self.exportNode(bookmarkNode)
                        }
                    
                    continuation.resume(returning: items)
                }
        }
    }
    
    private func exportNode(_ node: BookmarkNodeData) -> Core.BookmarkItem? {
        if let folder = node as? BookmarkFolderData {
            return .folder(folder.title, folder.children?.compactMap { exportNode($0) } ?? [], .empty)
        } else if let bookmark = node as? BookmarkItemData {
            return .bookmark(bookmark.title, bookmark.url, .empty)
        }
        assertionFailure("This should not happen")
        return nil
    }
    
    @MainActor
    private func notifyExportDone(_ error: Error?) {
        onExportDoneHandler?(error)
    }
    
    private func setupMobileFolderData(completion: @escaping () -> Void) {
        profile.places
            .getBookmarksTree(rootGUID: BookmarkRoots.MobileFolderGUID, recursive: false)
            .uponQueue(.main) { result in
                guard let mobileFolder = result.successValue as? BookmarkFolderData else {
                    self.setErrorCase()
                    return
                }

                self.bookmarkFolder = mobileFolder
                self.bookmarkNodes = mobileFolder.fxChildren ?? []

                /* Ecosia: remove desktop folder
                let desktopFolder = LocalDesktopFolder()
                self.bookmarkNodes.insert(desktopFolder, at: 0)
                 */
                completion()
            }
    }

    /// Local desktop folder data is a folder that only exists locally in the application
    /// It contains the three desktop folder of "unfiled", "menu" and "toolbar"
    private func setupLocalDesktopFolderData(completion: () -> Void) {
        let unfiled = LocalDesktopFolder(forcedGuid: BookmarkRoots.UnfiledFolderGUID)
        let toolbar = LocalDesktopFolder(forcedGuid: BookmarkRoots.ToolbarFolderGUID)
        let menu = LocalDesktopFolder(forcedGuid: BookmarkRoots.MenuFolderGUID)

        self.bookmarkFolder = nil
        self.bookmarkNodes = [unfiled, toolbar, menu]
        completion()
    }

    /// Subfolder data case happens when we select a folder created by a user
    private func setupSubfolderData(completion: @escaping () -> Void) {
        profile.places.getBookmarksTree(rootGUID: bookmarkFolderGUID,
                                        recursive: false).uponQueue(.main) { result in
            guard let folder = result.successValue as? BookmarkFolderData else {
                self.setErrorCase()
                return
            }

            self.bookmarkFolder = folder
            self.bookmarkNodes = folder.fxChildren ?? []

            completion()
        }
    }
}

extension BookmarksPanelViewModel: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.onImportDoneHandler?(nil, nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard
            let firstHtmlUrl = urls.first,
            let viewController = documentPickerPresentingViewController
        else { return }
        handlePickedUrl(firstHtmlUrl, in: viewController)
    }
    
    func handlePickedUrl(_ url: URL, in viewController: UIViewController) {
        guard url.startAccessingSecurityScopedResource() else { return }
        Task {
            do {
                try await bookmarksExchange.import(from: url, in: viewController)
                await notifyImportDone(url, nil)
            } catch {
                await notifyImportDone(url, error)
            }
        }
    }
    
    @MainActor
    private func notifyImportDone(_ url: URL, _ error: Error?) {
        onImportDoneHandler?(url, error)
    }
}
