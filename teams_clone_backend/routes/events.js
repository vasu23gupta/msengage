const express = require('express');
const router = express.Router();
const Event = require('../models/Event');
const ChatRoom = require('../models/ChatRoom');
const mongoose = require('mongoose');
const EventModel = mongoose.model('Events');

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
        var events = await EventModel.getEventsByUserId(req.params.userId);
        res.json(events);
    } catch (err) {
        res.json({ message: err });
    }
});

router.delete('/:eventId', async (req, res) => {
    try {
        await ChatRoom.updateOne({ events: { $in: req.params.eventId } }, {$pull: {events: req.params.eventId}});
        const event = await Event.findByIdAndDelete(req.params.eventId);
        res.json(event);
    } catch (err) {
        console.log(err);
        res.json({ message: err });
    }
});

module.exports = router;