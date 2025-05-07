import Foundation
import Combine

enum ChatRoomsState: Equatable {
    case error(String)
    case empty
    case rooms([String: [Message]])
}

class ChatRoomsViewModel: ObservableObject {
    @Published private(set) var state: ChatRoomsState = .empty
    @Published var isConnected: Bool = true

    private var chatSocket: ChatSocketProtocol
    private let queue: MessageQueueProtocol
    var networkMonitor: NetworkMonitorProtocol
    private var cancellables = Set<AnyCancellable>()
    private let messageQueue = DispatchQueue(label: "com.chatapp.messages", qos: .background, attributes: [])

    // MARK: init
    init(socket: ChatSocketProtocol, queue: MessageQueueProtocol, monitor: NetworkMonitorProtocol) {
        self.chatSocket = socket
        self.queue = queue
        self.networkMonitor = monitor
        
        // start monitoring network and receiving messages
        setupBindings()
        networkMonitor.startMonitoring()
    }
    
    // MARK: Private Methods
    private func updateRooms(roomId: String, message: Message? = nil) {
        messageQueue.async { [weak self] in
            guard let self else { return }
            if case .rooms(var rooms) = self.state {
                if let message = message {
                    rooms[roomId, default: []].append(message)
                } else {
                    rooms[roomId] = []
                }
                self.update(state: .rooms(rooms))
            } else {
                self.update(state: .rooms([roomId: []]))
            }
        }
    }
    
    private func setupBindings() {
        chatSocket.onMessageReceived = { [weak self] roomId, message in
            guard let self else { return }
            self.updateRooms(roomId: roomId, message: Message(content: message))
        }

        chatSocket.onConnect = { [weak self] roomIds in
            guard let self else { return }
            let roomMessages = Dictionary(uniqueKeysWithValues: roomIds.map { ($0, [Message]()) })
            self.update(state: .rooms(roomMessages))
        }

        networkMonitor.onStatusChange = { [weak self] status in
            guard let self else { return }
            self.isConnected = status
        }
        
        $isConnected.receive(on: DispatchQueue.main).sink { [weak self] isConnected in
            guard let self else { return }
            if isConnected {
                self.retryQueuedMessages()
            }
        }.store(in: &cancellables)
    }
    
    private func retryQueuedMessages() {
        if case .rooms(let rooms) = state {
            for roomId in rooms.keys {
                while let msg = queue.dequeue(for: roomId) {
                    do {
                        try chatSocket.sendMessage(msg.content, to: roomId)
                    } catch {
                        self.update(state: .error("Failed to retry sending message: \(error.localizedDescription)"))
                        self.queue.enqueue(msg, for: roomId)
                    }
                }
            }
        }
    }
    
    private func update(state: ChatRoomsState) {
        DispatchQueue.main.async {
            self.state = state
        }
    }

    // MARK: Public Methods
    func createChatRoom(name: String) -> String? {
        guard isConnected else {
            update(state: .error("Cannot create new chat room while offline"))
            return nil
        }
        
        let roomId = "\(name)"
        do {
            try chatSocket.subscribe(to: roomId)
            updateRooms(roomId: roomId)
            return roomId
        } catch {
            update(state: .error("Failed to subscribe to chat room: \(error.localizedDescription)"))
            return nil
        }
    }

    func sendMessage(_ message: String, to roomId: String) {
        let newMessage = Message(content: "\(message)", isQueued: !isConnected, isSent: true)
        
        if isConnected {
            do {
                try chatSocket.sendMessage(message, to: roomId)
            } catch {
                update(state: .error("Failed to send message: \(error.localizedDescription)"))
                queue.enqueue(newMessage, for: roomId)
            }
        } else {
            queue.enqueue(newMessage, for: roomId)
        }
        
        updateRooms(roomId: roomId, message: newMessage)
    }
    
    func hasPendingMessages(for roomId: String) -> Bool {
        return !queue.isQueueEmpty(for: roomId)
    }
    
    func hasQueued(messageId: UUID, in roomId: String) -> Bool {
        return queue.hasQueued(messageId: messageId, in: roomId)
    }

    // MARK: init
    deinit {
        chatSocket.disconnect()
        networkMonitor.stopMonitoring()
    }
} 
