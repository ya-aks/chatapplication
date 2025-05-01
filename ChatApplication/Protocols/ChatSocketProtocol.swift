import Foundation
import Channels

protocol ChatSocketProtocol {
    var onMessageReceived: ((_ roomId: String, _ message: String) -> Void)? { get set }
    var onConnect: ((_ roomIds: [String]) -> Void)? { get set }
    func disconnect()
    func sendMessage(_ message: String, to roomId: String) throws
    func subscribe(to roomId: String) throws
}

protocol ChatSocketConnectionProtocol {
    func connect()
}
