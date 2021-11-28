import XCTest
import Shift
import EventKit

final class ShiftTests: XCTestCase {
    func testConfigureAppName() {
        let name = "MyApp"
        Shift.configureWithAppName(name)
        XCTAssertEqual(Shift.appName, name)
    }
}
