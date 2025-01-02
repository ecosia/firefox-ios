// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

struct MockAppVersionInfoProvider: AppVersionInfoProvider {

    var mockedAppVersion: String

    init(mockedAppVersion: String) {
        self.mockedAppVersion = mockedAppVersion
    }

    var version: String {
        mockedAppVersion
    }
}
