// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared

struct BrowserViewControllerState: ScreenState, Equatable {
    let windowUUID: WindowUUID
    var searchScreenState: SearchScreenState
    var showDataClearanceFlow: Bool
    var toolbarState: ToolbarState
    var fakespotState: FakespotState
    var toast: ToastType?
    var showOverlay: Bool
    var reloadWebView: Bool
    var browserViewType: BrowserViewType
    var navigateToHome: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let bvcState = store.state.screenState(
            BrowserViewControllerState.self,
            for: .browserViewController,
            window: uuid)
        else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(searchScreenState: bvcState.searchScreenState,
                  showDataClearanceFlow: bvcState.showDataClearanceFlow,
                  toolbarState: bvcState.toolbarState,
                  fakespotState: bvcState.fakespotState,
                  toast: bvcState.toast,
                  showOverlay: bvcState.showOverlay,
                  windowUUID: bvcState.windowUUID,
                  reloadWebView: bvcState.reloadWebView,
                  browserViewType: bvcState.browserViewType,
                  navigateToHome: bvcState.navigateToHome)
    }

    init(windowUUID: WindowUUID) {
        self.init(
            searchScreenState: SearchScreenState(),
            showDataClearanceFlow: false,
            toolbarState: ToolbarState(windowUUID: windowUUID),
            fakespotState: FakespotState(windowUUID: windowUUID),
            toast: nil,
            showOverlay: false,
            windowUUID: windowUUID,
            browserViewType: .normalHomepage,
            navigateToHome: false)
    }

    init(
        searchScreenState: SearchScreenState,
        showDataClearanceFlow: Bool,
        toolbarState: ToolbarState,
        fakespotState: FakespotState,
        toast: ToastType? = nil,
        showOverlay: Bool = false,
        windowUUID: WindowUUID,
        reloadWebView: Bool = false,
        browserViewType: BrowserViewType,
        navigateToHome: Bool = false
    ) {
        self.searchScreenState = searchScreenState
        self.showDataClearanceFlow = showDataClearanceFlow
        self.toolbarState = toolbarState
        self.fakespotState = fakespotState
        self.toast = toast
        self.windowUUID = windowUUID
        self.showOverlay = showOverlay
        self.reloadWebView = reloadWebView
        self.browserViewType = browserViewType
        self.navigateToHome = navigateToHome
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        if let action = action as? FakespotAction {
            return BrowserViewControllerState.reduceStateForFakeSpotAction(action: action, state: state)
        } else if let action = action as? PrivateModeAction {
            return BrowserViewControllerState.reduceStateForPrivateModeAction(action: action, state: state)
        } else if let action = action as? GeneralBrowserAction {
            return BrowserViewControllerState.reduceStateForGeneralBrowserAction(action: action, state: state)
        } else if let action = action as? ToolbarAction {
            return BrowserViewControllerState.reduceStateForToolbarAction(action: action, state: state)
        } else {
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                showOverlay: state.showOverlay,
                windowUUID: state.windowUUID,
                reloadWebView: false,
                browserViewType: state.browserViewType,
                navigateToHome: state.navigateToHome)
        }
    }

    static func reduceStateForFakeSpotAction(action: FakespotAction,
                                             state: BrowserViewControllerState) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            showDataClearanceFlow: state.showDataClearanceFlow,
            toolbarState: state.toolbarState,
            fakespotState: FakespotState.reducer(state.fakespotState, action),
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            navigateToHome: state.navigateToHome)
    }

    static func reduceStateForPrivateModeAction(action: PrivateModeAction,
                                                state: BrowserViewControllerState) -> BrowserViewControllerState {
        switch action.actionType {
        case PrivateModeActionType.privateModeUpdated:
            let privacyState = action.isPrivate ?? false
            var browserViewType = state.browserViewType
            if browserViewType != .webview {
                browserViewType = privacyState ? .privateHomepage : .normalHomepage
            }
            return BrowserViewControllerState(
                searchScreenState: SearchScreenState(inPrivateMode: privacyState),
                showDataClearanceFlow: privacyState,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                windowUUID: state.windowUUID,
                reloadWebView: true,
                browserViewType: browserViewType,
                navigateToHome: state.navigateToHome)
        default:
            return state
        }
    }

    static func reduceStateForGeneralBrowserAction(action: GeneralBrowserAction,
                                                   state: BrowserViewControllerState) -> BrowserViewControllerState {
        switch action.actionType {
        case GeneralBrowserActionType.showToast:
            guard let toastType = action.toastType else { return state }
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                toast: toastType,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateToHome: state.navigateToHome)
        case GeneralBrowserActionType.showOverlay:
            let showOverlay = action.showOverlay ?? false
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                showOverlay: showOverlay,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateToHome: state.navigateToHome)
        case GeneralBrowserActionType.updateSelectedTab:
            return BrowserViewControllerState.resolveStateForUpdateSelectedTab(action: action, state: state)
        case GeneralBrowserActionType.goToHomepage:
            let showHomepage = action.navigateToHome ?? false
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateToHome: showHomepage)

        default:
            return state
        }
    }

    static func reduceStateForToolbarAction(action: ToolbarAction,
                                            state: BrowserViewControllerState) -> BrowserViewControllerState {
        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: ToolbarState.reducer(state.toolbarState, action),
                fakespotState: state.fakespotState,
                showOverlay: state.showOverlay,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateToHome: state.navigateToHome)
        default:
            return state
        }
    }

    static func resolveStateForUpdateSelectedTab(action: GeneralBrowserAction,
                                                 state: BrowserViewControllerState) -> BrowserViewControllerState {
        let isAboutHomeURL = InternalURL(action.selectedTabURL)?.isAboutHomeURL ?? false
        var browserViewType = BrowserViewType.normalHomepage
        let isPrivateBrowsing = action.isPrivateBrowsing ?? false

        if isAboutHomeURL {
            browserViewType = isPrivateBrowsing ? .privateHomepage : .normalHomepage
        } else {
            browserViewType = .webview
        }

        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            showDataClearanceFlow: state.showDataClearanceFlow,
            toolbarState: state.toolbarState,
            fakespotState: state.fakespotState,
            showOverlay: state.showOverlay,
            windowUUID: state.windowUUID,
            reloadWebView: true,
            browserViewType: browserViewType,
            navigateToHome: state.navigateToHome)
    }
}
