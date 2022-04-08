/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UIColor {
    struct Light {
        struct Background {
            static let primary = UIColor.white
            static let secondary = UIColor(red: 0.973, green: 0.973, blue: 0.965, alpha: 1)
            static let tertiary = UIColor(red: 0.941, green: 0.941, blue: 0.922, alpha: 1)
            static let quarternary = UIColor(red: 0.153, green: 0.322, blue: 0.263, alpha: 1)
        }
        
        struct Button {
            static let primary = UIColor(red: 0, green: 0.5, blue: 0.033, alpha: 1)
            static let primaryActive = UIColor(red: 0.153, green: 0.322, blue: 0.263, alpha: 1)
        }
        
        struct Text {
            static let primary = UIColor(red: 0.059, green: 0.059, blue: 0.059, alpha: 1)
            static let secondary = UIColor(red: 0.424, green: 0.424, blue: 0.424, alpha: 1)
        }

        struct State {
            static let warning = UIColor(red: 0.992, green: 0.259, blue: 0.337, alpha: 1)
            static let information = UIColor(red: 0, green: 0.494, blue: 0.659, alpha: 1)
        }
        
        static let border = UIColor(red: 0.871, green: 0.871, blue: 0.851, alpha: 1)
    }
    
    struct Dark {
        struct Background {
            static let primary = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
            static let secondary = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
            static let tertiary = UIColor(red: 0.298, green: 0.298, blue: 0.298, alpha: 1)
            static let quarternary = UIColor(red: 0.686, green: 0.914, blue: 0.69, alpha: 1)
        }
        
        struct Button {
            static let primary = UIColor(red: 0.365, green: 0.824, blue: 0.369, alpha: 1)
            static let primaryActive = UIColor(red: 0.686, green: 0.914, blue: 0.69, alpha: 1)
        }
        
        struct Text {
            static let primary = UIColor.white
            static let secondary = UIColor(red: 0.871, green: 0.871, blue: 0.851, alpha: 1)
        }

        public struct State {
            static let warning = UIColor(red: 1.0, green: 0.541, blue: 0.549, alpha: 1)
            static let information = UIColor(red: 0.589, green: 0.839, blue: 0.973, alpha: 1)
        }
        
        static let border = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1)
    }
}
