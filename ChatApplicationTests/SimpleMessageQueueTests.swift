import XCTest
@testable import ChatApplication

final class SimpleMessageQueueTests: XCTestCase {
    var messageQueue: SimpleMessageQueue!
    
    override func setUp() {
        super.setUp()
        messageQueue = SimpleMessageQueue()
    }
    
    override func tearDown() {
        messageQueue = nil
        super.tearDown()
    }
    
    func testEnqueueMessage() {
        let roomId = "testRoom"
        let message = Message(content: "Hello", isQueued: true, isSent: false)
        
        messageQueue.enqueue(message, for: roomId)
        
        XCTAssertTrue(messageQueue.hasQueued(messageId: message.id, in: roomId))
        XCTAssertFalse(messageQueue.isQueueEmpty(for: roomId))
    }
    
    func testDequeueMessage() {
        let roomId = "testRoom"
        let message = Message(content: "Hello", isQueued: true, isSent: false)
        
        messageQueue.enqueue(message, for: roomId)
        let dequeuedMessage = messageQueue.dequeue(for: roomId)
        
        XCTAssertEqual(dequeuedMessage?.content, message.content)
        XCTAssertTrue(messageQueue.isQueueEmpty(for: roomId))
    }
    
    func testMultipleRooms() {
        let room1 = "room1"
        let room2 = "room2"
        let message1 = Message(content: "Hello", isQueued: true, isSent: false)
        let message2 = Message(content: "Hi", isQueued: true, isSent: false)
        
        messageQueue.enqueue(message1, for: room1)
        messageQueue.enqueue(message2, for: room2)
        
        XCTAssertTrue(messageQueue.hasQueued(messageId: message1.id, in: room1))
        XCTAssertTrue(messageQueue.hasQueued(messageId: message2.id, in: room2))
        XCTAssertFalse(messageQueue.isQueueEmpty(for: room1))
        XCTAssertFalse(messageQueue.isQueueEmpty(for: room2))
    }
} 