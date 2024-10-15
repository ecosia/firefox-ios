// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

final class HomepageAction: Action {
    var navigationDestination: HomepageState.NavigationDestination?

    override init(windowUUID: WindowUUID, actionType: any ActionType) {
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum HomepageActionType: ActionType {
    case initialize
    case tappedOnCustomizeHomepage
}
