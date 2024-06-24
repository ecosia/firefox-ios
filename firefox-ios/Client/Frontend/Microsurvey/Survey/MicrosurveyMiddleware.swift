// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

class MicrosurveyMiddleware {
    private let microsurveySurfaceManager: MicrosurveyManager

    init(microsurveySurfaceManager: MicrosurveyManager = AppContainer.shared.resolve()) {
        self.microsurveySurfaceManager = microsurveySurfaceManager
    }

    lazy var microsurveyProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
        switch action.actionType {
        case MicrosurveyActionType.closeSurvey:
            self.dismissSurvey(windowUUID: windowUUID)
        case MicrosurveyActionType.tapPrivacyNotice:
            self.navigateToPrivacyNotice(windowUUID: windowUUID)
        case MicrosurveyActionType.submitSurvey:
            self.sendTelemetryAndClosePrompt(windowUUID: windowUUID)
        default:
           break
        }
    }

    private func dismissSurvey(windowUUID: WindowUUID) {
        let newAction = MicrosurveyMiddlewareAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyMiddlewareActionType.dismissSurvey
        )
        store.dispatch(newAction)
        closeMicrosurveyPrompt(windowUUID: windowUUID)
        // TODO: FXIOS-8993 - Add Telemetry
    }

    private func navigateToPrivacyNotice(windowUUID: WindowUUID) {
        let newAction = MicrosurveyMiddlewareAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyMiddlewareActionType.navigateToPrivacyNotice
        )
        store.dispatch(newAction)
        // TODO: FXIOS-8993 - Add Telemetry
    }

    private func sendTelemetryAndClosePrompt(windowUUID: WindowUUID) {
        microsurveySurfaceManager.handleMessagePressed()
        closeMicrosurveyPrompt(windowUUID: windowUUID)
    }

    private func closeMicrosurveyPrompt(windowUUID: WindowUUID) {
        store.dispatch(
            MicrosurveyPromptAction(
                windowUUID: windowUUID,
                actionType: MicrosurveyPromptActionType.closePrompt
            )
        )
        // TODO: FXIOS-8993 - Add Telemetry
    }
}
