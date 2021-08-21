import XCTest
@testable import Shift
import EventKit

final class ShiftTests: XCTestCase {
    func testExample() {
        if #available(macOS 12.0, *) {
            Task {
                let events = try await Shift.shared.fetchEventsForToday()
                XCTAssertNotNil(events, "events should NOT be nil")
            }
        }
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
