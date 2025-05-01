import Foundation

class SimpleMessageQueue: MessageQueueProtocol {
    private var queues: [String: [Message]] = [:]

    func enqueue(_ message: Message, for roomId: String) {
        queues[roomId, default: []].append(message)
    }

    func dequeue(for roomId: String) -> Message? {
        guard var queue = queues[roomId], !queue.isEmpty else { return nil }
        let msg = queue.removeFirst()
        queues[roomId] = queue
        return msg
    }
    
    func isQueueEmpty(for roomId: String) -> Bool {
        return queues[roomId]?.isEmpty ?? true
    }
    
    func hasQueued(messageId: UUID, in roomId: String) -> Bool {
        guard let queue = queues[roomId], !queue.isEmpty else {
            return false
        }
        
        return queue.contains { $0.id == messageId }
    }
}
