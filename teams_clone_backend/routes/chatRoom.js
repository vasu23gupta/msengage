const mongoose = require('mongoose');
const express = require('express');
require('../models/ChatRoom.js');
const ChatRoomModel = mongoose.model('ChatRoom');
const ChatMessageModel = require('../models/ChatMessage.js');
const UserModel = require('../models/User.js');
const router = express.Router();

router.post('/room/message/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const messageText = req.body.messageText;
    const isMedia = req.body.isMedia;
    const currentLoggedUser = req.get('authorisation');
    const post = await ChatMessageModel.createPostInChatRoom(roomId, messageText, currentLoggedUser, isMedia);
    global.io.sockets.emit('new message', { message: post });
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

router.patch('/room/changeRoomIcon/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const room = await ChatRoomModel.findById({ _id: roomId });
    ChatRoomModel.uploadedChatPicture(req, res, function (err) {
      if (err) {
        console.log('*******Multer Error: ', err);
        return res.status(500).json({ success: false, error: error })
      }
      if (req.file) {
        room.imgUrl = 'https://www.backend.zecide.com/' + ChatRoomModel.chatPicturePath + '/' + req.file.filename;
        room.save();
        return res.status(200).json({
          success: true,
          message: "Operation performed successfully"
        });
      }
    });

  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

router.patch('/room/removeRoomIcon/:roomId', async (req, res, next) => {
  try {
    var roomId = req.params.roomId;
    let room = await ChatRoomModel.getChatRoomByRoomId(roomId);
    room.imgUrl = null;
    await room.save();
    res.status(200).json({ success: true, conversation: room });
  }
  catch (err) {
    console.log(err);
    res.setHeader('Content-Type', 'application/json');
    res.status(err.status || 500).json({ err: err });
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

router.patch('/room/leave/:roomId',  async (req, res) => {
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
router.post('/initiate', async (req, res) => {
  try {
    const { userIds, name } = req.body;
    const chatInitiator = req.get('authorisation');
    const allUserIds = [...userIds, chatInitiator];
    const chatRoom = await ChatRoomModel.initiateChat(allUserIds, chatInitiator, name);
    return res.status(200).json({ success: true, chatRoom });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

//get all rooms im in
router.get('/', async (req, res) => {
  try {
    const currentLoggedUser = req.get('authorisation');
    // const options = {
    //   page: parseInt(req.query.page) || 0,
    //   limit: parseInt(req.query.limit) || 10,
    // };
    const rooms = await ChatRoomModel.getChatRoomsByUserId(currentLoggedUser);
    //const roomIds = rooms.map(room => room._id);
    // const recentConversation = await ChatMessageModel.getRecentConversation(
    //   roomIds, options, currentLoggedUser
    // );
    return res.status(200).json({ success: true, conversation: rooms });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

//rooms a third person is in
router.get('/getRoomsByUserId/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    const currentLoggedUser = req.get('authorisation');
    const rooms = await ChatRoomModel.getChatRoomsByUserId(userId);
    rooms.forEach(element => {
      if (element.userIds.includes(currentLoggedUser)) element["joined"] = true;
      else element["joined"] = false;
    });
    return res.status(200).json({ success: true, conversation: rooms });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

//created by me
router.get('/myChannels', async (req, res) => {
  try {
    const currentLoggedUser = req.get('authorisation');
    const rooms = await ChatRoomModel.find({ chatInitiator: currentLoggedUser });
    return res.status(200).json({ success: true, conversation: rooms });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

module.exports = router;