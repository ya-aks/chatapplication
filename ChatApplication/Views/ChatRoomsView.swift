import SwiftUI

struct ChatRoomsView: View {
    @StateObject private var viewModel: ChatRoomsViewModel
    @State private var showingRoomNamePrompt = false
    @State private var newRoomName = ""

    init() {
        let socket = PieSocketChatSocket()
        let queue = SimpleMessageQueue()
        let monitor = MockNetworkMonitor()
        _viewModel = StateObject(wrappedValue: ChatRoomsViewModel(socket: socket, queue: queue, monitor: monitor))
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    Button {
                        (viewModel.networkMonitor as? MockNetworkMonitor)?.toggleConnection()
                    } label: {
                        Image(systemName: viewModel.isConnected ? "wifi" : "wifi.slash")
                            .foregroundColor(viewModel.isConnected ? .green : .red)
                    }
                    .padding()
                }

                switch viewModel.state {
                case .error(let message):
                    VStack {
                        ContentUnavailableView(
                            "Connection Error",
                            systemImage: "exclamationmark.triangle.fill",
                            description: Text(message)
                        )
                        if !viewModel.isConnected {
                            Button("Retry Connection") {
                                (viewModel.networkMonitor as? MockNetworkMonitor)?.toggleConnection()
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                        }
                    }
                    
                case .empty:
                    ContentUnavailableView(
                        "No Chat Rooms",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Create a new chat room to start messaging.")
                    )
                    
                case .rooms(let rooms):
                    VStack(spacing: 0) {
                        List(rooms.keys.sorted(), id: \.self) { roomId in
                            NavigationLink(destination: ChatRoomView(viewModel: viewModel, roomId: roomId)) {
                                VStack(alignment: .leading) {
                                    Text("Room: \(roomId)")
                                        .font(.headline)
                                    HStack {
                                        Text(rooms[roomId]?.last?.content ?? "No messages")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        if !viewModel.isConnected && viewModel.hasPendingMessages(for: roomId) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.orange)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                VStack(spacing: .zero) {
                    if !viewModel.isConnected {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.orange)
                                .frame(width: 12, height: 12)
                            Text("Offline - Messages will be sent when back online")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .frame(maxWidth: .infinity)
                        .cornerRadius(4)
                        .padding(10)
                        .background(Color.orange.opacity(0.1))
                    }
                    
                    Button("+ Create Chat Room") {
                        showingRoomNamePrompt = true
                    }
                    .padding()
                    .disabled(!viewModel.isConnected)
                }
            }
            .alert("Create New Chat Room", isPresented: $showingRoomNamePrompt) {
                TextField("Room Name", text: $newRoomName)
                Button("Cancel", role: .cancel) {
                    newRoomName = ""
                }
                Button("Create") {
                    if !newRoomName.isEmpty {
                        _ = viewModel.createChatRoom(name: newRoomName)
                        newRoomName = ""
                    }
                }
            } message: {
                Text("Enter a name for your new chat room")
            }
        }
    }
} 
