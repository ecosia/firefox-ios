// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

struct ToolbarState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var toolbarPosition: AddressToolbarPosition
    var isPrivateMode: Bool
    var addressToolbar: AddressBarState
    var navigationToolbar: NavigationBarState
    let isShowingNavigationToolbar: Bool
    let isShowingTopTabs: Bool
    let canGoBack: Bool
    let canGoForward: Bool
    var numberOfTabs: Int
    var showMenuWarningBadge: Bool
    var isNewTabFeatureEnabled: Bool
    var canShowDataClearanceAction: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let toolbarState = store.state.screenState(
            ToolbarState.self,
            for: .toolbar,
            window: uuid)
        else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: toolbarState.windowUUID,
                  toolbarPosition: toolbarState.toolbarPosition,
                  isPrivateMode: toolbarState.isPrivateMode,
                  addressToolbar: toolbarState.addressToolbar,
                  navigationToolbar: toolbarState.navigationToolbar,
                  isShowingNavigationToolbar: toolbarState.isShowingNavigationToolbar,
                  isShowingTopTabs: toolbarState.isShowingTopTabs,
                  canGoBack: toolbarState.canGoBack,
                  canGoForward: toolbarState.canGoForward,
                  numberOfTabs: toolbarState.numberOfTabs,
                  showMenuWarningBadge: toolbarState.showMenuWarningBadge,
                  isNewTabFeatureEnabled: toolbarState.isNewTabFeatureEnabled,
                  canShowDataClearanceAction: toolbarState.canShowDataClearanceAction)
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            toolbarPosition: .top,
            isPrivateMode: false,
            addressToolbar: AddressBarState(windowUUID: windowUUID),
            navigationToolbar: NavigationBarState(windowUUID: windowUUID),
            isShowingNavigationToolbar: true,
            isShowingTopTabs: false,
            canGoBack: false,
            canGoForward: false,
            numberOfTabs: 1,
            showMenuWarningBadge: false,
            isNewTabFeatureEnabled: false,
            canShowDataClearanceAction: false
        )
    }

    init(
        windowUUID: WindowUUID,
        toolbarPosition: AddressToolbarPosition,
        isPrivateMode: Bool,
        addressToolbar: AddressBarState,
        navigationToolbar: NavigationBarState,
        isShowingNavigationToolbar: Bool,
        isShowingTopTabs: Bool,
        canGoBack: Bool,
        canGoForward: Bool,
        numberOfTabs: Int,
        showMenuWarningBadge: Bool,
        isNewTabFeatureEnabled: Bool,
        canShowDataClearanceAction: Bool
    ) {
        self.windowUUID = windowUUID
        self.toolbarPosition = toolbarPosition
        self.isPrivateMode = isPrivateMode
        self.addressToolbar = addressToolbar
        self.navigationToolbar = navigationToolbar
        self.isShowingNavigationToolbar = isShowingNavigationToolbar
        self.isShowingTopTabs = isShowingTopTabs
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.numberOfTabs = numberOfTabs
        self.showMenuWarningBadge = showMenuWarningBadge
        self.isNewTabFeatureEnabled = isNewTabFeatureEnabled
        self.canShowDataClearanceAction = canShowDataClearanceAction
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            guard let toolbarAction = action as? ToolbarAction,
                  let toolbarPosition = toolbarAction.toolbarPosition
            else { return state }

            let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: position,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: state.numberOfTabs,
                showMenuWarningBadge: state.showMenuWarningBadge,
                isNewTabFeatureEnabled: toolbarAction.isNewTabFeatureEnabled ?? state.isNewTabFeatureEnabled,
                canShowDataClearanceAction: toolbarAction.canShowDataClearanceAction ?? state.canShowDataClearanceAction)

        case ToolbarActionType.borderPositionChanged,
            ToolbarActionType.urlDidChange,
            ToolbarActionType.didSetTextInLocationView,
            ToolbarActionType.didPasteSearchTerm,
            ToolbarActionType.didStartEditingUrl,
            ToolbarActionType.cancelEdit,
            ToolbarActionType.didScrollDuringEdit,
            ToolbarActionType.websiteLoadingStateDidChange,
            ToolbarActionType.searchEngineDidChange:
            guard let toolbarAction = action as? ToolbarAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
                isShowingNavigationToolbar: toolbarAction.isShowingNavigationToolbar ?? state.isShowingNavigationToolbar,
                isShowingTopTabs: toolbarAction.isShowingTopTabs ?? state.isShowingTopTabs,
                canGoBack: toolbarAction.canGoBack ?? state.canGoBack,
                canGoForward: toolbarAction.canGoForward ?? state.canGoForward,
                numberOfTabs: state.numberOfTabs,
                showMenuWarningBadge: state.showMenuWarningBadge,
                isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
                canShowDataClearanceAction: state.canShowDataClearanceAction)

        case ToolbarActionType.showMenuWarningBadge:
            guard let toolbarAction = action as? ToolbarAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: state.numberOfTabs,
                showMenuWarningBadge: toolbarAction.showMenuWarningBadge ?? state.showMenuWarningBadge,
                isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
                canShowDataClearanceAction: state.canShowDataClearanceAction)

        case ToolbarActionType.numberOfTabsChanged:
            guard let toolbarAction = action as? ToolbarAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: toolbarAction.numberOfTabs ?? state.numberOfTabs,
                showMenuWarningBadge: state.showMenuWarningBadge,
                isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
                canShowDataClearanceAction: state.canShowDataClearanceAction)

        case GeneralBrowserActionType.updateSelectedTab:
            guard let action = action as? GeneralBrowserAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: action.isPrivateBrowsing ?? state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, action),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, action),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: state.numberOfTabs,
                showMenuWarningBadge: state.showMenuWarningBadge,
                isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
                canShowDataClearanceAction: state.canShowDataClearanceAction)

        case ToolbarActionType.toolbarPositionChanged:
            guard let toolbarPosition = (action as? ToolbarAction)?.toolbarPosition else { return state }
            let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: position,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, action),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, action),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: state.numberOfTabs,
                showMenuWarningBadge: state.showMenuWarningBadge,
                isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
                canShowDataClearanceAction: state.canShowDataClearanceAction)

        case ToolbarActionType.readerModeStateChanged:
            guard let toolbarAction = action as? ToolbarAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: state.numberOfTabs,
                showMenuWarningBadge: state.showMenuWarningBadge,
                isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
                canShowDataClearanceAction: state.canShowDataClearanceAction)

        case ToolbarActionType.backButtonStateChanged,
            ToolbarActionType.forwardButtonStateChanged:
            guard let toolbarAction = action as? ToolbarAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                canGoBack: toolbarAction.canGoBack ?? state.canGoBack,
                canGoForward: toolbarAction.canGoForward ?? state.canGoForward,
                numberOfTabs: state.numberOfTabs,
                showMenuWarningBadge: state.showMenuWarningBadge,
                isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
                canShowDataClearanceAction: state.canShowDataClearanceAction)

        case ToolbarActionType.traitCollectionDidChange:
            guard let toolbarAction = action as? ToolbarAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: toolbarAction.isShowingTopTabs ?? state.isShowingTopTabs,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: state.numberOfTabs,
                showMenuWarningBadge: state.showMenuWarningBadge,
                isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
                canShowDataClearanceAction: state.canShowDataClearanceAction)

        default:
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: state.addressToolbar,
                navigationToolbar: state.navigationToolbar,
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: state.numberOfTabs,
                showMenuWarningBadge: state.showMenuWarningBadge,
                isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
                canShowDataClearanceAction: state.canShowDataClearanceAction)
        }
    }

    private static func addressToolbarPositionFromSearchBarPosition(_ position: SearchBarPosition)
    -> AddressToolbarPosition {
        switch position {
        case .top: return .top
        case .bottom: return .bottom
        }
    }
}
