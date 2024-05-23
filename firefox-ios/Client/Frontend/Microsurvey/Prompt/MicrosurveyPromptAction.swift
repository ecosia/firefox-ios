// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

class MicrosurveyPromptAction: Action { }
class MicrosurveyPromptMiddlewareAction: Action { }

enum MicrosurveyPromptActionType: ActionType {
    case showPrompt
    case closePrompt
    case continueToSurvey
}

enum MicrosurveyPromptMiddlewareActionType: ActionType {
    case initialize(MicrosurveyModel)
    case dismissPrompt
    case openSurvey
}
