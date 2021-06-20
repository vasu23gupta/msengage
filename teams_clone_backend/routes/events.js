const express = require('express');
const router = express.Router();
const Event = require('../models/Event');
const ChatRoom = require('../models/ChatRoom');
const mongoose = require('mongoose');
const ChatRoomModel = mongoose.model('ChatRoom');

// get all events (for testing)
router.get('/', async (req, res) => {
    try {
        const events = await Event.find();
        res.json(events);
    } catch (err) {
        res.json({ message: err });
    }
});

//create event
router.post('/', async (req, res) => {
    try {
        var event = new Event({
            title: req.body.title,
            startTime: req.body.startTime,
            endTime: req.body.endTime,
            createdBy: req.body.createdBy,
        });
        var savedEvent = await event.save();
        var roomId = req.body.roomId
        if (roomId) {
            var room = await ChatRoom.findByIdAndUpdate(
                roomId,
                { $push: { events: savedEvent._id } },
                { new: true },
            );
        }
        res.json(savedEvent);
    } catch (err) {
        console.log(err);
        res.json({ message: err });
    }
});

router.get('/:eventId', async (req, res) => {
    try {
        const event = await Event.findById(req.params.eventId);
        res.json(event);
    } catch (err) {
        res.json({ message: err });
    }
});

router.get('/user/:userId', async (req, res) => {
    try {
        const rooms = await ChatRoomModel.getChatRoomsByUserId(req.params.userId);
        var eventIds = [];
        for (let i = 0; i < rooms.length; i++) {
            var room = rooms[i];
            for (let j = 0; j < room.events.length; j++) {
                eventIds.push(room.events[j]);
            }
        }
        var events = [];
        for (let i = 0; i < eventIds.length; i++) {
            var doc = await Event.findById(eventIds[i]);
            events.push(doc);
        }
        const userEvents = await Event.find({ createdBy: req.params.userId });
        for (let i = 0; i < userEvents.length; i++) {
            var doc = userEvents[i];
            if (events.some( e => !e['_id'].equals(doc['_id'] ))) {
                /* events already contains this doc */
                events.push(doc);   
            }
        }
        res.json(events);
    } catch (err) {
        res.json({ message: err });
    }
});

module.exports = router;