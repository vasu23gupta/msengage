const express = require('express');
const router = express.Router();
const User = require('../models/User');
const fs = require('fs');
const Image = require('../models/Image');
const multer = require('multer');
const Event = require('../models/Event');
const mongoose = require("mongoose");
const EventModel = mongoose.model('Events');
const ChatRoomModel = mongoose.model('ChatRoom');
const ChatMessage = require('../models/ChatMessage.js');

const storage = multer.diskStorage({
    filename: function (req, file, cb) {
        cb(null, file.originalname);
    }
});

const upload = multer({
    storage: storage,
    limits: {
        fileSize: 15 * 1024 * 1024
    }
});

// get all users (for testing)
router.get('/', async (req, res) => {
    try {
        const users = await User.find();
        res.json(users);
    } catch (err) {
        res.json({ message: err });
    }
});

//add user
router.post('/', async (req, res) => {
    try {
        var userId = req.get('authorisation');
        const user = new User({
            _id: userId,
            username: req.body.username,
            email: req.body.email
        });
        const savedUser = await user.save();
        res.json(savedUser);
    } catch (err) {
        console.log(err);
        res.json({ message: err });
    }
});

//get userid from email
router.get('/:email', async (req, res) => {
    try {
        var em = req.params.email;
        const user = await User.findOne({ email: em }, { _id: 1 });
        res.json(user);
    } catch (err) {
        console.log(err);
        res.json({ message: err });
    }
});

router.patch('/changeIcon/:uid', upload.single('image'), async (req, res) => {
    try {
        const uid = req.params.uid;
        var f = req.file;
        var image = new Image();
        image.img.data = fs.readFileSync(f.path);
        image.img.contentType = f.mimetype;
        const savedImage = await image.save();
        const oldImg = req.body.old;
        if (oldImg) await Image.deleteOne({ _id: oldImg });
        await User.updateOne({ _id: uid }, { $set: { imgUrl: savedImage._id } });
        return res.status(200).json({ success: true, 'imgUrl': savedImage._id });
    } catch (error) {
        return res.status(error.status || 500).json({ success: false, error: error })
    }
});

router.patch('/removeIcon/:uid', async (req, res, next) => {
    try {
        var uid = req.params.uid;
        await User.updateOne({ _id: uid }, { $set: { imgUrl: undefined } });
        await Image.deleteOne({ _id: req.body.old });
        res.status(200).json({ success: true });
    }
    catch (err) {
        console.log(err);
        return res.status(err.status || 500).json({ success: false, error: err })
    }
});

router.get('/search/:query', async (req, res) => {
    try {
        const query = req.params.query;
        const userId = req.get('authorisation');
        var reg = new RegExp(query, "i");
        var rooms = await ChatRoomModel.getChatRoomsByUserId(userId);
        const roomIds = rooms.map(room => room._id.toString());
        let events = await EventModel.getEventsByUserId(userId, reg);
        let messages = await ChatMessage.find({
            chatRoomId: { $in: roomIds },
            message: { $regex: reg },
            $or: [
                { type: "text" },
                { type: "file" }
            ]
        }).populate('postedByUser');
        rooms = await ChatRoomModel.find({ userIds: { $in: [userId] }, name: { $regex: reg } });
        //console.log(rooms);
        //console.log(events);
        //console.log(messages);
        res.json({ rooms: rooms, events: events, messages: messages });
    }
    catch (err) {
        console.log(err);
        return res.status(err.status || 500).json({ success: false, error: err })
    }
});

// router.patch('/:userId', async (req, res) => {
//     try {
//         const updatedUser = await User.updateOne({ _id: req.params.userId }, {
//             $push: {
//                 vendors: req.body.vendorId
//             },
//         });
//         res.json(updatedUser);
//     } catch (err) {
//         res.json({ message: err });
//     }
// });

module.exports = router;