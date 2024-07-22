// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

class ToolbarAction: Action {
    let addressToolbarModel: AddressToolbarModel?
    let navigationToolbarModel: NavigationToolbarModel?
    let toolbarPosition: AddressToolbarPosition?
    let numberOfTabs: Int?
    let url: URL?
    let isPrivate: Bool?
    let badgeImageName: String?
    let isShowingNavigationToolbar: Bool?
    let isShowingTopTabs: Bool?
    let canGoBack: Bool?
    let canGoForward: Bool?

    init(addressToolbarModel: AddressToolbarModel? = nil,
         navigationToolbarModel: NavigationToolbarModel? = nil,
         toolbarPosition: AddressToolbarPosition? = nil,
         numberOfTabs: Int? = nil,
         url: URL? = nil,
         isPrivate: Bool? = nil,
         badgeImageName: String? = nil,
         isShowingNavigationToolbar: Bool? = nil,
         isShowingTopTabs: Bool? = nil,
         canGoBack: Bool? = nil,
         canGoForward: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.addressToolbarModel = addressToolbarModel
        self.navigationToolbarModel = navigationToolbarModel
        self.toolbarPosition = toolbarPosition
        self.numberOfTabs = numberOfTabs
        self.url = url
        self.isPrivate = isPrivate
        self.badgeImageName = badgeImageName
        self.isShowingNavigationToolbar = isShowingNavigationToolbar
        self.isShowingTopTabs = isShowingTopTabs
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarActionType: ActionType {
    case didLoadToolbars
    case numberOfTabsChanged
    case addressToolbarActionsDidChange
    case urlDidChange
    case backForwardButtonStatesChanged
    case scrollOffsetChanged
    case toolbarPositionChanged
    case showMenuWarningBadge
}

class ToolbarMiddlewareAction: Action {
    let buttonType: ToolbarActionState.ActionType?
    let buttonTapped: UIButton?
    let gestureType: ToolbarButtonGesture?
    let isLoading: Bool?
    let isShowingTopTabs: Bool?
    let isShowingNavigationToolbar: Bool?
    let lockIconImageName: String?
    let numberOfTabs: Int?
    let url: URL?
    let canGoBack: Bool?
    let canGoForward: Bool?
    let badgeImageName: String?

    init(buttonType: ToolbarActionState.ActionType? = nil,
         buttonTapped: UIButton? = nil,
         gestureType: ToolbarButtonGesture? = nil,
         isLoading: Bool? = nil,
         isShowingTopTabs: Bool? = nil,
         isShowingNavigationToolbar: Bool? = nil,
         lockIconImageName: String? = nil,
         numberOfTabs: Int? = nil,
         url: URL? = nil,
         canGoBack: Bool? = nil,
         canGoForward: Bool? = nil,
         badgeImageName: String? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.buttonType = buttonType
        self.buttonTapped = buttonTapped
        self.gestureType = gestureType
        self.isLoading = isLoading
        self.isShowingTopTabs = isShowingTopTabs
        self.isShowingNavigationToolbar = isShowingNavigationToolbar
        self.lockIconImageName = lockIconImageName
        self.numberOfTabs = numberOfTabs
        self.url = url
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.badgeImageName = badgeImageName
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarMiddlewareActionType: ActionType {
    case didTapButton
    case numberOfTabsChanged
    case urlDidChange
    case didStartEditingUrl
    case cancelEdit
    case websiteLoadingStateDidChange
    case traitCollectionDidChange
    case backButtonStateChanged
    case forwardButtonStateChanged
    case showMenuWarningBadge
}
