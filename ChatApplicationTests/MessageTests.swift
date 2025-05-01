import XCTest
@testable import ChatApplication

final class MessageTests: XCTestCase {
    
    func testMessageInitialization() {
        let message = Message(content: "Hello", isQueued: false, isSent: true)
        
        XCTAssertNotNil(message.id)
        XCTAssertEqual(message.content, "Hello")
        XCTAssertFalse(message.isQueued)
        XCTAssertTrue(message.isSent)
    }
    
    func testMessageEquality() {
        let message1 = Message(content: "Hello", isQueued: false, isSent: true)
        let message2 = Message(content: "Hello", isQueued: false, isSent: true)
        let message3 = Message(content: "Hi", isQueued: true, isSent: false)
        
        XCTAssertNotEqual(message1, message2) // Messages with different UUIDs are not equal
        XCTAssertNotEqual(message1, message3)
    }
    
    func testMessageDisplayText() {
        let sentMessage = Message(content: "Hello", isQueued: false, isSent: true)
        let receivedMessage = Message(content: "Hi", isQueued: false, isSent: false)
        
        XCTAssertEqual(sentMessage.displayMessage, "You: Hello")
        XCTAssertEqual(receivedMessage.displayMessage, "Hi")
    }
} 