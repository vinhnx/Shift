/**
 *  Shift
 *  Copyright (c) Vinh Nguyen 2021
 *  MIT license, see LICENSE file for details
 */

import Foundation
import SwiftUI
import EventKit

/// ShiftError definition
public enum ShiftError: Error, LocalizedError {
    case mapFromError(Error)
    case unableToAccessCalendar
    case eventAuthorizationStatus(EKAuthorizationStatus? = nil)
    case invalidEvent

    var localizedDescription: String {
        switch self {
        case .invalidEvent: return "Invalid event"
        case .unableToAccessCalendar: return "Unable to access celendar"
        case let .mapFromError(error): return error.localizedDescription
        case let .eventAuthorizationStatus(status):
            if let status = status {
                return "Failed to authorize event persmissson, status: \(status)"
            } else {
                return "Failed to authorize event persmissson"
            }
        }
    }
}

/// Swift wrapper for EventKit
/// actor: protected against un-safe thread accessing
public actor Shift: ObservableObject {

    // MARK: - Properties

    /// Events should only be accessible from main thread
    @Published @MainActor public var events = [EKEvent]()

    public static var appName: String?

    /// Event store: An object that accesses the user’s calendar and reminder events and supports the scheduling of new events.
    public private(set) var eventStore = EKEventStore()

    /// Returns calendar object from event kit
    public var defaultCalendar: EKCalendar? {
        eventStore.calendarForApp()
    }

    // MARK: Lifecycle

    public static let shared = Shift()

    public static func configureWithAppName(_ appName: String) {
        self.appName = appName
    }

    private init() {} // This prevents others from using the default '()' initializer for this class.

    // MARK: - Flow

    /// Request event store authorization
    /// - Returns: EKAuthorizationStatus enum
    public func requestEventStoreAuthorization() async throws -> EKAuthorizationStatus {
        let granted = try await requestCalendarAccess()
        if granted {
            return EKEventStore.authorizationStatus(for: .event)
        }
        else {
            throw ShiftError.unableToAccessCalendar
        }
    }

    // MARK: - CRUD

    /// Create an event
    /// - Parameters:
    ///   - title: title of the event
    ///   - startDate: event's start date
    ///   - endDate: event's end date
    ///   - span: event's span
    ///   - isAllDay: is all day event
    /// - Returns: created event
#if os(iOS) || os(macOS)
    public func createEvent(
        _ title: String,
        startDate: Date,
        endDate: Date?,
        span: EKSpan = .thisEvent,
        isAllDay: Bool = false
    ) async throws -> EKEvent {
        let calendar = try await accessCalendar()
        let createdEvent = try await self.eventStore.createEvent(title: title, startDate: startDate, endDate: endDate, calendar: calendar, span: span, isAllDay: isAllDay)
        return createdEvent
    }
#endif

    /// Delete an event
    /// - Parameters:
    ///   - identifier: event identifier
    ///   - span: even't span
#if os(iOS) || os(macOS)
    public func deleteEvent(
        identifier: String,
        span: EKSpan = .thisEvent
    ) async throws {
        try await accessCalendar()
        try self.eventStore.deleteEvent(identifier: identifier, span: span)
    }
#endif

    // MARK: - Fetch Events

    /// Fetch events for today
    /// - Parameter completion: completion handler
    /// - Parameter filterCalendarIDs: filterable Calendar IDs
    /// Returns: events for today
    @discardableResult
    public func fetchEventsForToday(filterCalendarIDs: [String] = []) async throws -> [EKEvent] {
        let today = Date()
        return try await fetchEvents(startDate: today.startOfDay, endDate: today.endOfDay, filterCalendarIDs: filterCalendarIDs)
    }

    /// Fetch events for a specific day
    /// - Parameters:
    ///   - date: day to fetch events from
    ///   - completion: completion handler
    ///   - filterCalendarIDs: filterable Calendar IDs
    /// Returns: events
    @discardableResult
    public func fetchEvents(for date: Date, filterCalendarIDs: [String] = []) async throws -> [EKEvent] {
        try await fetchEvents(startDate: date.startOfDay, endDate: date.endOfDay, filterCalendarIDs: filterCalendarIDs)
    }

    /// Fetch events for a specific day
    /// - Parameters:
    ///   - date: day to fetch events from
    ///   - completion: completion handler
    ///   - startDate: event start date
    ///   - filterCalendarIDs: filterable Calendar IDs
    /// Returns: events
    @discardableResult
    public func fetchEventsRangeUntilEndOfDay(from startDate: Date, filterCalendarIDs: [String] = []) async throws -> [EKEvent] {
        try await fetchEvents(startDate: startDate, endDate: startDate.endOfDay, filterCalendarIDs: filterCalendarIDs)
    }

    /// Fetch events from date range
    /// - Parameters:
    ///   - startDate: start date range
    ///   - endDate: end date range
    ///   - completion: completion handler
    ///   - filterCalendarIDs: filterable Calendar IDs
    /// Returns: events
    @discardableResult
    public func fetchEvents(startDate: Date, endDate: Date, filterCalendarIDs: [String] = []) async throws -> [EKEvent] {
        let authorization = try await requestEventStoreAuthorization()
        guard authorization == .authorized else {
            throw ShiftError.eventAuthorizationStatus(nil)
        }

        let calendars = self.eventStore.calendars(for: .event).filter { calendar in
            if filterCalendarIDs.isEmpty { return true }
            return filterCalendarIDs.contains(calendar.calendarIdentifier)
        }

        let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = self.eventStore.events(matching: predicate)

        // MainActor is a type that runs code on main thread.
        await MainActor.run {
            self.events = events
        }

        return events
    }

    // MARK: Private

    /// Request access to calendar
    /// - Returns: calendar object
    @discardableResult
    private func accessCalendar() async throws -> EKCalendar {
        let authorization = try await requestEventStoreAuthorization()

        guard authorization == .authorized else {
            throw ShiftError.eventAuthorizationStatus(nil)
        }

        guard let calendar = eventStore.calendarForApp() else {
            throw ShiftError.unableToAccessCalendar
        }

        return calendar
    }

    private func requestCalendarAccess() async throws -> Bool {
        try await eventStore.requestAccess(to: .event)
    }
}

extension EKEventStore {

    // MARK: - CRUD

    /// Create an event
    /// - Parameters:
    ///   - title: title of the event
    ///   - startDate: event's start date
    ///   - endDate: event's end date
    ///   - calendar: calendar instance
    ///   - span: event's span
    ///   - isAllDay: is all day event
    /// - Returns: created event
#if os(iOS) || os(macOS)
    public func createEvent(
        title: String,
        startDate: Date,
        endDate: Date?,
        calendar: EKCalendar,
        span: EKSpan = .thisEvent,
        isAllDay: Bool = false
    ) async throws -> EKEvent {
        let event = EKEvent(eventStore: self)
        event.calendar = calendar
        event.title = title
        event.isAllDay = isAllDay
        event.startDate = startDate
        event.endDate = endDate
        try save(event, span: span, commit: true)
        return event
    }
#endif

    /// Delete event
    /// - Parameters:
    ///   - identifier: event identifier
    ///   - span: event's span
#if os(iOS) || os(macOS)
    public func deleteEvent(
        identifier: String,
        span: EKSpan = .thisEvent
    ) throws {
        guard let event = fetchEvent(identifier: identifier) else {
            throw ShiftError.invalidEvent
        }

        try remove(event, span: span, commit: true)
    }
#endif

    // MARK: - Fetch

    /// Calendar for current AppName
    /// - Returns: App calendar
    /// - Parameter calendarColor: default new calendar color
    public func calendarForApp(calendarColor: CGColor = .init(red: 1, green: 0, blue: 0, alpha: 1)) -> EKCalendar? {
        guard let appName = Shift.appName else {
#if DEBUG
            print("App name is nil, please config with `Shift.configureWithAppName` in AppDelegate")
#endif
            return nil
        }

        let calendars = self.calendars(for: .event)

        if let clendar = calendars.first(where: { $0.title == appName }) {
            return clendar
        }
        else {
#if os(iOS) || os(macOS)
            let newClendar = EKCalendar(for: .event, eventStore: self)
            newClendar.title = appName
            newClendar.source = defaultCalendarForNewEvents?.source
            newClendar.cgColor = .init(red: 1, green: 0, blue: 0, alpha: 1)
            try? saveCalendar(newClendar, commit: true)
            return newClendar
#else
            return nil
#endif
        }
    }

    /// Fetch an EKEvent instance with given identifier
    /// - Parameter identifier: event identifier
    /// - Returns: an EKEvent instance with given identifier
    func fetchEvent(identifier: String) -> EKEvent? {
        event(withIdentifier: identifier)
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        // swiftlint:disable:next force_unwrapping
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
}
