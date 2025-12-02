import Foundation

/// Service for interacting with Google Calendar API
/// Uses GoogleOAuthManager for authentication
class GoogleCalendarService {
    static let shared = GoogleCalendarService()

    private let baseURL = "https://www.googleapis.com/calendar/v3"
    private let oauthManager = GoogleOAuthManager.shared

    private init() {}

    // MARK: - Calendar Events

    /// Fetch upcoming calendar events
    /// - Parameters:
    ///   - maxResults: Maximum number of events to return
    ///   - completion: Called with array of events or error
    func fetchUpcomingEvents(maxResults: Int = 10, completion: @escaping (Result<[CalendarEvent], Error>) -> Void) {
        oauthManager.getValidAccessToken { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let accessToken):
                self.performFetchEvents(accessToken: accessToken, maxResults: maxResults, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func performFetchEvents(accessToken: String, maxResults: Int, completion: @escaping (Result<[CalendarEvent], Error>) -> Void) {
        // Build URL with query parameters
        var components = URLComponents(string: "\(baseURL)/calendars/primary/events")!
        components.queryItems = [
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "timeMin", value: ISO8601DateFormatter().string(from: Date()))
        ]

        guard let url = components.url else {
            completion(.failure(CalendarError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(CalendarError.noData))
                }
                return
            }

            do {
                let eventsResponse = try JSONDecoder().decode(CalendarEventsResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(eventsResponse.items ?? []))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    /// Create a new calendar event
    /// - Parameters:
    ///   - event: The event to create
    ///   - completion: Called with created event or error
    func createEvent(_ event: CalendarEvent, completion: @escaping (Result<CalendarEvent, Error>) -> Void) {
        oauthManager.getValidAccessToken { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let accessToken):
                self.performCreateEvent(accessToken: accessToken, event: event, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func performCreateEvent(accessToken: String, event: CalendarEvent, completion: @escaping (Result<CalendarEvent, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/calendars/primary/events") else {
            completion(.failure(CalendarError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(event)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(CalendarError.noData))
                }
                return
            }

            do {
                let createdEvent = try JSONDecoder().decode(CalendarEvent.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(createdEvent))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    /// Delete a calendar event
    /// - Parameters:
    ///   - eventId: The ID of the event to delete
    ///   - completion: Called with success or error
    func deleteEvent(eventId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        oauthManager.getValidAccessToken { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let accessToken):
                self.performDeleteEvent(accessToken: accessToken, eventId: eventId, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func performDeleteEvent(accessToken: String, eventId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/calendars/primary/events/\(eventId)") else {
            completion(.failure(CalendarError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(CalendarError.deleteFailed))
                }
            }
        }.resume()
    }

    /// List all calendars
    /// - Parameter completion: Called with array of calendars or error
    func listCalendars(completion: @escaping (Result<[Calendar], Error>) -> Void) {
        oauthManager.getValidAccessToken { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let accessToken):
                self.performListCalendars(accessToken: accessToken, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func performListCalendars(accessToken: String, completion: @escaping (Result<[Calendar], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/users/me/calendarList") else {
            completion(.failure(CalendarError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(CalendarError.noData))
                }
                return
            }

            do {
                let calendarsResponse = try JSONDecoder().decode(CalendarListResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(calendarsResponse.items ?? []))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

// MARK: - Data Models

struct CalendarEvent: Codable {
    let id: String?
    let summary: String?
    let description: String?
    let start: EventDateTime?
    let end: EventDateTime?
    let location: String?
    let status: String?
    let htmlLink: String?

    struct EventDateTime: Codable {
        let dateTime: String?
        let timeZone: String?
        let date: String? // For all-day events
    }
}

struct CalendarEventsResponse: Codable {
    let items: [CalendarEvent]?
}

struct Calendar: Codable {
    let id: String
    let summary: String?
    let description: String?
    let timeZone: String?
    let primary: Bool?
}

struct CalendarListResponse: Codable {
    let items: [Calendar]?
}

enum CalendarError: LocalizedError {
    case invalidURL
    case noData
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from server"
        case .deleteFailed:
            return "Failed to delete event"
        }
    }
}

// MARK: - Example Usage

extension GoogleCalendarService {
    /// Example: Fetch and print upcoming events
    func exampleFetchEvents() {
        fetchUpcomingEvents(maxResults: 5) { result in
            switch result {
            case .success(let events):
                print("📅 Upcoming Events:")
                for event in events {
                    print("- \(event.summary ?? "No title")")
                    if let start = event.start?.dateTime {
                        print("  Starts: \(start)")
                    }
                }
            case .failure(let error):
                print("❌ Error fetching events: \(error.localizedDescription)")
            }
        }
    }

    /// Example: Create a new event
    func exampleCreateEvent() {
        let newEvent = CalendarEvent(
            id: nil,
            summary: "Team Meeting",
            description: "Discuss Q1 goals",
            start: CalendarEvent.EventDateTime(
                dateTime: "2024-03-15T10:00:00-07:00",
                timeZone: "America/Los_Angeles",
                date: nil
            ),
            end: CalendarEvent.EventDateTime(
                dateTime: "2024-03-15T11:00:00-07:00",
                timeZone: "America/Los_Angeles",
                date: nil
            ),
            location: "Conference Room A",
            status: nil,
            htmlLink: nil
        )

        createEvent(newEvent) { result in
            switch result {
            case .success(let event):
                print("✅ Event created: \(event.summary ?? "Unknown")")
                print("   Link: \(event.htmlLink ?? "N/A")")
            case .failure(let error):
                print("❌ Error creating event: \(error.localizedDescription)")
            }
        }
    }
}
