import XCTest
@testable import ChatApplication

final class ChatRoomsViewModelTests: XCTestCase {
    var viewModel: ChatRoomsViewModel!
    var mockNetworkMonitor: MockNetworkMonitor!
    var mockMessageQueue: SimpleMessageQueue!
    var mockChatSocket: PieSocketChatSocket!
    
    override func setUp() {
        super.setUp()
        mockNetworkMonitor = MockNetworkMonitor()
        mockMessageQueue = SimpleMessageQueue()
        mockChatSocket = PieSocketChatSocket()
        viewModel = ChatRoomsViewModel(
            socket: mockChatSocket,
            queue: mockMessageQueue,
            monitor: mockNetworkMonitor
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockNetworkMonitor = nil
        mockMessageQueue = nil
        mockChatSocket = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.state, .empty)
        XCTAssertTrue(viewModel.isConnected)
    }
    
    func testCreateChatRoom() {
        let roomId = viewModel.createChatRoom(name: "testRoom")
        XCTAssertNotNil(roomId)
        
        if case .rooms(let rooms) = viewModel.state {
            XCTAssertNotNil(rooms[roomId!])
            XCTAssertTrue(rooms[roomId!]!.isEmpty)
        } else {
            XCTFail("State should be .rooms")
        }
    }
    
    func testSendMessageWhenOnline() {
        let roomId = viewModel.createChatRoom(name: "testRoom")
        let message = "Hello"
        
        viewModel.sendMessage(message, to: roomId!)
        
        if case .rooms(let rooms) = viewModel.state {
            XCTAssertEqual(rooms[roomId!]?.count, 1)
            XCTAssertEqual(rooms[roomId!]?.first?.content, message)
            XCTAssertTrue(rooms[roomId!]?.first?.isSent ?? false)
        } else {
            XCTFail("State should be .rooms")
        }
    }
    
    func testSendMessageWhenOffline() {
        let roomId = viewModel.createChatRoom(name: "testRoom")
        let message = "Hello"
        
        mockNetworkMonitor.toggleConnection()
        viewModel.sendMessage(message, to: roomId!)
        
        if case .rooms(let rooms) = viewModel.state {
            XCTAssertEqual(rooms[roomId!]?.count, 1)
            XCTAssertTrue(rooms[roomId!]?.first?.isQueued ?? false)
            XCTAssertTrue(viewModel.hasQueued(messageId: rooms[roomId!]!.first!.id, in: roomId!))
        } else {
            XCTFail("State should be .rooms")
        }
    }
    
    func testRetryQueuedMessages() {
        let roomId = viewModel.createChatRoom(name: "testRoom")
        let message = "Hello"
        
        // Send message while offline
        mockNetworkMonitor.toggleConnection()
        viewModel.sendMessage(message, to: roomId!)
        
        // Go back online
        mockNetworkMonitor.toggleConnection()
        
        // Wait for retry to complete
        let expectation = XCTestExpectation(description: "Retry queued messages")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertFalse(viewModel.hasPendingMessages(for: roomId!))
    }
} 
