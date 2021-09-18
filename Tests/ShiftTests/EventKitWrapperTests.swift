import XCTest
@testable import Shift
import EventKit

final class ShiftTests: XCTestCase {
    @available(iOS 15.0, *)
    func testExample() {
        if #available(macOS 12.0, *) {
            Task {
                let events = try await Shift.shared.fetchEventsForToday()
                XCTAssertNotNil(events, "events should NOT be nil")
            }
        }
    }

    @available(iOS 15.0, *)
    static var allTests = [
        ("testExample", testExample),
    ]
}
