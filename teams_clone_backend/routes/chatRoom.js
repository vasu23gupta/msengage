const mongoose = require('mongoose');
const express = require('express');
require('../models/ChatRoom.js');
const fs = require('fs');
const ChatRoomModel = mongoose.model('ChatRoom');
const ChatMessageModel = require('../models/ChatMessage.js');
const UserModel = require('../models/User.js');
const router = express.Router();
const Image = require('../models/Image');
const multer = require('multer');

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

router.post('/room/message/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const messageText = req.body.messageText;
    const type = req.body.type;
    const currentLoggedUser = req.get('authorisation');
    const post = await ChatMessageModel.createPostInChatRoom(roomId, messageText, currentLoggedUser, type);
    global.io.sockets.in(roomId).emit('new message', { message: post });
    return res.status(200).json({ success: true, post: post });
  } catch (error) {
    console.log(error);
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

router.patch('/room/changeRoomName/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const room = await ChatRoomModel.updateOne({ _id: roomId }, {
      $set: {
        name: req.body.name
      }
    });
    return res.status(200).json({
      success: true,
      message: "Operation performed successfully"
    });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

router.patch('/room/changeRoomCensorship/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const room = await ChatRoomModel.updateOne({ _id: roomId }, {
      $set: {
        censoring: req.body.censoring
      }
    });
    return res.status(200).json({
      success: true,
      message: "Operation performed successfully"
    });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

router.patch('/room/changeRoomIcon/:roomId', upload.single('image'), async (req, res) => {
  try {
    const roomId = req.params.roomId;
    var f = req.file;
    var image = new Image();
    image.img.data = fs.readFileSync(f.path);
    image.img.contentType = f.mimetype;
    const savedImage = await image.save();
    const oldImg = req.body.old;
    if (oldImg) await Image.deleteOne({ _id: oldImg });
    const room = await ChatRoomModel.updateOne({ _id: roomId }, { $set: { imgUrl: savedImage._id } });
    return res.status(200).json({ success: true, 'imgUrl': savedImage._id });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

router.patch('/room/removeRoomIcon/:roomId', async (req, res, next) => {
  try {
    var roomId = req.params.roomId;
    await ChatRoomModel.updateOne({ _id: roomId }, { $set: { imgUrl: undefined } });
    await Image.deleteOne({ _id: req.body.old });
    res.status(200).json({ success: true });
  }
  catch (err) {
    console.log(err);
    return res.status(err.status || 500).json({ success: false, error: err })
  }
});

router.patch('/room/join/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const room = await ChatRoomModel.updateOne({ _id: roomId }, {
      $push: {
        userIds: req.get('authorisation')
      }
    });
    return res.status(200).json({
      success: true,
      message: "Operation performed successfully"
    });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

router.patch('/room/addUsers/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    console.log(req.body.users);
    const room = await ChatRoomModel.updateOne({ _id: roomId }, {
      $push: {
        userIds: { $each: req.body.users }
      }
    });
    console.log(room);
    return res.status(200).json({
      success: true,
      message: "Operation performed successfully"
    });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

router.patch('/room/leave/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const room = await ChatRoomModel.updateOne({ _id: roomId }, {
      $pull: {
        userIds: req.get('authorisation')
      }
    });
    return res.status(200).json({
      success: true,
      message: "Operation performed successfully"
    });
  } catch (error) {
    console.log(error);
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

router.delete('/room/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const room = await ChatRoomModel.deleteOne({ _id: roomId });
    const messages = await ChatMessageModel.deleteMany({ chatRoomId: roomId })
    return res.status(200).json({
      success: true,
      message: "Operation performed successfully",
      deletedRoomsCount: room.deletedCount,
      deletedMessagesCount: messages.deletedCount,
    });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

router.get('/room/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const room = await ChatRoomModel.getChatRoomByRoomId(roomId);
    if (!room) {
      return res.status(400).json({
        success: false,
        message: 'No room exists for this id',
      })
    }
    const users = await UserModel.getUserByIds(room.userIds);
    const options = {
      page: parseInt(req.query.page) || 0,
      limit: parseInt(req.query.limit) || 100,
    };
    const conversation = await ChatMessageModel.getConversationByRoomId(roomId, options);
    return res.status(200).json({
      success: true,
      conversation,
      users,
      room
    });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error });
  }
});

//create new chat room
router.post('/initiate', upload.single('image'), async (req, res) => {
  try {
    const { userIds, name, chatInitiator } = req.body;
    var allUserIds;
    // = [...userIds, chatInitiator];
    if (Array.isArray(userIds)) allUserIds = [...userIds, chatInitiator];
    else allUserIds = [userIds, chatInitiator];
    console.log(allUserIds);
    var f = req.file;
    var image;
    if (f) {
      image = new Image();
      image.img.data = fs.readFileSync(f.path);
      image.img.contentType = f.mimetype;
    }
    const chatRoom = await ChatRoomModel.initiateChat(allUserIds, chatInitiator, name, image);
    await ChatMessageModel.createPostInChatRoom(chatRoom.chatRoomId, "Created the group", chatInitiator, "text");
    return res.status(200).json({ success: true, chatRoom });
  } catch (error) {
    console.log(error);
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

//get all rooms im in
router.get('/', async (req, res) => {
  try {
    const currentLoggedUser = req.get('authorisation');
    const options = {
      page: parseInt(req.query.page) || 0,
      limit: parseInt(req.query.limit) || 1000,
    };
    const rooms = await ChatRoomModel.getChatRoomsByUserId(currentLoggedUser);
    const roomIds = rooms.map(room => room._id.toString());
    const recentConversation = await ChatMessageModel.getRecentConversation(roomIds, options);
    console.log(recentConversation.length);
    return res.status(200).json({ success: true, conversation: recentConversation });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

// //rooms a third person is in
// router.get('/getRoomsByUserId/:userId', async (req, res) => {
//   try {
//     const userId = req.params.userId;
//     const currentLoggedUser = req.get('authorisation');
//     const rooms = await ChatRoomModel.getChatRoomsByUserId(userId);
//     rooms.forEach(element => {
//       if (element.userIds.includes(currentLoggedUser)) element["joined"] = true;
//       else element["joined"] = false;
//     });
//     return res.status(200).json({ success: true, conversation: rooms });
//   } catch (error) {
//     return res.status(error.status || 500).json({ success: false, error: error })
//   }
// });

// //created by me
// router.get('/myChannels', async (req, res) => {
//   try {
//     const currentLoggedUser = req.get('authorisation');
//     const rooms = await ChatRoomModel.find({ chatInitiator: currentLoggedUser });
//     return res.status(200).json({ success: true, conversation: rooms });
//   } catch (error) {
//     return res.status(error.status || 500).json({ success: false, error: error })
//   }
// });

module.exports = router;