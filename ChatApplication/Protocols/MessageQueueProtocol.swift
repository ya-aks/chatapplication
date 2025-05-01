import Foundation

protocol MessageQueueProtocol {
    func enqueue(_ message: Message, for roomId: String)
    func dequeue(for roomId: String) -> Message?
    func isQueueEmpty(for roomId: String) -> Bool
    func hasQueued(messageId: UUID, in roomId: String) -> Bool
}
