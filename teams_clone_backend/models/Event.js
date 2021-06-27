const mongoose = require("mongoose");
const ChatRoomModel = mongoose.model('ChatRoom');

const EventSchema = mongoose.Schema({
    title: {
        type: String,
        required: true,
    },
    startTime: {
        type: Date,
        required: true,
    },
    endTime: {
        type: Date,
        required: true,
    },
    createdBy: {
        type: String,
        required: true,
    },
}, { timestamps: true });

EventSchema.statics.getEventsByUserId = async function (userId, query = new RegExp(".*", "i")) {
    try {
        const rooms = await ChatRoomModel.getChatRoomsByUserId(userId);
        var eventIds = [];
        for (let i = 0; i < rooms.length; i++) {
            var room = rooms[i];
            for (let j = 0; j < room.events.length; j++) {
                eventIds.push(room.events[j]);
            }
        }
        var events = [];
        for (let i = 0; i < eventIds.length; i++) {
            var doc = await this.find({ _id: eventIds[i], title: { $regex: query } });
            events.push(doc);
        }
        const userEvents = await this.find({ createdBy: userId, title: { $regex: query } });
        for (let i = 0; i < userEvents.length; i++) {
            var doc = userEvents[i];
            if (events.some(e => e['_id'].equals(doc['_id']))) {
                /* events already contains this doc */
                //events.push(doc);
            }
            else events.push(doc);
        }
        return events;
    }
    catch (err) {
        console.log(err);
        res.json({ message: err });
    }
}

module.exports = mongoose.model('Events', EventSchema);