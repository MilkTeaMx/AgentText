import Foundation
import FirebaseFirestore

struct Agent: Identifiable, Codable {
    let id: String // Document ID (sanitized agent name)
    let agentId: String // Unique UUID
    let agentName: String
    let description: String
    let logic: String
    let developerId: String
    let developerName: String
    let installations: Int
    let likes: Int
    let dislikes: Int
    let createdAt: Date?
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.agentId = data["agent_id"] as? String ?? ""
        self.agentName = data["agent_name"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.logic = data["logic"] as? String ?? ""
        self.developerId = data["developer_id"] as? String ?? ""
        self.developerName = data["developer_name"] as? String ?? ""
        self.installations = data["installations"] as? Int ?? 0
        self.likes = data["likes"] as? Int ?? 0
        self.dislikes = data["dislikes"] as? Int ?? 0
        
        // Handle Firestore timestamp
        if let timestamp = data["created_at"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else if let timestamp = data["created_at"] as? [String: Any],
                  let seconds = timestamp["_seconds"] as? Int64 {
            // Handle server timestamp format
            self.createdAt = Date(timeIntervalSince1970: TimeInterval(seconds))
        } else {
            self.createdAt = nil
        }
    }
}

