import Foundation

public struct Message: Identifiable, Equatable {
    public let id: UUID
    public let content: String
    public let isQueued: Bool
    public let isSent: Bool
    
    public var displayMessage: String {
        isSent ? "You: \(content)" : content
    }
    
    public init(content: String,
                isQueued: Bool = false,
                isSent: Bool = false) {
        self.id = UUID()
        self.content = content
        self.isQueued = isQueued
        self.isSent = isSent
    }
} 
