import Foundation

protocol NetworkMonitorProtocol {
    var isConnected: Bool { get }
    var onStatusChange: ((Bool) -> Void)? { get set }
    func startMonitoring()
    func stopMonitoring()
} 