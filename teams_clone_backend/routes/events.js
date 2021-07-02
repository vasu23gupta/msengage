const express = require('express');
const router = express.Router();
const Event = require('../models/Event');
const ChatRoom = require('../models/ChatRoom');
const mongoose = require('mongoose');
const EventModel = mongoose.model('Events');

/**
 * create event
 * request:
 *   body: {
 *       title: {String} title of event
 *       startTime: {DateTime} date and time of start of event
 *       endTime: {DateTime} date and time of end of event
 *       createdBy: {String} user id of creator of event
 *       roomId: {String} room id of event, optional
 *   }
 * response:
 *   json: {
 *     success: true/false
 *   }
 */
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

/**
 * gets event with id eventId
 * request:
 *   parameters: 
 *     eventId: event id
 * response:
 *   json: {
 *     event
 *   }
 */
router.get('/:eventId', async (req, res) => {
    try {
        const event = await Event.findById(req.params.eventId);
        res.json(event);
    } catch (err) {
        res.json({ message: err });
    }
});

/**
 * gets all events a user has
 * request:
 *   parameters: 
 *     userId: user id
 * response:
 *   json: {
 *     events: list of events
 *   }
 */
router.get('/user/:userId', async (req, res) => {
    try {
        var events = await EventModel.getEventsByUserId(req.params.userId);
        res.json(events);
    } catch (err) {
        res.json({ message: err });
    }
});

/**
 * deletes event with id eventId
 * request:
 *   parameters: 
 *     eventId: event id
 * response:
 *   json: {
 *     success: true/false
 *   }
 */
router.delete('/:eventId', async (req, res) => {
    try {
        await ChatRoom.updateOne({ events: { $in: req.params.eventId } }, { $pull: { events: req.params.eventId } });
        const event = await Event.findByIdAndDelete(req.params.eventId);
        res.json({ 'success': true });
    } catch (err) {
        console.log(err);
        res.json({ 'success': false, message: err });
    }
});

module.exports = router;