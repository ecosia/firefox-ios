// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct HomepageState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var loadInitialData: Bool
    var headerState: HeaderState

    init(appState: AppState, uuid: WindowUUID) {
        guard let homepageState = store.state.screenState(
            HomepageState.self,
            for: .homepage,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: homepageState.windowUUID,
            loadInitialData: homepageState.loadInitialData,
            headerState: homepageState.headerState
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            loadInitialData: false,
            headerState: HeaderState(windowUUID: windowUUID)
        )
    }

    private init(
        windowUUID: WindowUUID,
        loadInitialData: Bool,
        headerState: HeaderState
    ) {
        self.windowUUID = windowUUID
        self.loadInitialData = loadInitialData
        self.headerState = headerState
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return HomepageState(
                windowUUID: state.windowUUID,
                loadInitialData: false,
                headerState: HeaderState.reducer(state.headerState, action)
            )
        }

        switch action.actionType {
        case HomepageActionType.initialize:
            return HomepageState(
                windowUUID: state.windowUUID,
                loadInitialData: true,
                headerState: HeaderState.reducer(state.headerState, action)
            )
        case HeaderActionType.updateHeader:
            return HomepageState(
                windowUUID: state.windowUUID,
                loadInitialData: false,
                headerState: HeaderState.reducer(state.headerState, action)
            )
        default:
            return HomepageState(
                windowUUID: state.windowUUID,
                loadInitialData: false,
                headerState: HeaderState.reducer(state.headerState, action)
            )
        }
    }
}
