const mongoose = require("mongoose");
const ChatRoomModel = mongoose.model('ChatRoom');

const EventSchema = mongoose.Schema(
    {
        title: { type: String, required: true },
        startTime: { type: Date, required: true },
        endTime: { type: Date, required: true },
        createdBy: { type: String, required: true },
    }, 
    { timestamps: true });

/**
 * Get all the events a user has including team and personal events.
 * @param {String} userId - id of creator of event.
 * @param {RegExp} query - regular expression of search query
 * @return {[Object]} list of events
 */
EventSchema.statics.getEventsByUserId = async function (userId, query = new RegExp(".*", "i")) {
    try {
        // get all rooms a user is in.
        const rooms = await ChatRoomModel.getChatRoomsByUserId(userId);
        var eventIds = [];

        // get all the event ids of those rooms.
        for (let i = 0; i < rooms.length; i++) {
            var room = rooms[i];
            for (let j = 0; j < room.events.length; j++) {
                eventIds.push(room.events[j]);
            }
        }

        // result
        var events = [];

        // filter those events based on query
        var docs = await this.find({ _id: { $in: eventIds }, title: { $regex: query } });

        events.push(...docs);

        // get all personal events, add them to result only if they are not in there already.
        const userEvents = await this.find({ createdBy: userId, title: { $regex: query } });
        for (let i = 0; i < userEvents.length; i++) {
            var doc = userEvents[i];
            if (events.some(e => e['_id'].equals(doc['_id']))) {
                /* events already contains this doc */
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