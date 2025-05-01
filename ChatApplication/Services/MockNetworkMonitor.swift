import Foundation

class MockNetworkMonitor: NetworkMonitorProtocol {
    var isConnected: Bool = true
    var onStatusChange: ((Bool) -> Void)? {
        didSet {
            onStatusChange?(isConnected)
        }
    }
    
    func toggleConnection() {
        isConnected.toggle()
        onStatusChange?(isConnected)
    }
    
    func startMonitoring() {
        // No-op in mock implementation
    }
    
    func stopMonitoring() {
        // No-op in mock implementation
    }
} 