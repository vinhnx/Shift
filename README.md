<h1 align="center">Shift</h1>
<p align="center">Swift(UI) wrapper for EventKit</p>

---

Shift is a Result-based wrapper for EventKit. SwiftUI supported!

### Installation

This component is built using Swift Package Manager, it is pretty straight forward to use:

1. In Xcode (11+), open your project and navigate to File > Swift Packages > Add Package Dependency...
2. Paste the repository URL (https://github.com/vinhnx/Shift) and click Next.
3. For Rules, select Branch (with branch set to master).
4. Click Finish to resolve package into your Xcode project.

### Getting Started

**First thing first**: Add Calendar usage description to your app's Info.plist to request for user's Calendars access.

```
<key>NSCalendarsUsageDescription</key>
	<string>&quot;$(PRODUCT_NAME) needs your permission to create events&quot;</string>
```

(Optional) configure own calendar name to request access to, preferrable in `AppDelegate` (Swift) or `App` (SwiftUI):

Swift AppDelegate:

```swift

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Shift.configureWithAppName("MyApp")
        return true
    }
}
```

SwiftUI App:

```swift
import SwiftUI
import Shift

@main
struct MyApp: App {
    init() {
        Shift.configureWithAppName("MyApp")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

### Swift Example

Fetch Events:

```swift
Shift.shared.fetchEvents(for: Date()) { result in
	switch result {
	case let .success(events): print(events) // got events
	case let .failure(error): print(error) // handle error
	}
}
```

```swift
Shift.shared.fetchEventsRangeUntilEndOfDay(from: Date()) { result in
    switch result {
	case let .success(events): print(events) // got events
	case let .failure(error): print(error) // handle error
	}
}
```

Various events fetching helpers:

```swift
    /// Fetch events for today
    /// - Parameter completion: completion handler
    public func fetchEventsForToday(completion: ((Result<[EKEvent], ShiftError>) -> Void)? = nil) {
        let today = Date()
        fetchEvents(startDate: today.startOfDay, endDate: today.endOfDay, completion: completion)
    }

    /// Fetch events for a specific day
    /// - Parameters:
    ///   - date: day to fetch events from
    ///   - completion: completion handler
    public func fetchEvents(for date: Date, completion: ((Result<[EKEvent], ShiftError>) -> Void)? = nil) {
        fetchEvents(startDate: date.startOfDay, endDate: date.endOfDay, completion: completion)
    }

    /// Fetch events for a specific day
    /// - Parameters:
    ///   - date: day to fetch events from
    ///   - completion: completion handler
    public func fetchEventsRangeUntilEndOfDay(from startDate: Date, completion: ((Result<[EKEvent], ShiftError>) -> Void)? = nil) {
        fetchEvents(startDate: startDate, endDate: startDate.endOfDay, completion: completion)
    }

    /// Fetch events from date range
    /// - Parameters:
    ///   - startDate: start date range
    ///   - endDate: end date range
    ///   - completion: completion handler
    public func fetchEvents(startDate: Date, endDate: Date, completion: ((Result<[EKEvent], ShiftError>) -> Void)? = nil) {...}
```

---

Create Event:

```swift
Shift.shared.createEvent("Be happy!", startDate: startTime, endDate: endTime) { result in
	switch result {
	case let .success(event): print(event) // created event
	case let .failure(error): print(error) // handle error
	}
}
```

---

Delete event:

```swift
Shift.shared.deleteEvent(identifier: eventID) { result in
	switch result {
	case let .success: print("done!") // deleted event
	case let .failure(error): print(error) // handle error
	}
}
```

---

## SwiftUI Example

Shift is conformed `ObservableObject` with an `@Published` `events` property, so it's straight-forward to use in SwiftUI binding mechanism.

Usage example:

```swift
import EventKit
import SwiftUI
import Shift

struct ContentView: View {
    @StateObject var eventKitWrapper = Shift.shared
    @State private var selectedEvent: EKEvent?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            ForEach(eventKitWrapper.events, id: \.self) { event in
                Text(event: event)
            }
        }
        .padding()
        .onAppear { eventKitWrapper.fetchEventsForToday() }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
```

---

### Apps currently using Shift

+ [Clendar](https://github.com/vinhnx/Clendar) - Clendar - universal calendar app. Written in SwiftUI. Available on App Store. MIT License.

([add yours here](https://github.com/vinhnx/Laden/pulls))

---

### Help, feedback or suggestions?

Feel free to [open an issue](https://github.com/vinhnx/Shift/issues) or contact me on [Twitter](https://twitter.com/@vinhnx) for discussions, news & announcements & other projects. 🚀

I hope you like it! :)
