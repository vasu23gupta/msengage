const express = require('express');
const router = express.Router();
const User = require('../models/User');

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