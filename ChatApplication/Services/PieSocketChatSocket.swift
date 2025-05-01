import Foundation
import Network
import Channels

class PieSocketChatSocket: ChatSocketProtocol {
    var onMessageReceived: ((String, String) -> Void)?
    var onConnect: ((_ roomIds: [String]) -> Void)?
    private var channelClients: [String: Channel] = [:]
    private var pieSocket: PieSocket

    init() {
        let options: PieSocketOptions = PieSocketOptions()
        options.setClusterId(clusterId: "s14578.blr1")
        options.setApiKey(apiKey: "g8uFOIZAnlRIxbdQPfCQ7SZdTr6dN0oNRBCaI3eY")

        pieSocket = PieSocket(pieSocketOptions: options)
        self.loadExistingRooms()
    }
    
    private func loadExistingRooms() {
        let rooms = pieSocket.getAllRooms()
        for (roomId, channel) in rooms {
            channelClients[roomId] = channel
            _ = channel.listen(eventName: "system:message", callback: { [weak self] event in
                self?.onMessageReceived?(roomId, event.getData())
            })
        }
        onConnect?(Array(rooms.keys))
    }
    
    func disconnect() {
        for client in channelClients.values {
            client.disconnect()
        }
        channelClients.removeAll()
    }

    func subscribe(to roomId: String) throws {
        let channel = pieSocket.join(roomId: roomId)
        
        _ = channel.listen(eventName: "system:message", callback: { [weak self] event in
            self?.onMessageReceived?(roomId, event.getData())
        })

        channelClients[roomId] = channel
    }

    func sendMessage(_ message: String, to roomId: String) throws {
        guard let channel = channelClients[roomId] else { return }
        channel.send(text: message)
    }
} 
