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
    private func setupBindings() {
        chatSocket.onMessageReceived = { [weak self] roomId, message in
            guard let self else {
                return
            }
            
            if case .rooms(var rooms) = self.state {
                rooms[roomId, default: []].append(Message(content: message))
                self.update(state: .rooms(rooms))
            }
        }

        chatSocket.onConnect = { [weak self] roomIds in
            guard let self else {
                return
            }
            let roomMessages = Dictionary(uniqueKeysWithValues: roomIds.map { ($0, [Message]()) })
            self.update(state: .rooms(roomMessages))
        }

        networkMonitor.onStatusChange = { [weak self] status in
            guard let self else {
                return
            }
            self.isConnected = status
        }
        
        $isConnected.receive(on: DispatchQueue.main).sink { isConnected in
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
                        DispatchQueue.main.async {
                            self.state = .error("Failed to retry sending message: \(error.localizedDescription)")
                            self.queue.enqueue(msg, for: roomId)
                        }
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
            state = .error("Cannot create new chat room while offline")
            return nil
        }
        
        let roomId = "\(name)"
        do {
            try chatSocket.subscribe(to: roomId)
            if case .rooms(var rooms) = state {
                rooms[roomId] = []
                state = .rooms(rooms)
            } else {
                state = .rooms([roomId: []])
            }
            return roomId
        } catch {
            DispatchQueue.main.async {
                self.update(state: .error("Failed to subscribe to chat room: \(error.localizedDescription)"))
            }
            return nil
        }
    }

    func sendMessage(_ message: String, to roomId: String) {
        let newMessage = Message(content: "\(message)", isQueued: !isConnected, isSent: true)
        
        if isConnected {
            do {
                try chatSocket.sendMessage(message, to: roomId)
            } catch {
                self.update(state: .error("Failed to send message: \(error.localizedDescription)"))
                self.queue.enqueue(newMessage, for: roomId)
            }
        } else {
            queue.enqueue(newMessage, for: roomId)
        }
        
        if case .rooms(var rooms) = state {
            rooms[roomId, default: []].append(newMessage)
            state = .rooms(rooms)
        }
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
