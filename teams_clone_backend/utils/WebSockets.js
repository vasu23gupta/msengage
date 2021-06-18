class WebSockets {
    connection(client) {
        // event fired when the chat room is disconnected
        console.log('chat connected');

        // add identity of user mapped to the socket id
        client.on("identity", (userId) => { });

        // subscribe person to chat & other user as well
        client.on("subscribe", (room) => {
            client.join(room.room);
        });

        // mute a chat room
        client.on("unsubscribe", (room) => {
            client.leave(room);
        });
    }
}

module.exports = new WebSockets();