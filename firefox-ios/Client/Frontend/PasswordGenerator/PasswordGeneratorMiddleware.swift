// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

final class PasswordGeneratorMiddleware {
    private let logger: Logger = DefaultLogger.shared
    lazy var passwordGeneratorProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
        guard let currentTab = (action as? PasswordGeneratorAction)?.currentTab else { return }
        switch action.actionType {
        case PasswordGeneratorActionType.showPasswordGenerator:
            self.showPasswordGenerator(tab: currentTab, windowUUID: windowUUID)
        default:
            break
        }
    }

    private func showPasswordGenerator(tab: Tab, windowUUID: WindowUUID) {
       generateNewPassword(with: tab, completion: { generatedPassword in
           let newAction = PasswordGeneratorAction(
               windowUUID: windowUUID,
               actionType: PasswordGeneratorActionType.updateGeneratedPassword,
               password: generatedPassword
           )
           store.dispatch(newAction)
       })
    }

    private func generateNewPassword(with tab: Tab, completion: @escaping (String) -> Void) {
            let jsFunctionCall = "window.__firefox__.logins.generatePassword()"
            tab.webView?.evaluateJavascriptInDefaultContentWorld(jsFunctionCall) { (result, error) in
                if let error = error {
                    self.logger.log("JavaScript evaluation error",
                                    level: .warning,
                                    category: .webview,
                                    description: "\(error.localizedDescription)")
                } else if let result = result as? String {
                    completion(result)
                }
            }
        }
}
