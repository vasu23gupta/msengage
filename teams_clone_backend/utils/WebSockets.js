class WebSockets {
    users = [];

    connection(client) {
        // event fired when the chat room is disconnected
        console.log('chat connected');
        client.on("disconnect", () => {
            this.users = this.users.filter((user) => user.socketId !== client.id);
        });
        // add identity of user mapped to the socket id
        client.on("identity", (userId) => {
            if (Array.isArray(this.users)) {
                this.users.push({
                    socketId: client.id,
                    userId: userId,
                });
            } else {
                this.users = [{
                    socketId: client.id,
                    userId: userId,
                }];
            }
        });
        // subscribe person to chat & other user as well
        client.on("subscribe", (room, otherUserId = "") => {
            const userSockets = this.users.filter(
                (user) => user.userId === otherUserId
            );
            userSockets.map((userInfo) => {
                const socketConn = global.io.sockets.connected(userInfo.socketId);
                if (socketConn) {
                    socketConn.join(room);
                }
            });

            client.join(room);
        });
        // mute a chat room
        client.on("unsubscribe", (room) => {
            client.leave(room);
        });

        client.on("new message", (mssg) => {
            var msg = JSON.parse(mssg);
            //client.broadcast.emit("new message", {"message" : mssg});
            client.broadcast.in(msg.room).emit("new message", {"message" : mssg});
            global.io.to(msg.room).emit("new message", {"message" : mssg});
            global.io.in(msg.room).emit("new message", {"message" : mssg});
            global.io.sockets.to(msg.room).emit("new message", {"message" : mssg});
            global.io.sockets.in(msg.room).emit("new message", {"message" : mssg});
            client.to(msg.room).emit("new message", {"message" : mssg});
            client.in(msg.room).emit("new message", {"message" : mssg});
        });
    }
}

module.exports = new WebSockets();