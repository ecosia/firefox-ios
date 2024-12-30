// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// This struct defines all the standard image identifiers of icons and images used in the app.
/// When adding new identifiers, please respect alphabetical order.
/// Sing the song if you must.
public struct StandardImageIdentifiers {
    // Icon size 16x16
    public struct Small {
        public static let pinBadgeFill = "pinBadgeFillSmall"
    }

    // Icon size 20x20
    public struct Medium {
        public static let bookmarkBadgeFillBlue50 = "bookmarkBadgeFillMediumBlue50"
        public static let cross = "crossMedium"
    }

    // Icon size 24x24
    public struct Large {
        public static let appendUp = "appendUpLarge"
        /* Ecosia: Update App Menu to looklike Vanilla v104
        public static let appMenu = "appMenuLarge"
        */
        public static let appMenu = "nav-menu"
        public static let avatarCircle = "avatarCircleLarge"
        public static let back = "backLarge"
        /* Ecosia: Bookmarks Review
        public static let bookmark = "bookmarkLarge"
        public static let bookmarkFill = "bookmarkFillLarge"
        public static let bookmarkSlash = "bookmarkSlashLarge"
        public static let bookmarkTrayFill = "bookmarkTrayFillLarge"
        */
        public static let bookmark = "bookmarksEmpty"
        public static let bookmarkFill = "bookmarkFill"
        public static let bookmarkSlash = "bookmarkFill"
        public static let bookmarkTrayFill = "bookmarksEmpty"
        public static let checkmark = "checkmarkLarge"
        public static let chevronDown = "chevronDownLarge"
        public static let chevronLeft = "chevronLeftLarge"
        public static let chevronRight = "chevronRightLarge"
        public static let chevronUp = "chevronUpLarge"
        public static let clipboard = "clipboardLarge"
        public static let competitiveness = "competitivenessLarge"
        public static let creditCard = "creditCardLarge"
        public static let criticalFill = "criticalFillLarge"
        public static let cross = "crossLarge"
        public static let delete = "deleteLarge"
        /* Ecosia: Review Device icons
        public static let deviceDesktop = "deviceDesktopLarge"
        public static let deviceDesktopSend = "deviceDesktopSendLarge"
        public static let deviceMobile = "deviceMobileLarge"
        */
        public static let deviceDesktop = "menu-RequestDesktopSite"
        public static let deviceDesktopSend = "menu-Send-to-Device"
        public static let deviceMobile = "menu-ViewMobile"
        public static let download = "downloadLarge"
        public static let edit = "editLarge"
        public static let folder = "folderLarge"
        public static let forward = "forwardLarge"
        public static let globe = "globeLarge"
        public static let helpCircle = "helpCircleLarge"
        public static let history = "historyLarge"
        public static let home = "homeLarge"
        /* Ecosia: Update lock button
        public static let lock = "lockLarge"
        */
        public static let lock = "secureLock"
        public static let lockSlash = "lockSlashLarge"
        public static let logoFirefox = "logoFirefoxLarge"
        public static let lightbulb = "lightbulbLarge"
        public static let link = "linkLarge"
        public static let login = "loginLarge"
        public static let packaging = "packagingLarge"
        public static let pin = "pinLarge"
        public static let pinSlash = "pinSlashLarge"
        public static let plus = "plusLarge"
        public static let price = "priceLarge"
        public static let quality = "qualityLarge"
        public static let qrCode = "qrCodeLarge"
        public static let shipping = "shippingLarge"
        public static let shopping = "shoppingLarge"
        /* Ecosia: Update tabTray image name
        public static let tabTray = "tabTrayLarge"
        */
        public static let tabTray = "recentlyClosed"
        public static let warningFill = "warningFillLarge"
    }

    // Icon size 30x30
    public struct ExtraLarge {
        public static let crossCircleFill = "crossCircleFillExtraLarge"
    }
}
