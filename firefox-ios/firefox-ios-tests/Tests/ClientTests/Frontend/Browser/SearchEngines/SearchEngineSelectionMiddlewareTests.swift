// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class SearchEngineSelectionMiddlewareTests: XCTestCase {
    var mockProfile: MockProfile!
    var mockSearchEngines: [OpenSearchEngine]!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        mockSearchEngines = [
            OpenSearchEngineTests.generateOpenSearchEngine(type: .wikipedia, withImage: UIImage()),
            OpenSearchEngineTests.generateOpenSearchEngine(type: .youtube, withImage: UIImage()),
        ]
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testDismissMenuAction() throws {
        let mockSearchEnginesManager = SearchEnginesManager(prefs: mockProfile.prefs, files: mockProfile.files)
        mockSearchEnginesManager.orderedEngines = mockSearchEngines

        let subject = createSubject(mockSearchEnginesManager: mockSearchEnginesManager)
        let action = getAction(for: .viewDidLoad)

        let testStore = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: [subject.searchEngineSelectionProvider]
        )

        testStore.dispatch(action)

        // Currently we have a testability problem with our redux archicture:
        // 1) Every middleware calls the global `store`
        // 2) We have one global store so every test (including tests running in parallel) accesses the same store
        //
        // Ideally we would be able to check that the middleware fired an action of a specific type with a specific payload.
        throw XCTSkip("Need Store architecture changes if we want to implement tests")
    }

    // MARK: - Helpers

    private func createSubject(mockSearchEnginesManager: SearchEnginesManager) -> SearchEngineSelectionMiddleware {
        return SearchEngineSelectionMiddleware(profile: mockProfile, searchEnginesManager: mockSearchEnginesManager)
    }

    private func getAction(for actionType: SearchEngineSelectionActionType) -> SearchEngineSelectionAction {
        return SearchEngineSelectionAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: actionType
        )
    }
}
