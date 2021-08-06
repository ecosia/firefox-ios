/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core
import MozillaAppServices
import Shared

final class EcosiaFavourites {
    static func migrate(profile: Profile, progress: ((Double) -> ())? = nil, finished: @escaping (Result<Void, EcosiaImport.Failure>) -> ()){

        if let error = profile.places.reopenIfClosed() {
            finished(.failure(.init(reasons: [error])))
            return
        }

        profile.places.getBookmarksTree(rootGUID: BookmarkRoots.MobileFolderGUID, recursive: true).uponQueue(.main) { result in

            if case .failure(let error) = result {
                finished(.failure(.init(reasons: [error])))
            }

            guard let folder = result.successValue as? BookmarkFolder, let children = folder.children else {
                finished(.success(()))
                return
            }

            let nodes = folder.recursiveChildren()
            let items = nodes.compactMap({ $0 as? BookmarkItem })

            let pages: [Core.Page] = items.compactMap({
                guard let url = URL(string: $0.url) else { return nil }
                return Core.Page(url: url, title: $0.title)
            })
            debugPrint("FAVOURITES IMPORTED: \(pages.count)")

            Core.Favourites().items = pages
            finished(.success(()))
        }
    }
}

extension BookmarkNode {
    func recursiveChildren() -> [BookmarkItem] {
        if let item = self as? BookmarkItem {
            return [item]
        }

        if let folder = self as? BookmarkFolder {
            return folder.children?.reduce([BookmarkItem](), { items, node in
                items + node.recursiveChildren()
            }) ?? []
        }

        return []
    }
}
