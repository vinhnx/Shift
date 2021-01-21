//
//  EventKitWrapper.swift
//  Clendar
//
//  Created by Vinh Nguyen on 24/3/19.
//  Copyright © 2019 Vinh Nguyen. All rights reserved.

import Foundation
import SwiftUI
import EventKit

public enum ShiftError: Error, LocalizedError {
    case mapFromError(Error)
    case unableToAccessCalendar
    case failedToAuthorizeEventPersmissson(EKAuthorizationStatus? = nil)

    var localizedDescription: String {
        switch self {
        case .unableToAccessCalendar: return "Unable to access celendar"
        case let .mapFromError(error): return error.localizedDescription
        case let .failedToAuthorizeEventPersmissson(status):
            if let status = status {
                return "Failed to authorize event persmissson, status: \(status)"
            } else {
                return "Failed to authorize event persmissson"
            }
        }
    }
}

/// Swift wrapper for EventKit
public final class Shift: ObservableObject {

    // MARK: - Properties

    @Published public var events = [EKEvent]()

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
    /// - Parameter completion: completion handler with an EKAuthorizationStatus enum
    public func requestEventStoreAuthorization(completion: ((Result<EKAuthorizationStatus, ShiftError>) -> Void)?) {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .authorized:
            DispatchQueue.main.async { completion?(.success(status)) }

        case .denied,
             .restricted:
            DispatchQueue.main.async { completion?(.failure(ShiftError.failedToAuthorizeEventPersmissson(status))) }

        case .notDetermined:
            requestCalendarAccess { result in
                switch result {
                case let .success(granted):
                    if granted {
                        DispatchQueue.main.async { completion?(.success(.authorized)) }
                    }
                    else {
                        DispatchQueue.main.async { completion?(.failure(ShiftError.unableToAccessCalendar)) }
                    }

                case let .failure(error):
                    DispatchQueue.main.async { completion?(.failure(ShiftError.mapFromError(error))) }
                }
            }

        @unknown default:
            DispatchQueue.main.async { completion?(.failure(ShiftError.failedToAuthorizeEventPersmissson(status))) }
        }
    }

    // MARK: - CRUD

    /// Create an event
    /// - Parameters:
    ///   - title: event title
    ///   - startDate: event start date
    ///   - endDate: event end date
    ///   - completion: completion handler
    #if os(iOS) || os(macOS)
    public func createEvent(
        _ title: String,
        startDate: Date,
        endDate: Date?,
        span: EKSpan = .thisEvent,
        isAllDay: Bool = false,
        completion: ((Result<EKEvent, ShiftError>) -> Void)?
    ) {
        requestEventStoreAuthorization { [weak self] result in
            switch result {
            case let .success(status):
                guard let self = self else { return }
                guard status == .authorized else { return }

                self.accessCalendar { [weak self] calendarResult in
                    guard let self = self else { return }

                    switch calendarResult {
                    case let .success(calendar):
                        self.eventStore.createEvent(title: title, startDate: startDate, endDate: endDate, calendar: calendar, span: span, isAllDay: isAllDay, completion: completion)

                    case let .failure(error):
                        DispatchQueue.main.async { completion?(.failure(error)) }
                    }
                }

            case let .failure(error):
                DispatchQueue.main.async { completion?(.failure(error)) }
            }
        }
    }
    #endif

    /// Delete an event
    /// - Parameters:
    ///   - identifier: event identifier
    ///   - span: An object that indicates whether modifications should apply to a single event or all future events of a recurring event.
    ///   - completion: completion handler
    #if os(iOS) || os(macOS)
    public func deleteEvent(identifier: String, span: EKSpan = .thisEvent, completion: ((Result<Void, ShiftError>) -> Void)?) {
        requestEventStoreAuthorization { [weak self] result in
            switch result {
            case let .success(status):
                guard let self = self else { return }
                guard status == .authorized else { return }

                self.accessCalendar { [weak self] calendarResult in
                    guard let self = self else { return }

                    switch calendarResult {
                    case .success:
                        self.eventStore.deleteEvent(identifier: identifier, span: span, completion: completion)

                    case let .failure(error):
                        DispatchQueue.main.async { completion?(.failure(error)) }
                    }
                }

            case let .failure(error):
                DispatchQueue.main.async { completion?(.failure(error)) }
            }
        }
    }
    #endif

    // MARK: - Fetch Events

    /// Fetch events for today
    /// - Parameter completion: completion handler
    /// - Parameter filterCalendarIDs: filterable Calendar IDs
    public func fetchEventsForToday(filterCalendarIDs: [String] = [], completion: ((Result<[EKEvent], ShiftError>) -> Void)? = nil) {
        let today = Date()
        fetchEvents(startDate: today.startOfDay, endDate: today.endOfDay, filterCalendarIDs: filterCalendarIDs, completion: completion)
    }

    /// Fetch events for a specific day
    /// - Parameters:
    ///   - date: day to fetch events from
    ///   - completion: completion handler
    ///   - filterCalendarIDs: filterable Calendar IDs
    public func fetchEvents(for date: Date, filterCalendarIDs: [String] = [], completion: ((Result<[EKEvent], ShiftError>) -> Void)? = nil) {
        fetchEvents(startDate: date.startOfDay, endDate: date.endOfDay, filterCalendarIDs: filterCalendarIDs, completion: completion)
    }

    /// Fetch events for a specific day
    /// - Parameters:
    ///   - date: day to fetch events from
    ///   - completion: completion handler
    ///   - startDate: event start date
    ///   - filterCalendarIDs: filterable Calendar IDs
    public func fetchEventsRangeUntilEndOfDay(from startDate: Date, filterCalendarIDs: [String] = [], completion: ((Result<[EKEvent], ShiftError>) -> Void)? = nil) {
        fetchEvents(startDate: startDate, endDate: startDate.endOfDay, filterCalendarIDs: filterCalendarIDs, completion: completion)
    }

    /// Fetch events from date range
    /// - Parameters:
    ///   - startDate: start date range
    ///   - endDate: end date range
    ///   - completion: completion handler
    ///   - filterCalendarIDs: filterable Calendar IDs
    public func fetchEvents(startDate: Date, endDate: Date, filterCalendarIDs: [String] = [], completion: ((Result<[EKEvent], ShiftError>) -> Void)? = nil) {
        requestEventStoreAuthorization { [weak self] result in
            switch result {
            case let .success(status):
                guard let self = self else { return }
                guard status == .authorized else { return }

                let calendars = self.eventStore
                    .calendars(for: .event)
                    .filter { calendar in
                        if filterCalendarIDs.isEmpty { return true }
                        return filterCalendarIDs.contains(calendar.calendarIdentifier)
                    }

                let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
                let events = self.eventStore.events(matching: predicate)
                DispatchQueue.main.async { 
                    self.events = events
                    completion?(.success(events)) 
                }

            case let .failure(error):
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
            }
        }
    }

    // MARK: Private

    /// Request access to calendar
    /// - Parameter completion: calendar object
    private func accessCalendar(completion: ((Result<EKCalendar, ShiftError>) -> Void)?) {
        requestEventStoreAuthorization { [weak self] result in
            switch result {
            case let .success(status):
                guard let self = self else { return }
                guard status == .authorized else { return }
                guard let calendar = self.eventStore.calendarForApp() else { return }

                DispatchQueue.main.async {
                    completion?(.success(calendar))
                }

            case let .failure(error):
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Prompt the user for access to their Calendar
    /// - Parameter onAuthorized: on authorized
    private func requestCalendarAccess(completion: ((Result<Bool, Error>) -> Void)?) {
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    completion?(.success(granted))
                }
            }
            else if let error = error {
                DispatchQueue.main.async { completion?(.failure(error)) }
            }
            else {
                DispatchQueue.main.async { completion?(.failure(ShiftError.unableToAccessCalendar)) }
            }
        }
    }
}

extension EKEventStore {
    // MARK: - CRUD

    /// Create an event
    /// - Parameters:
    ///   - title: event title
    ///   - startDate: event startDate
    ///   - endDate: event endDate
    ///   - calendar: event calendar
    ///   - span: event span
    ///   - completion: event completion handler that returns an event
    #if os(iOS) || os(macOS)
    public func createEvent(
        title: String,
        startDate: Date,
        endDate: Date?,
        calendar: EKCalendar,
        span: EKSpan = .thisEvent,
        isAllDay: Bool = false,
        completion: ((Result<EKEvent, ShiftError>) -> Void)?
    ) {
        let event = EKEvent(eventStore: self)
        event.calendar = calendar
        event.title = title
        event.isAllDay = isAllDay
        event.startDate = startDate
        event.endDate = endDate

        do {
            try save(event, span: span, commit: true)
            DispatchQueue.main.async { completion?(.success(event)) }
        } catch {
            DispatchQueue.main.async {
                completion?(.failure(ShiftError.mapFromError(error)))
            }
        }
    }
    #endif

    /// Delete event
    /// - Parameters:
    ///   - identifier: event identifier
    ///   - span: event span
    ///   - completion: event completion handler that returns an event
    #if os(iOS) || os(macOS)
    public func deleteEvent(
        identifier: String,
        span: EKSpan = .thisEvent,
        completion: ((Result<Void, ShiftError>) -> Void)? = nil
    ) {
        guard let event = fetchEvent(identifier: identifier) else { return }

        do {
            try remove(event, span: span, commit: true)

            DispatchQueue.main.async {
                completion?(.success(()))
            }
        } catch {
            DispatchQueue.main.async {
                completion?(.failure(ShiftError.mapFromError(error)))
            }
        }
    }
    #endif

    // MARK: - Fetch

    /// Calendar for current AppName
    /// - Returns: App calendar
    /// - Parameter calendarColor: default new calendar color
    public func calendarForApp(calendarColor: CGColor = UIColor.red.cgColor) -> EKCalendar? {
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
            newClendar.cgColor = UIColor.red.cgColor
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
