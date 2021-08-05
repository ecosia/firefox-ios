/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core
import MozillaAppServices
import Storage
import Shared

final class EcosiaImport {

    enum Status {
        case succeeded, failed(Failure)
    }

    struct Failure: Error {
        let reasons: [MaybeErrorType]

        var description: String {
            // max 3 errors to be reported to save bandwidth and storage
            return reasons.prefix(3).map{$0.description}.joined(separator: " / ")
        }
    }

    struct Exception: Codable {
        let reason: String

        private static let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("migration.ecosia")

        static func load() -> Exception? {
            try? JSONDecoder().decode(Exception.self, from: .init(contentsOf: path))
        }

        func save() {
            try? JSONEncoder().encode(self).write(to: Self.path, options: .atomic)
        }

        static func clear() {
            try? FileManager.default.removeItem(at: path)
        }
    }

    let profile: Profile
    private var progress: ((Double) -> ())?

    init(profile: Profile) {
        self.profile = profile
    }

    func migrateHistory(progress: ((Double) -> ())? = nil, finished: @escaping (Status) -> ()) {
        self.progress = progress

        // Migrate in order for performance reasons -> first history, then favorites
        EcosiaHistory.migrate(Core.History().items, to: profile, progress: { historyProgress in
            self.progress = progress
        }) { result in

            self.progress?(1.0)

            switch result {
            case .success:
                finished(.succeeded)
            case .failure(let error):
                finished(.failed(error))
                Analytics.shared.migrationError(in: .history, message: error.description)
            }
        }
    }

    func migrateFavourites(finished: @escaping (Status) -> ()) {

        // Migrate in order for performance reasons -> first history, then favorites
        EcosiaFavourites.migrate(profile: self.profile) { result in
            switch result {
            case .success:
                finished(.succeeded)
            case .failure(let error):
                finished(.failed(error))
                Analytics.shared.migrationError(in: .favourites, message: error.description)
            }
        }
    }
}
