import SwiftUI

struct ChatRoomView: View {
    @ObservedObject var viewModel: ChatRoomsViewModel
    var roomId: String
    @State private var message: String = ""

    var body: some View {
        VStack(spacing: .zero) {
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

            if case .rooms(let rooms) = viewModel.state, let messages = rooms[roomId], !messages.isEmpty {
                List {
                    ForEach(messages) { msg in
                        HStack {
                            Text(msg.displayMessage)
                            if !viewModel.isConnected && viewModel.hasQueued(messageId: msg.id, in: roomId) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Messages",
                    systemImage: "bubble.left",
                    description: Text("Send a message to start the conversation.")
                )
            }
            HStack {
                TextField("Type a message", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    guard !message.isEmpty else { return }
                    viewModel.sendMessage(message, to: roomId)
                    message = ""
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("Room: \(roomId)")
    }
} 
