const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Image = require('../models/Image');
const Event = require('../models/Event');
const mongoose = require("mongoose");
const EventModel = mongoose.model('Events');
const ChatRoomModel = mongoose.model('ChatRoom');
const ChatMessage = require('../models/ChatMessage.js');
const upload = require('../shared/multer_configuration');
//const cp = require('child_process');
const https = require('https');
const querystring = require('querystring');

const dotenv = require('dotenv');
dotenv.config();

/**
 * add firebase user to database
 * request:
 *   headers: {
 *     authorisation: {String} uid of user of firebase user.
 *   }
 *   body: {
 *       username: {String} username of user
 *       email: {String} email of user
 *   }
 * response:
 *   json: {
 *     savedUser: created user
 *   }
 */
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

/**
 * get userid from email
 * request:
 *   parameters: 
 *     email: email
 * response:
 *   json: {
 *     user: user id
 *   }
 */
router.get('/:email', async (req, res) => {
    try {
        var em = req.params.email;
        const user = await User.findOne({ email: em }, { _id: 1 }); // get only the id
        res.json(user);
    } catch (err) {
        console.log(err);
        res.json({ message: err });
    }
});

/**
 * change user icon
 * request:
 *   parameters: 
 *     uid: user id
 *   form data: {
 *       image: image
 *   }
 *   body: {
 *       old: {String} image id of existing icon
 *   }
 * response:
 *   json: {
 *     success: true/false
 *     imgUrl: id of new image
 *   }
 */
router.patch('/changeIcon/:uid', upload.single('image'), async (req, res) => {
    try {
        const uid = req.params.uid;
        var f = req.file;
        const savedImage = await Image.uploadImage(f, false);
        const oldImg = req.body.old;
        if (oldImg) await Image.deleteOne({ _id: oldImg });
        await User.updateOne({ _id: uid }, { $set: { imgUrl: savedImage._id } });
        return res.status(200).json({ success: true, 'imgUrl': savedImage._id });
    } catch (error) {
        return res.status(error.status || 500).json({ success: false, error: error })
    }
});

/**
 * remove image
 * request:
 *   parameters: 
 *     uid: user id
 *   body: {
 *       old: {String} image id of existing icon
 *   }
 * response:
 *   json: {
 *     success: true/false
 *   }
 */
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

/**
 * search for events, chat rooms, messages
 * request:
 *   parameters: 
 *     query: search query
 *   headers: {
 *     authorisation: {String} uid of user searching
 *   }
 * response:
 *   json: {
 *     rooms: list of chat rooms
 *     events: list of events
 *     messages: list of messages
 *   }
 */
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
        res.json({ rooms: rooms, events: events, messages: messages });
    }
    catch (err) {
        console.log(err);
        return res.status(err.status || 500).json({ error: err })
    }
});

/**
 * get address from latlng
 * request:
 *   parameters: 
 *     lat: latitude
 *     lng: longitude
 * response:
 *   json: {
 *     address: {String} address of coordindates
 *   }
 */
router.get('/address/:lat/:lng', async (req, res) => {
    const lat = req.params.lat;
    const lng = req.params.lng;
    try {
        let output = '';
        const parameters = {
            key: process.env.LOCATIONIQ_API_KEY,
            lat: lat,
            lon: lng,
            format: 'json'
        }
        const get_request_args = querystring.stringify(parameters);
        https.get("https://eu1.locationiq.com/v1/reverse.php/?" + get_request_args, (ress) => {
            ress.setEncoding('utf8');
            ress.on('data', (chunk) => {
                output += chunk;
            });
            ress.on('end', () => {
                let obj = (output);
                res.json({ "address": JSON.parse(obj).display_name });
            });
        });
    } catch (err) {
        res.json({ message: err });
    }
});

// router.post('/assistant', async (req, res) => {
//     const query = req.body.query;
//     var cmd = "python ./assistant.py " + "\"" + query + "\"";
//     cp.exec(cmd, (err, stdout) => {
//         if (err) {
//             console.log(err);
//             res.setHeader('Content-Type', 'application/json');
//             res.end(JSON.stringify({ err: err }));
//         }
//         else {
//             res.send(JSON.parse(stdout));
//         }
//     });
// });

module.exports = router;