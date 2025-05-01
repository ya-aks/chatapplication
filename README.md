# chatapplication
This is a chat application which is created to chat through Rooms. This is using PieSocket for websocket communication.

Functionalities:

1. Can create new room and chat in that room
2. Offline messages will be stored if the user is offline
3. No new rooms can be created while being offline
4. All the messages will be sent who are queued when comes back online
5. After app close all history will go away
6. Error and Empty State Handling


Code Design:
-  ChatSocketProtocol -> To Communicate with WebSocket Server
    - Concrete implementation is PieSocketChatSocket but can be replaced with any other service whenever needed by just injecting a new implementation
-  MessageQueueProtocol -> To handle message queueing (Right now a simple queue but can be replaced with advanced queue by just implementing this protocol)
-  NetworkMonitorProtocol -> To Monitor Network Status (used a mock network status implementation using a toggle but also provided actual network status observer)

Models:
Message to store the message sent

Views:
ChatRoomsView -> To show all the chats 
ChatRoomView -> Is a granular view of a chat from where messages can be sent

ViewModel:
ChatRoomsViewModel -> To link between view and services

Demo Video:
https://drive.google.com/file/d/1sr4vM5dnvPL5fetBHz9sWdGsVxHn4ZJs/view?usp=sharing
