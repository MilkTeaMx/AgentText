import Foundation

/// Service for interacting with Notion API
/// Uses NotionOAuthManager for authentication
class NotionService {
    static let shared = NotionService()

    private let baseURL = "https://api.notion.com/v1"
    private let oauthManager = NotionOAuthManager.shared

    private init() {}

    // MARK: - Pages

    /// Retrieve a page by ID
    /// - Parameters:
    ///   - pageId: The Notion page ID
    ///   - completion: Called with page data or error
    func retrievePage(pageId: String, completion: @escaping (Result<NotionPage, Error>) -> Void) {
        oauthManager.getValidAccessToken { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let accessToken):
                self.performRetrievePage(accessToken: accessToken, pageId: pageId, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func performRetrievePage(accessToken: String, pageId: String, completion: @escaping (Result<NotionPage, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/pages/\(pageId)") else {
            completion(.failure(NotionError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version") // Notion API version

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NotionError.noData))
                }
                return
            }

            do {
                let page = try JSONDecoder().decode(NotionPage.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(page))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    /// Create a new page
    /// - Parameters:
    ///   - parent: The parent page or database ID
    ///   - properties: The page properties
    ///   - completion: Called with created page or error
    func createPage(parent: NotionParent, properties: [String: NotionProperty], completion: @escaping (Result<NotionPage, Error>) -> Void) {
        oauthManager.getValidAccessToken { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let accessToken):
                self.performCreatePage(accessToken: accessToken, parent: parent, properties: properties, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func performCreatePage(accessToken: String, parent: NotionParent, properties: [String: NotionProperty], completion: @escaping (Result<NotionPage, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/pages") else {
            completion(.failure(NotionError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "parent": parent.toDictionary(),
            "properties": properties.mapValues { $0.toDictionary() }
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
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
                    completion(.failure(NotionError.noData))
                }
                return
            }

            do {
                let page = try JSONDecoder().decode(NotionPage.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(page))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    /// Update a page
    /// - Parameters:
    ///   - pageId: The page ID to update
    ///   - properties: The properties to update
    ///   - completion: Called with updated page or error
    func updatePage(pageId: String, properties: [String: NotionProperty], completion: @escaping (Result<NotionPage, Error>) -> Void) {
        oauthManager.getValidAccessToken { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let accessToken):
                self.performUpdatePage(accessToken: accessToken, pageId: pageId, properties: properties, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func performUpdatePage(accessToken: String, pageId: String, properties: [String: NotionProperty], completion: @escaping (Result<NotionPage, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/pages/\(pageId)") else {
            completion(.failure(NotionError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "properties": properties.mapValues { $0.toDictionary() }
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
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
                    completion(.failure(NotionError.noData))
                }
                return
            }

            do {
                let page = try JSONDecoder().decode(NotionPage.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(page))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Databases

    /// Query a database
    /// - Parameters:
    ///   - databaseId: The database ID
    ///   - filter: Optional filter criteria
    ///   - sorts: Optional sort criteria
    ///   - completion: Called with query results or error
    func queryDatabase(databaseId: String, filter: NotionFilter? = nil, sorts: [NotionSort]? = nil, completion: @escaping (Result<NotionDatabaseQueryResponse, Error>) -> Void) {
        oauthManager.getValidAccessToken { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let accessToken):
                self.performQueryDatabase(accessToken: accessToken, databaseId: databaseId, filter: filter, sorts: sorts, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func performQueryDatabase(accessToken: String, databaseId: String, filter: NotionFilter?, sorts: [NotionSort]?, completion: @escaping (Result<NotionDatabaseQueryResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/databases/\(databaseId)/query") else {
            completion(.failure(NotionError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [:]
        if let filter = filter {
            body["filter"] = filter.toDictionary()
        }
        if let sorts = sorts {
            body["sorts"] = sorts.map { $0.toDictionary() }
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
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
                    completion(.failure(NotionError.noData))
                }
                return
            }

            do {
                let response = try JSONDecoder().decode(NotionDatabaseQueryResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(response))
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

struct NotionPage: Codable {
    let id: String
    let object: String
    let createdTime: String?
    let lastEditedTime: String?
    let createdBy: NotionUser?
    let lastEditedBy: NotionUser?
    let cover: NotionFile?
    let icon: NotionIcon?
    let parent: NotionParent?
    let archived: Bool?
    let properties: [String: NotionProperty]?
    let url: String?
}

struct NotionUser: Codable {
    let object: String
    let id: String
}

struct NotionFile: Codable {
    let type: String
    let external: NotionExternalFile?
    let file: NotionFileData?
}

struct NotionExternalFile: Codable {
    let url: String
}

struct NotionFileData: Codable {
    let url: String
    let expiryTime: String?
}

struct NotionIcon: Codable {
    let type: String
    let emoji: String?
    let external: NotionExternalFile?
    let file: NotionFileData?
}

struct NotionParent: Codable {
    let type: String
    let pageId: String?
    let databaseId: String?
    let workspace: Bool?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["type": type]
        if let pageId = pageId {
            dict["page_id"] = pageId
        }
        if let databaseId = databaseId {
            dict["database_id"] = databaseId
        }
        if let workspace = workspace {
            dict["workspace"] = workspace
        }
        return dict
    }
}

struct NotionProperty: Codable {
    let id: String?
    let type: String
    let title: [NotionRichText]?
    let richText: [NotionRichText]?
    let number: Double?
    let select: NotionSelect?
    let multiSelect: [NotionSelect]?
    let date: NotionDate?
    let checkbox: Bool?
    let url: String?
    let email: String?
    let phoneNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, number, select, date, checkbox, url, email
        case richText = "rich_text"
        case multiSelect = "multi_select"
        case phoneNumber = "phone_number"
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["type": type]
        
        if let title = title {
            dict["title"] = title.map { $0.toDictionary() }
        }
        if let richText = richText {
            dict["rich_text"] = richText.map { $0.toDictionary() }
        }
        if let number = number {
            dict["number"] = number
        }
        if let select = select {
            dict["select"] = select.toDictionary()
        }
        if let multiSelect = multiSelect {
            dict["multi_select"] = multiSelect.map { $0.toDictionary() }
        }
        if let date = date {
            dict["date"] = date.toDictionary()
        }
        if let checkbox = checkbox {
            dict["checkbox"] = checkbox
        }
        if let url = url {
            dict["url"] = url
        }
        if let email = email {
            dict["email"] = email
        }
        if let phoneNumber = phoneNumber {
            dict["phone_number"] = phoneNumber
        }
        
        return dict
    }
}

struct NotionRichText: Codable {
    let type: String
    let plainText: String?
    let href: String?
    let annotations: NotionAnnotations?
    let text: NotionTextContent?
    
    enum CodingKeys: String, CodingKey {
        case type, href, annotations, text
        case plainText = "plain_text"
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["type": type]
        if let plainText = plainText {
            dict["plain_text"] = plainText
        }
        if let href = href {
            dict["href"] = href
        }
        if let annotations = annotations {
            dict["annotations"] = annotations.toDictionary()
        }
        if let text = text {
            dict["text"] = text.toDictionary()
        }
        return dict
    }
}

struct NotionTextContent: Codable {
    let content: String
    let link: NotionLink?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["content": content]
        if let link = link {
            dict["link"] = link.toDictionary()
        }
        return dict
    }
}

struct NotionLink: Codable {
    let type: String
    let url: String
    
    func toDictionary() -> [String: Any] {
        return ["type": type, "url": url]
    }
}

struct NotionAnnotations: Codable {
    let bold: Bool?
    let italic: Bool?
    let strikethrough: Bool?
    let underline: Bool?
    let code: Bool?
    let color: String?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let bold = bold { dict["bold"] = bold }
        if let italic = italic { dict["italic"] = italic }
        if let strikethrough = strikethrough { dict["strikethrough"] = strikethrough }
        if let underline = underline { dict["underline"] = underline }
        if let code = code { dict["code"] = code }
        if let color = color { dict["color"] = color }
        return dict
    }
}

struct NotionSelect: Codable {
    let id: String?
    let name: String
    let color: String?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["name": name]
        if let id = id { dict["id"] = id }
        if let color = color { dict["color"] = color }
        return dict
    }
}

struct NotionDate: Codable {
    let start: String
    let end: String?
    let timeZone: String?
    
    enum CodingKeys: String, CodingKey {
        case start, end
        case timeZone = "time_zone"
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["start": start]
        if let end = end { dict["end"] = end }
        if let timeZone = timeZone { dict["time_zone"] = timeZone }
        return dict
    }
}

struct NotionFilter: Codable {
    let property: String
    let type: String
    // Add more filter types as needed
    
    func toDictionary() -> [String: Any] {
        return ["property": property, "type": type]
    }
}

struct NotionSort: Codable {
    let property: String?
    let timestamp: String?
    let direction: String
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["direction": direction]
        if let property = property { dict["property"] = property }
        if let timestamp = timestamp { dict["timestamp"] = timestamp }
        return dict
    }
}

struct NotionDatabaseQueryResponse: Codable {
    let object: String
    let results: [NotionPage]
    let nextCursor: String?
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case object, results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

enum NotionError: LocalizedError {
    case invalidURL
    case noData
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from server"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

