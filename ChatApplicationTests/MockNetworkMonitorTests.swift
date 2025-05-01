import XCTest
@testable import ChatApplication

final class MockNetworkMonitorTests: XCTestCase {
    var networkMonitor: MockNetworkMonitor!
    
    override func setUp() {
        super.setUp()
        networkMonitor = MockNetworkMonitor()
    }
    
    override func tearDown() {
        networkMonitor = nil
        super.tearDown()
    }
    
    func testInitialConnectionState() {
        XCTAssertTrue(networkMonitor.isConnected)
    }
    
    func testToggleConnection() {
        networkMonitor.toggleConnection()
        XCTAssertFalse(networkMonitor.isConnected)
        
        networkMonitor.toggleConnection()
        XCTAssertTrue(networkMonitor.isConnected)
    }
} 
