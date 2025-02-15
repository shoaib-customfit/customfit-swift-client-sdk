import XCTest
@testable import customfit_swift_client_sdk

final class CustomFitClientTests: XCTestCase {
    func testGetFlagValue() {
        let client = CustomFitClient(token: "dummy-token")
        let result = client.getFlagValue(key: "my-feature", defaultValue: "default-val")
        XCTAssertEqual(result, "mocked-value-for-my-feature")
    }
}

