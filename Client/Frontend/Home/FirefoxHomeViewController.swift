/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit
import Storage
import SDWebImage
import XCGLogger
import SyncTelemetry
import SnapKit
import Core

private let log = Logger.browserLogger

// MARK: -  Lifecycle
struct FirefoxHomeUX {
    static let rowSpacing: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 30 : 20
    static let highlightCellHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 250 : 200
    static let sectionInsetsForSizeClass = UXSizeClasses(compact: 0, regular: 101, other: 16)
    static let numberOfItemsPerRowForSizeClassIpad = UXSizeClasses(compact: 3, regular: 4, other: 2)
    static let SectionInsetsForIpad: CGFloat = 101
    static let SectionInsetsForIphone: CGFloat = 16
    static let MinimumInsets: CGFloat = 16
    static let TopSitesInsets: CGFloat = 6
    static let LibraryShortcutsHeight: CGFloat = 100
    static let LibraryShortcutsMaxWidth: CGFloat = 350
    static let SearchBarHeight: CGFloat = 56
    static var ToolbarHeight: CGFloat {
        (UIDevice.current.userInterfaceIdiom == .phone && UIDevice.current.orientation.isPortrait) ? 46 : 0
    }
}
/*
 Size classes are the way Apple requires us to specify our UI.
 Split view on iPad can make a landscape app appear with the demensions of an iPhone app
 Use UXSizeClasses to specify things like offsets/itemsizes with respect to size classes
 For a primer on size classes https://useyourloaf.com/blog/size-classes/
 */
struct UXSizeClasses {
    var compact: CGFloat
    var regular: CGFloat
    var unspecified: CGFloat

    init(compact: CGFloat, regular: CGFloat, other: CGFloat) {
        self.compact = compact
        self.regular = regular
        self.unspecified = other
    }

    subscript(sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
        switch sizeClass {
            case .compact:
                return self.compact
            case .regular:
                return self.regular
            case .unspecified:
                return self.unspecified
            @unknown default:
                fatalError()
        }

    }
}

protocol HomePanelDelegate: AnyObject {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
    func homePanel(didSelectURL url: URL, visitType: VisitType)
    func homePanelDidRequestToOpenLibrary(panel: LibraryPanelType)
}

protocol HomePanel: Themeable {
    var homePanelDelegate: HomePanelDelegate? { get set }
}

enum HomePanelType: Int {
    case topSites = 0

    var internalUrl: URL {
        let aboutUrl: URL! = URL(string: "\(InternalURL.baseUrl)/\(AboutHomeHandler.path)")
        return URL(string: "#panel=\(self.rawValue)", relativeTo: aboutUrl)!
    }
}

protocol HomePanelContextMenu {
    func getSiteDetails(for indexPath: IndexPath) -> Site?
    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]?
    func presentContextMenu(for indexPath: IndexPath)
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?)
}

extension HomePanelContextMenu {
    func presentContextMenu(for indexPath: IndexPath) {
        guard let site = getSiteDetails(for: indexPath) else { return }

        presentContextMenu(for: site, with: indexPath, completionHandler: {
            return self.contextMenu(for: site, with: indexPath)
        })
    }

    func contextMenu(for site: Site, with indexPath: IndexPath) -> PhotonActionSheet? {
        guard let actions = self.getContextMenuActions(for: site, with: indexPath) else { return nil }

        let contextMenu = PhotonActionSheet(site: site, actions: actions)
        contextMenu.modalPresentationStyle = .overFullScreen
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }

    func getDefaultContextMenuActions(for site: Site, homePanelDelegate: HomePanelDelegate?) -> [PhotonActionSheetItem]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let openInNewTabAction = PhotonActionSheetItem(title: Strings.OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { _, _ in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
        }

        let openInNewPrivateTabAction = PhotonActionSheetItem(title: Strings.OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _, _ in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        return [openInNewTabAction, openInNewPrivateTabAction]
    }
}

protocol FirefoxHomeViewControllerDelegate: AnyObject {
    func home(_ home: FirefoxHomeViewController, didScroll contentOffset: CGFloat, offset: CGFloat)
    func homeDidTapSearchButton(_ home: FirefoxHomeViewController)
    func home(_ home: FirefoxHomeViewController, willBegin drag: CGPoint)
    func homeDidPressPersonalCounter(_ home: FirefoxHomeViewController)
}

class FirefoxHomeViewController: UICollectionViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?
    weak var delegate: FirefoxHomeViewControllerDelegate?
    fileprivate let profile: Profile
    fileprivate let pocketAPI = Pocket()
    fileprivate let flowLayout = UICollectionViewFlowLayout()
    fileprivate weak var searchbarCell: UICollectionViewCell?
    fileprivate weak var libraryCell: UICollectionViewCell?
    fileprivate weak var topSitesCell: UICollectionViewCell? {
        didSet { collectionView.collectionViewLayout.invalidateLayout() }
    }

    fileprivate lazy var topSitesManager: ASHorizontalScrollCellManager = {
        let manager = ASHorizontalScrollCellManager()
        return manager
    }()

    fileprivate lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    // Not used for displaying. Only used for calculating layout.
    lazy var topSiteCell: ASHorizontalScrollCell = {
        let customCell = ASHorizontalScrollCell(frame: CGRect(width: self.view.frame.size.width, height: 0))
        customCell.delegate = self.topSitesManager
        return customCell
    }()

    var pocketStories: [PocketStory] = []

    init(profile: Profile, delegate: FirefoxHomeViewControllerDelegate?) {
        self.profile = profile
        self.delegate = delegate
        super.init(collectionViewLayout: flowLayout)
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
        self.collectionView?.alwaysBounceVertical = true

        collectionView?.addGestureRecognizer(longPressRecognizer)

        let refreshEvents: [Notification.Name] = [.DynamicFontChanged, .HomePanelPrefsChanged]
        refreshEvents.forEach { NotificationCenter.default.addObserver(self, selector: #selector(reload), name: $0, object: nil) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Section.allCases.forEach { self.collectionView?.register(Section($0.rawValue).cellType, forCellWithReuseIdentifier: Section($0.rawValue).cellIdentifier) }
        self.collectionView?.register(ASHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        self.collectionView?.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "EmptyHeader")
        self.collectionView?.register(ASFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer")
        collectionView?.keyboardDismissMode = .onDrag

        self.view.backgroundColor = UIColor.theme.ecosia.primaryBackground
        self.profile.panelDataObservers.activityStream.delegate = self

        applyTheme()

        if showPromo {
            Analytics.shared.defaultBrowser(.view)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadAll()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if inOverlayMode, let cell = libraryCell {
            collectionView.contentOffset = .init(x: 0, y: cell.frame.minY - FirefoxHomeUX.SearchBarHeight)
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {context in
            //The AS context menu does not behave correctly. Dismiss it when rotating.
            if let _ = self.presentedViewController as? PhotonActionSheet {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }
            self.collectionViewLayout.invalidateLayout()
            self.collectionView?.reloadData()
        }, completion: { _ in
            // Workaround: label positions are not correct without additional reload
            self.collectionView?.reloadData()
        })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.topSitesManager.currentTraits = self.traitCollection
    }

    @objc func reload(notification: Notification) {
        reloadAll()
    }

    func applyTheme() {
        collectionView?.backgroundColor = UIColor.theme.ecosia.primaryBackground
        self.view.backgroundColor = UIColor.theme.ecosia.primaryBackground
        topSiteCell.collectionView.reloadData()
        collectionView.reloadData()
    }

    func scrollToTop(animated: Bool = false) {
        collectionView?.setContentOffset(.zero, animated: animated)
    }

    var inOverlayMode = false {
        didSet {
            guard isViewLoaded else { return }
            if inOverlayMode && !oldValue, let libraryCell = libraryCell {
                UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState], animations: { [weak self] in
                    self?.collectionView.contentOffset = .init(x: 0, y: libraryCell.frame.minY - FirefoxHomeUX.SearchBarHeight)
                })
            } else if oldValue && !inOverlayMode && !collectionView.isDragging {
                UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState], animations: { [weak self] in
                    self?.collectionView.contentOffset = .zero
                })
            }
        }
    }

    private var showPromo: Bool {
        guard #available(iOS 14.0, *) else { return false }
        return !UserDefaults.standard.bool(forKey: "DidDismissDefaultBrowserCard")
    }

}

// MARK: -  Section management
extension FirefoxHomeViewController {
    enum Section: Int, CaseIterable {
        case promo
        case personalCounter
        case logo
        case search
        case treeCounter
        case libraryShortcuts
        case topSites
        case emptySpace

        var title: String? {
            switch self {
            case .topSites: return Strings.ASTopSitesTitle
            default: return nil
            }
        }

        var headerHeight: CGSize {
            switch self {
            case .logo:
                return CGSize(width: 50, height: 30)
            case .topSites:
                return CGSize(width: 50, height: 54)
            case .libraryShortcuts:
                return CGSize(width: 50, height: 10)
            default:
                return .zero
            }
        }

        func cellHeight(_ traits: UITraitCollection, width: CGFloat) -> CGFloat {
            switch self {
            case .personalCounter: return UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption2).pointSize + 28 + 32
            case .promo: return 230
            case .logo: return 100
            case .search: return UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).pointSize + 25 + 16
            case .treeCounter:
                return 30 + UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline).pointSize + 2 + 16 //TODO: make dynamic
            case .topSites: return 0 //calculated dynamically
            case .libraryShortcuts: return FirefoxHomeUX.LibraryShortcutsHeight
            case .emptySpace:
                return .nan // will be calculated outside of enum
            }
        }

        /*
         There are edge cases to handle when calculating section insets
        - An iPhone 7+ is considered regular width when in landscape
        - An iPad in 66% split view is still considered regular width
         */
        func sectionInsets(_ traits: UITraitCollection, frameWidth: CGFloat) -> CGFloat {
            var currentTraits = traits
            if (traits.horizontalSizeClass == .regular && UIApplication.shared.statusBarOrientation.isPortrait) || UIDevice.current.userInterfaceIdiom == .phone {
                currentTraits = UITraitCollection(horizontalSizeClass: .compact)
            }
            var insets = FirefoxHomeUX.sectionInsetsForSizeClass[currentTraits.horizontalSizeClass]

            switch self {
            case .libraryShortcuts, .topSites, .promo, .search, .personalCounter:
                let window = UIApplication.shared.keyWindow
                let safeAreaInsets = window?.safeAreaInsets.left ?? 0
                insets += FirefoxHomeHeaderViewUX.Insets + safeAreaInsets
                
                /* Ecosia: center layout in landscape for iPhone */
                if UIApplication.shared.statusBarOrientation.isLandscape, UIDevice.current.userInterfaceIdiom == .phone {
                    insets = frameWidth / 4
                }
                
                return insets
            case .treeCounter, .logo:
                insets += FirefoxHomeUX.TopSitesInsets
                return insets
            case .emptySpace:
                return 0
            }
        }

        func cellSize(for traits: UITraitCollection, frameWidth: CGFloat) -> CGSize {
            let height = cellHeight(traits, width: frameWidth)
            let inset = sectionInsets(traits, frameWidth: frameWidth) * 2
            return CGSize(width: frameWidth - inset, height: height)
        }

        var cellIdentifier: String {
            return "\(cellType)"
        }

        var cellType: UICollectionViewCell.Type {
            switch self {
            case .personalCounter: return PersonalCounterCell.self
            case .promo: return DefaultBrowserCard.self
            case .logo: return LogoCell.self
            case .search: return SearchbarCell.self
            case .topSites: return ASHorizontalScrollCell.self
            case .treeCounter: return TreeCounterCell.self
            case .libraryShortcuts: return ASLibraryCell.self
            case .emptySpace: return EmptyCell.self
            }
        }

        init(at indexPath: IndexPath) {
            self.init(rawValue: indexPath.section)!
        }

        init(_ section: Int) {
            self.init(rawValue: section)!
        }
    }
}

// MARK: -  Tableview Delegate
extension FirefoxHomeViewController: UICollectionViewDelegateFlowLayout {

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        guard kind == UICollectionView.elementKindSectionHeader, Section(indexPath.section) == .topSites else {
            return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "EmptyHeader", for: indexPath)
        }

        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! ASHeaderView
        let title = Section(indexPath.section).title
        view.title = title
        view.titleLabel.accessibilityIdentifier = "topSitesTitle"
        return view
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.longPressRecognizer.isEnabled = false

        switch Section(rawValue: indexPath.section) {
        case .personalCounter:
            delegate?.homeDidPressPersonalCounter(self)
            collectionView.deselectItem(at: indexPath, animated: true)
        default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize = Section(indexPath.section).cellSize(for: self.traitCollection, frameWidth: self.view.frame.width)

        switch Section(indexPath.section) {
        case .treeCounter, .promo, .search, .logo, .personalCounter:
            return cellSize
        case .topSites:
            // Create a temporary cell so we can calculate the height.
            let layout = topSiteCell.collectionView.collectionViewLayout as! HorizontalFlowLayout
            let estimatedLayout = layout.calculateLayout(for: CGSize(width: cellSize.width, height: 0))
            return CGSize(width: cellSize.width, height: estimatedLayout.size.height)
        case .libraryShortcuts:
            let width = min(FirefoxHomeUX.LibraryShortcutsMaxWidth, cellSize.width)
            return CGSize(width: width, height: FirefoxHomeUX.LibraryShortcutsHeight)
        case .emptySpace:
            guard let libraryCell = libraryCell else { return .zero }
            let offset = libraryCell.frame.minY + Section.libraryShortcuts.headerHeight.height
            let barHeight: CGFloat = FirefoxHomeUX.SearchBarHeight
            let filledHeight = User.shared.topSites == false ? libraryCell.frame.maxY : topSitesCell?.frame.maxY
            let height = collectionView.frame.height - (filledHeight ?? 0) + offset - barHeight - FirefoxHomeUX.ToolbarHeight
            return .init(width: cellSize.width, height: max(0, height))
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch Section(section) {
        case .promo, .emptySpace, .logo, .personalCounter:
            return .zero
        case .treeCounter, .search:
            return Section(section).headerHeight
        case .topSites:
            return topSitesManager.content.isEmpty ? .zero : Section(section).headerHeight
        case .libraryShortcuts:
            return UIDevice.current.userInterfaceIdiom == .pad ? CGSize.zero : Section(section).headerHeight
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return FirefoxHomeUX.rowSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let insets = Section(section).sectionInsets(self.traitCollection, frameWidth: self.view.frame.width)
        return UIEdgeInsets(top: 0, left: insets, bottom: 0, right: insets)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let searchbarCell = searchbarCell else { return }
        delegate?.home(self, didScroll: searchbarCell.frame.minY, offset: scrollView.contentOffset.y)
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView.superview)
        delegate?.home(self, willBegin: velocity)

    }

    fileprivate func showSiteWithURLHandler(_ url: URL) {
        let visitType = VisitType.bookmark
        
        switch url.absoluteString {
        case Environment.current.blog.absoluteString:
            Analytics.shared.open(topSite: .blog)
        case Environment.current.financialReports.absoluteString:
            Analytics.shared.open(topSite: .financialReports)
        case Environment.current.privacy.absoluteString:
            Analytics.shared.open(topSite: .privacy)
        case Environment.current.howEcosiaWorks.absoluteString:
            Analytics.shared.open(topSite: .howEcosiaWorks)
        default:
            break
        }
        
        homePanelDelegate?.homePanel(didSelectURL: url, visitType: visitType)
    }
}

// MARK: - Tableview Data Source
extension FirefoxHomeViewController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numItems: CGFloat = FirefoxHomeUX.numberOfItemsPerRowForSizeClassIpad[self.traitCollection.horizontalSizeClass]
        if UIApplication.shared.statusBarOrientation.isPortrait {
            numItems = numItems - 1
        }
        if self.traitCollection.horizontalSizeClass == .compact && UIApplication.shared.statusBarOrientation.isLandscape {
            numItems = numItems - 1
        }
        switch Section(section) {
        case .personalCounter:
            return 1
        case .promo:
            return showPromo ? 1 : 0
        case .topSites:
            return (topSitesManager.content.isEmpty || User.shared.topSites == false) ? 0 : 1
        case .treeCounter, .search, .emptySpace, .logo:
            return 1
        case .libraryShortcuts:
            // disable the libary shortcuts on the ipad
            return UIDevice.current.userInterfaceIdiom == .pad ? 0 : 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = Section(indexPath.section).cellIdentifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)

        switch Section(indexPath.section) {
        case .promo:
            if let card = cell as? DefaultBrowserCard {
                card.dismissClosure = { [weak self] in
                    self?.collectionView.reloadSections([0, 1])
                }
            }
            return cell
        case .topSites:
            let topSitesCell = configureTopSitesCell(cell, forIndexPath: indexPath)
            self.topSitesCell = topSitesCell
            return topSitesCell
        case .search:
            (cell as? SearchbarCell)?.delegate = self
            searchbarCell = cell
            return cell
        case .treeCounter, .emptySpace, .logo, .personalCounter:
            return cell
        case .libraryShortcuts:
            let libraryCell = configureLibraryShortcutsCell(cell, forIndexPath: indexPath)
            self.libraryCell = libraryCell
            return libraryCell
        }
    }

    func configureLibraryShortcutsCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let libraryCell = cell as! ASLibraryCell
        // Ecosia: open history instead of sync
        let targets = [#selector(openBookmarks), #selector(openHistory), #selector(openReadingList), #selector(openDownloads)]
        libraryCell.libraryButtons.map({ $0.button }).zip(targets).forEach { (button, selector) in
            button.removeTarget(nil, action: nil, for: .allEvents)
            button.addTarget(self, action: selector, for: .touchUpInside)
        }
        libraryCell.applyTheme()
        return cell
    }

    //should all be collectionview
    func configureTopSitesCell(_ cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let topSiteCell = cell as! ASHorizontalScrollCell
        topSiteCell.delegate = self.topSitesManager
        topSiteCell.setNeedsLayout()
        topSiteCell.collectionView.reloadData()
        return cell
    }

}

// MARK: - Data Management
extension FirefoxHomeViewController: DataObserverDelegate {

    // Reloads both highlights and top sites data from their respective caches. Does not invalidate the cache.
    // See ActivityStreamDataObserver for invalidation logic.
    func reloadAll() {
        // If the pocket stories are not availible for the Locale the PocketAPI will return nil
        // So it is okay if the default here is true

        TopSitesHandler.getTopSites(profile: profile).uponQueue(.main) { result in
            // If there is no pending cache update and highlights are empty. Show the onboarding screen
            self.collectionView?.reloadData()
            
            self.topSitesManager.currentTraits = self.view.traitCollection
            
            let numRows = max(self.profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows, 1)
            
            let maxItems = Int(numRows) * self.topSitesManager.numberOfHorizontalItems()
            
            self.topSitesManager.content = Array(result.prefix(maxItems))
            
            self.topSitesManager.urlPressedHandler = { [unowned self] url, indexPath in
                self.longPressRecognizer.isEnabled = false
                self.showSiteWithURLHandler(url as URL)
            }

            self.getPocketSites().uponQueue(.main) { _ in
                if !self.pocketStories.isEmpty {
                    self.collectionView?.reloadData()
                }
            }
            // Refresh the AS data in the background so we'll have fresh data next time we show.
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: false)
        }
    }

    func getPocketSites() -> Success {
        let showPocket = (profile.prefs.boolForKey(PrefsKeys.ASPocketStoriesVisible) ?? Pocket.IslocaleSupported(Locale.current.identifier))
        guard showPocket else {
            self.pocketStories = []
            return succeed()
        }

        return pocketAPI.globalFeed(items: 10).bindQueue(.main) { pStory in
            self.pocketStories = pStory
            return succeed()
        }
    }

    @objc func showMorePocketStories() {
        showSiteWithURLHandler(Pocket.MoreStoriesURL)
    }

    // Invoked by the ActivityStreamDataObserver when highlights/top sites invalidation is complete.
    func didInvalidateDataSources(refresh forced: Bool, topSitesRefreshed: Bool) {
        // Do not reload panel unless we're currently showing the highlight intro or if we
        // force-reloaded the highlights or top sites. This should prevent reloading the
        // panel after we've invalidated in the background on the first load.
        if forced {
            reloadAll()
        }
    }

    func hideURLFromTopSites(_ site: Site) {
        guard let host = site.tileURL.normalizedHost else {
            return
        }
        let url = site.tileURL.absoluteString
        // if the default top sites contains the siteurl. also wipe it from default suggested sites.
        if defaultTopSites().filter({$0.url == url}).isEmpty == false {
            deleteTileForSuggestedSite(url)
        }
        profile.history.removeHostFromTopSites(host).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
        }
    }

    func pinTopSite(_ site: Site) {
        profile.history.addPinnedTopSite(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
        }
    }

    func removePinTopSite(_ site: Site) {
        profile.history.removeFromPinnedTopSites(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
        }
    }

    fileprivate func deleteTileForSuggestedSite(_ siteURL: String) {
        var deletedSuggestedSites = profile.prefs.arrayForKey(TopSitesHandler.DefaultSuggestedSitesKey) as? [String] ?? []
        deletedSuggestedSites.append(siteURL)
        profile.prefs.setObject(deletedSuggestedSites, forKey: TopSitesHandler.DefaultSuggestedSitesKey)
    }

    func defaultTopSites() -> [Site] {
        let suggested = SuggestedSites.asArray()
        let deleted = profile.prefs.arrayForKey(TopSitesHandler.DefaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({deleted.firstIndex(of: $0.url) == .none})
    }

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        let point = longPressGestureRecognizer.location(in: self.collectionView)
        guard let indexPath = self.collectionView?.indexPathForItem(at: point) else { return }

        switch Section(indexPath.section) {
        case .topSites:
            let topSiteCell = self.collectionView?.cellForItem(at: indexPath) as! ASHorizontalScrollCell
            let pointInTopSite = longPressGestureRecognizer.location(in: topSiteCell.collectionView)
            guard let topSiteIndexPath = topSiteCell.collectionView.indexPathForItem(at: pointInTopSite) else { return }
            presentContextMenu(for: IndexPath(item: topSiteIndexPath.item, section: indexPath.section))
        default:
            break
        }
    }

    fileprivate func fetchBookmarkStatus(for site: Site, with indexPath: IndexPath, forSection section: Section, completionHandler: @escaping () -> Void) {
        profile.places.isBookmarked(url: site.url).uponQueue(.main) { result in
            let isBookmarked = result.successValue ?? false
            site.setBookmarked(isBookmarked)
            completionHandler()
        }
    }

}

extension FirefoxHomeViewController {
    @objc func openBookmarks() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .bookmarks)
        Analytics.shared.browser(.open, label: .favourites, property: .home)
    }

    @objc func openHistory() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .history)
        Analytics.shared.browser(.open, label: .history, property: .home)
    }

    @objc func openSyncedTabs() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .syncedTabs)
        Analytics.shared.browser(.open, label: .tabs, property: .home)
    }

    @objc func openReadingList() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .readingList)
    }

    @objc func openDownloads() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .downloads)
    }
}

extension FirefoxHomeViewController: HomePanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {

        fetchBookmarkStatus(for: site, with: indexPath, forSection: Section(indexPath.section)) {
            guard let contextMenu = completionHandler() else { return }
            self.present(contextMenu, animated: true, completion: nil)
        }
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        switch Section(indexPath.section) {
        case .topSites:
            return topSitesManager.content[indexPath.item]
        default:
            return nil
        }
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]? {
        guard let siteURL = URL(string: site.url) else { return nil }
        var sourceView: UIView?
        switch Section(indexPath.section) {
        case .topSites:
            if let topSiteCell = self.collectionView?.cellForItem(at: IndexPath(row: 0, section: 0)) as? ASHorizontalScrollCell {
                sourceView = topSiteCell.collectionView.cellForItem(at: indexPath)
            }
        default:
            return nil
        }

        let openInNewTabAction = PhotonActionSheetItem(title: Strings.OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { _, _ in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
            let source = ["Source": "Activity Stream Long Press Context Menu"]
            LeanPlumClient.shared.track(event: .openedNewTab, withParameters: source)
            Analytics.shared.browser(.open, label: .newTab, property: .menu)
        }

        let openInNewPrivateTabAction = PhotonActionSheetItem(title: Strings.OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _, _ in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        let bookmarkAction: PhotonActionSheetItem
        if site.bookmarked ?? false {
            bookmarkAction = PhotonActionSheetItem(title: Strings.RemoveBookmarkContextMenuTitle, iconString: "action_bookmark_remove", handler: { _, _ in
                self.profile.places.deleteBookmarksWithURL(url: site.url) >>== {
                    self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: false)
                    site.setBookmarked(false)
                }

                TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .bookmark, value: .activityStream)
                Analytics.shared.browser(.delete, label: .favourites, property: .home)
            })
        } else {
            bookmarkAction = PhotonActionSheetItem(title: Strings.BookmarkContextMenuTitle, iconString: "action_bookmark", handler: { _, _ in
                let shareItem = ShareItem(url: site.url, title: site.title, favicon: site.icon)
                _ = self.profile.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID, url: shareItem.url, title: shareItem.title)

                var userData = [QuickActions.TabURLKey: shareItem.url]
                if let title = shareItem.title {
                    userData[QuickActions.TabTitleKey] = title
                }
                QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                                    withUserData: userData,
                                                                                    toApplication: .shared)
                site.setBookmarked(true)
                self.profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)
                LeanPlumClient.shared.track(event: .savedBookmark)
                TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .activityStream)
                Analytics.shared.browser(.add, label: .favourites, property: .home)
            })
        }

        let shareAction = PhotonActionSheetItem(title: Strings.ShareContextMenuTitle, iconString: "action_share", handler: { _, _ in
            let helper = ShareExtensionHelper(url: siteURL, tab: nil)
            let controller = helper.createActivityViewController({ (_, _) in })
            if UI_USER_INTERFACE_IDIOM() == .pad, let popoverController = controller.popoverPresentationController {
                let cellRect = sourceView?.frame ?? .zero
                let cellFrameInSuperview = self.collectionView?.convert(cellRect, to: self.collectionView) ?? .zero

                popoverController.sourceView = sourceView
                popoverController.sourceRect = CGRect(origin: CGPoint(x: cellFrameInSuperview.size.width/2, y: cellFrameInSuperview.height/2), size: .zero)
                popoverController.permittedArrowDirections = [.up, .down, .left]
                popoverController.delegate = self
            }
            self.present(controller, animated: true, completion: nil)
        })

        let removeTopSiteAction = PhotonActionSheetItem(title: Strings.RemoveContextMenuTitle, iconString: "action_remove", handler: { _, _ in
            self.hideURLFromTopSites(site)
        })

        let pinTopSite = PhotonActionSheetItem(title: Strings.PinTopsiteActionTitle, iconString: "action_pin", handler: { _, _ in
            self.pinTopSite(site)
        })

        let removePinTopSite = PhotonActionSheetItem(title: Strings.RemovePinTopsiteActionTitle, iconString: "action_unpin", handler: { _, _ in
            self.removePinTopSite(site)
        })

        let topSiteActions: [PhotonActionSheetItem]
        if let _ = site as? PinnedSite {
            topSiteActions = [removePinTopSite]
        } else {
            topSiteActions = [pinTopSite, removeTopSiteAction]
        }

        var actions = [openInNewTabAction, openInNewPrivateTabAction, bookmarkAction, shareAction]

        switch Section(indexPath.section) {
            case .topSites: actions.append(contentsOf: topSiteActions)
            default: break
        }
        return actions
    }
}

extension FirefoxHomeViewController: UIPopoverPresentationControllerDelegate {

    // Dismiss the popover if the device is being rotated.
    // This is used by the Share UIActivityViewController action sheet on iPad
    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        popoverPresentationController.presentedViewController.dismiss(animated: false, completion: nil)
    }
}

// MARK: - Section Header View
private struct FirefoxHomeHeaderViewUX {
    static var SeparatorColor: UIColor { return UIColor.theme.homePanel.separator }
    static let TextFont = DynamicFontHelper.defaultHelper.SmallSizeHeavyWeightAS
    static let ButtonFont = DynamicFontHelper.defaultHelper.MediumSizeBoldFontAS
    static let SeparatorHeight = 0.5
    static let Insets: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeUX.SectionInsetsForIpad + FirefoxHomeUX.MinimumInsets : FirefoxHomeUX.MinimumInsets
    static let TitleTopInset: CGFloat = 5
}

class ASFooterView: UICollectionReusableView {

    var separatorLineView: UIView?
    var leftConstraint: Constraint? //This constraint aligns content (Titles, buttons) between all sections.

    override init(frame: CGRect) {
        super.init(frame: frame)

        let separatorLine = UIView()
        self.backgroundColor = UIColor.clear
        addSubview(separatorLine)
        separatorLine.snp.makeConstraints { make in
            make.height.equalTo(FirefoxHomeHeaderViewUX.SeparatorHeight)
            leftConstraint = make.leading.equalTo(self.safeArea.leading).inset(insets).constraint
            make.trailing.equalTo(self.safeArea.trailing).inset(insets)
            make.top.equalTo(self.snp.top)
        }
        separatorLineView = separatorLine
        applyTheme()
    }

    var insets: CGFloat {
        return UIScreen.main.bounds.size.width == self.frame.size.width && UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeHeaderViewUX.Insets : FirefoxHomeUX.MinimumInsets
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        separatorLineView?.isHidden = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // update the insets every time a layout happens.Insets change depending on orientation or size (ipad split screen)
        leftConstraint?.update(offset: insets)
    }
}

extension ASFooterView: Themeable {
    func applyTheme() {
        separatorLineView?.backgroundColor = FirefoxHomeHeaderViewUX.SeparatorColor
    }
}

class ASHeaderView: UICollectionReusableView {
    static let verticalInsets: CGFloat = 8

    lazy fileprivate var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.theme.ecosia.highContrastText
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()

    /* Ecosia: no more button
    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.titleLabel?.font = FirefoxHomeHeaderViewUX.ButtonFont
        button.contentHorizontalAlignment = .right
        button.setTitleColor(UIConstants.SystemBlueColor, for: .normal)
        button.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
        return button
    }()
    */

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var leftConstraint: Constraint?
    var rightConstraint: Constraint?

    var titleInsets: CGFloat {
        // Ecosia: synchronize titleInsets for header and sectionInsets
        return FirefoxHomeViewController.Section.topSites.sectionInsets(self.traitCollection, frameWidth: UIScreen.main.bounds.width)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Ecosia: moreButton.isHidden = true
        // Ecosia: moreButton.setTitle(nil, for: .normal)
        // Ecosia: moreButton.accessibilityIdentifier = nil;
        titleLabel.text = nil
        // Ecosia: moreButton.removeTarget(nil, action: nil, for: .allEvents)
        titleLabel.textColor = UIColor.theme.ecosia.highContrastText
        // Ecosia: moreButton.setTitleColor(UIConstants.SystemBlueColor, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        /* Ecosia
        addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.top.equalTo(self.snp.top).offset(ASHeaderView.verticalInsets)
            make.bottom.equalToSuperview().offset(-ASHeaderView.verticalInsets)
            self.rightConstraint = make.trailing.equalTo(self.safeArea.trailing).inset(-titleInsets).constraint
        }
        moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        */
        titleLabel.snp.makeConstraints { make in
            self.leftConstraint = make.leading.equalTo(self.snp.leading).inset(titleInsets).constraint
            self.rightConstraint = make.trailing.equalTo(self.snp.trailing).inset(-titleInsets).priority(.high).constraint
            make.top.equalTo(self.snp.top).inset(32)
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        leftConstraint?.update(offset: titleInsets)
        rightConstraint?.update(offset: -titleInsets)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LibraryShortcutView: UIView {
    static let spacing: CGFloat = 16
    static let iconSize: CGFloat = 42

    var button = UIButton()
    var title = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(button)
        addSubview(title)
        button.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LibraryShortcutView.spacing/2.0)
            make.centerX.equalToSuperview()
            make.width.equalTo(LibraryShortcutView.iconSize + LibraryShortcutView.spacing)
            make.height.equalTo(LibraryShortcutView.iconSize + LibraryShortcutView.spacing)
        }
        title.allowsDefaultTighteningForTruncation = true
        title.lineBreakMode = .byTruncatingTail
        title.font = .preferredFont(forTextStyle: .footnote)
        title.adjustsFontForContentSizeCategory = true
        title.textAlignment = .center
        title.numberOfLines = 2
        title.setContentHuggingPriority(.required, for: .vertical)
        title.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(0)
            let maxHeight = title.font.pointSize * 2.6
            make.leading.trailing.equalToSuperview().inset(2).priority(.veryHigh)
            make.height.lessThanOrEqualTo(maxHeight)
        }
        button.imageView?.contentMode = .scaleToFill
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(equalInset: LibraryShortcutView.spacing/2.0)
        button.tintColor = .white
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class ASLibraryCell: UICollectionViewCell, Themeable {

    var mainView = UIStackView()

    struct LibraryPanel {
        let title: String
        let image: UIImage?
        let color: UIColor
    }

    var libraryButtons: [LibraryShortcutView] = []

    let bookmarks = LibraryPanel(title: Strings.AppMenuBookmarksTitleString, image: UIImage(named: "libraryFavorites"), color: UIColor.Photon.Yellow60)
    let history = LibraryPanel(title: Strings.AppMenuHistoryTitleString, image: UIImage(named: "libraryHistory"), color: UIColor.Photon.Teal60)
    let readingList = LibraryPanel(title: Strings.AppMenuReadingListTitleString, image: UIImage(named: "libraryReading"), color: UIColor.Photon.Blue60)
    let downloads = LibraryPanel(title: Strings.AppMenuDownloadsTitleString, image: UIImage(named: "libraryDownloads"), color: UIColor.Photon.Purple60)

    override init(frame: CGRect) {
        super.init(frame: frame)
        mainView.distribution = .fillEqually
        mainView.spacing = 0
        addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        // Ecosia: Show history instead of synced tabs
        [bookmarks, history, readingList, downloads].forEach { item in
            let view = LibraryShortcutView()
            view.button.setImage(item.image, for: .normal)
            view.title.text = item.title
            let words = view.title.text?.components(separatedBy: NSCharacterSet.whitespacesAndNewlines).count
            view.title.numberOfLines = words == 1 ? 1 : 2
            // view.button.backgroundColor = item.color
            view.button.setTitleColor(UIColor.theme.ecosia.highContrastText, for: .normal)
            view.accessibilityLabel = item.title
            mainView.addArrangedSubview(view)
            libraryButtons.append(view)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        libraryButtons.forEach { button in
            button.title.textColor = UIColor.theme.ecosia.highContrastText
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}

extension FirefoxHomeViewController: SearchbarCellDelegate {
    func searchbarCellPressed(_ cell: SearchbarCell) {
        delegate?.homeDidTapSearchButton(self)
    }
}
