const mongoose = require('mongoose');
const express = require('express');
require('../models/ChatRoom.js');
const ChatRoomModel = mongoose.model('ChatRoom');
const ChatMessageModel = require('../models/ChatMessage.js');
const UserModel = require('../models/User.js');
const router = express.Router();
const Image = require('../models/Image');
const upload = require('../shared/multer_configuration');

/**
 * sends message in room with room id req.params.roomId
 * request:
 *   parameters: 
 *     roomId: room id
 *   headers: {
 *     authorisation: {String} uid of user sending the message.
 *   }
 *   body: {
 *       messageText: {String} message content
 *       type: {String} type of message ("text", "location", "image", "file")
 *   }
 * response:
 *   json: {
 *     success: true/false
 *   }
 */
router.post('/room/message/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const messageText = req.body.messageText;
    const type = req.body.type;
    const currentLoggedUser = req.get('authorisation');
    const post = await ChatMessageModel.createPostInChatRoom(roomId, messageText, currentLoggedUser, type);
    //console.log(roomId);
    global.io.sockets.in(roomId).emit('new message', { message: post });
    return res.status(200).json({ success: true });
  } catch (error) {
    console.log(error);
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

router.patch('/room/join/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const room = await ChatRoomModel.findByIdAndUpdate(
      roomId,
      { $push: { userIds: req.get('authorisation') } }
    );
    if (room)
      return res.status(200).json({ success: true });
    else
      return res.status(404).json({ success: false });
  } catch (error) {
    console.log(error);
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

/**
 * changes room name of room with room id req.params.roomId
 * request:
 *   parameters: 
 *     roomId: room id
 *   body: {
 *       name: {String} new room name
 *   }
 * response:
 *   json: {
 *     success: true/false
 *   }
 */
router.patch('/room/changeRoomName/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const room = await ChatRoomModel.updateOne(
      { _id: roomId },
      { $set: { name: req.body.name } }
    );
    return res.status(200).json({ success: true });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

/**
 * change room censorship of room with room id req.params.roomId
 * request:
 *   parameters: 
 *     roomId: room id
 *   body: {
 *       censoring: {boolean} whether censoring or not
 *   }
 * response:
 *   json: {
 *     success: true/false
 *   }
 */
router.patch('/room/changeRoomCensorship/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const room = await ChatRoomModel.updateOne(
      { _id: roomId },
      { $set: { censoring: req.body.censoring } }
    );
    return res.status(200).json({ success: true });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

/**
 * changes icon of room with room id req.params.roomId
 * request:
 *   parameters: 
 *     roomId: room id
 *   form data: {
 *       image: image
 *   }
 *   body: {
 *       old: {String} existing icon id
 *   }
 * response:
 *   json: {
 *     success: true/false
 *     imgUrl: {String} new image id
 *   }
 */
router.patch('/room/changeRoomIcon/:roomId', upload.single('image'), async (req, res) => {
  try {
    const roomId = req.params.roomId;
    var f = req.file;
    const savedImage = await Image.uploadImage(f, false);
    const oldImg = req.body.old;
    if (oldImg) await Image.deleteOne({ _id: oldImg });
    const room = await ChatRoomModel.updateOne({ _id: roomId }, { $set: { imgUrl: savedImage._id } });
    return res.status(200).json({ success: true, 'imgUrl': savedImage._id });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

/**
 * remove icon of room with room id req.params.roomId
 * request:
 *   parameters: 
 *     roomId: room id
 *   body: {
 *       old: {String} existing icon id
 *   }
 * response:
 *   json: {
 *     success: true/false
 *   }
 */
router.patch('/room/removeRoomIcon/:roomId', async (req, res) => {
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

/**
 * add users in room with room id req.params.roomId
 * request:
 *   parameters: 
 *     roomId: room id
 *   body: {
 *       users: {[String]} array of users ids to be added
 *   }
 * response:
 *   json: {
 *     success: true/false
 *   }
 */
router.patch('/room/addUsers/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const room = await ChatRoomModel.updateOne(
      { _id: roomId },
      { $push: { userIds: { $each: req.body.users } } }
    );
    return res.status(200).json({ success: true });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

/**
 * leave room with room id req.params.roomId
 * request:
 *   parameters: 
 *     roomId: room id
 *   headers: {
 *     authorisation: {String} uid of user leaving the room.
 *   }
 * response:
 *   json: {
 *     success: true/false
 *   }
 */
router.patch('/room/leave/:roomId', async (req, res) => {
  try {
    const roomId = req.params.roomId;
    const room = await ChatRoomModel.updateOne(
      { _id: roomId }, {
      $pull: { userIds: req.get('authorisation') }
    });
    return res.status(200).json({ success: true });
  } catch (error) {
    console.log(error);
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

/**
 * gets all messages, users, and event ids of room with room id req.params.roomId
 * request:
 *   parameters: 
 *     roomId: room id
 *  query paramters:
 *     page: {Number} page number for pagination, optional
 *     limit: {Number} number of messages to be sent in reponse, optional
 * response:
 *   json: {
 *     success: true/false,
 *     conversation: array of chat messages,
 *     users: array of users in this room,
 *     room: chat room with room details and event ids
 *   }
 */
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

/**
 * creates new chat room.
 * request:
 *   body: {
 *       users: {[String]} array of users ids to be added,
 *       name: {String} room name
 *       chatInitiator: {String} uid of user creating the room
 *   }
 *   form data: {
 *       image: {image} room icon
 *   }
 * response:
 *   json: {
 *     success: true/false
 *     chatRoom: {ChatRoom Object} create or existing chat room
 *   }
 */
router.post('/initiate', upload.single('image'), async (req, res) => {
  try {
    var { userIds, name, chatInitiator, initiationMessageFlag } = req.body;
    var allUserIds;
    // = [...userIds, chatInitiator];
    if (Array.isArray(userIds)) allUserIds = [...userIds, chatInitiator];
    else allUserIds = [userIds, chatInitiator];
    var f = req.file;
    if (!name) name = "New chat";
    const chatRoom = await ChatRoomModel.initiateChat(allUserIds, chatInitiator, name, f);
    var initiationMessage;
    if (initiationMessageFlag == "chatroom") {
      await ChatMessageModel.createPostInChatRoom(
        chatRoom.chatRoomId,
        "Created the group",
        chatInitiator,
        "text"
      );
    }
    else if(initiationMessageFlag == "meeting"){
      await ChatMessageModel.createPostInChatRoom(
        chatRoom.chatRoomId,
        "Started a meeting. Share the following meeting id to join the meeting.",
        chatInitiator,
        "text"
      );
      await ChatMessageModel.createPostInChatRoom(
        chatRoom.chatRoomId,
        chatRoom.chatRoomId,
        chatInitiator,
        "text"
      );
    }
    return res.status(200).json({ success: true, chatRoom });
  } catch (error) {
    console.log(error);
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

//get all rooms im in
/**
 * gets all rooms a user is in, the rooms' last message and the message's sender.
 * request:
 *   headers: {
 *     authorisation: {String} uid of user sending the message.
 *   }
 * response:
 *   json: {
 *     success: true/false,
 *     conversationg: chat rooms
 *   }
 */
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
    return res.status(200).json({ success: true, conversation: recentConversation });
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, error: error })
  }
});

// router.delete('/room/:roomId', async (req, res) => {
//   try {
//     const roomId = req.params.roomId;
//     const room = await ChatRoomModel.deleteOne({ _id: roomId });
//     const messages = await ChatMessageModel.deleteMany({ chatRoomId: roomId })
//     return res.status(200).json({
//       success: true,
//       message: "Operation performed successfully",
//       deletedRoomsCount: room.deletedCount,
//       deletedMessagesCount: messages.deletedCount,
//     });
//   } catch (error) {
//     return res.status(error.status || 500).json({ success: false, error: error })
//   }
// });

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