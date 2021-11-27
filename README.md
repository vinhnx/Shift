<h1 align="center">Shift</h1>
<p align="center">Light-weight EventKit wrapper.</p>

---

[![Swift](https://github.com/vinhnx/Shift/actions/workflows/swift.yml/badge.svg)](https://github.com/vinhnx/Shift/actions/workflows/swift.yml)

Shift is a light-weight concurrency wrapper for EventKit:
+ SwiftUI supported
+ Concurrency ready with async/await. (tag: `0.7.0`)
+ Result completion handler (tag: `0.6.0`)
+ Thread-safe.

### Requirement

+ iOS 15.0 for async/await, tag `0.7.0`
+ iOS 14.0 and below for Result-based, tag <`0.6.0`
+ Swift version 5.5
+ Xcode 13.1

### Install

This component is built using Swift Package Manager, it is pretty straight forward to use:

1. In Xcode (11+), open your project and navigate to File > Swift Packages > Add Package Dependency...
2. Paste the repository URL (https://github.com/vinhnx/Shift) and click Next.
3. For Rules, select Version, in here, you can choose either:
  + Async/await => tag `0.7.0`
  + Result-based completion handler => tag `0.6.0`
5. Click Finish to resolve package into your Xcode project.

![Screen Shot 2021-08-15 at 11 28 54](https://user-images.githubusercontent.com/1097578/129467248-0ceac3c8-56f1-4a67-887f-538283121508.png)

### Tag Version:

Concurrency support is now ready, in tag [`0.7.0`](https://github.com/vinhnx/Shift/releases/tag/0.7.0)

In order to use old Result-based completion hanlders, please use tag [`0.6.0`](https://github.com/vinhnx/Shift/releases/tag/0.6.0).

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

### Usage Example

Fetch Events:

#### async/await

```swift
do {
    let events = try await Shift.shared.fetchEvents(for: Date()) // await for events fetching
} catch {
    print(error) // handle error
}
```

or, you can ignore event, like so:
```swift
let events = try? await Shift.shared.fetchEvents(for: Date()) // await for events fetching
```

#### Result

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

---

Create Event:

#### async/await

```swift
try? await Shift.shared.createEvent("Be happy!", startDate: startTime, endDate: endTime)
```

#### Result

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

#### async/await

```swift
try? await Shift.shared.deleteEvent(identifier: eventID)
```

### Result

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

#### Result-based example:

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
```

#### async/await example:

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
        .task { 
            try? await eventKitWrapper.fetchEventsForToday() 
        }
    }
}
```

---

### Apps currently using Shift

+ [Clendar](https://github.com/vinhnx/Clendar) - Clendar - universal calendar app. Written in SwiftUI. Available on App Store. MIT License.

([add yours here](https://github.com/vinhnx/Shift/pulls))

---

### Help, feedback or suggestions?

Feel free to [open an issue](https://github.com/vinhnx/Shift/issues) or contact me on [Twitter](https://twitter.com/@vinhnx) for discussions, news & announcements & other projects. 🚀

I hope you like it! :)
