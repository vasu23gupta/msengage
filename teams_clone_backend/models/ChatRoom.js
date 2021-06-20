const mongoose = require("mongoose");
const path = require('path');
const multer = require('multer');
const CHAT_PICTURE_PATH = path.join('/Uploads/ChatIcons');

/*
https://www.freecodecamp.org/news/create-a-professional-node-express/
https://github.com/adeelibr/node-playground/tree/master/chapter-1-chat
*/

const chatRoomSchema = new mongoose.Schema(
  {
    userIds: Array,
    chatInitiator: String,
    name: String,
    imgUrl: String,
    imgExtn: String,
    censoring: {
      type: Boolean,
      default: false,
    },
    events:{
      type: [String],
      required: true
    }
  },
  {
    timestamps: true,
    collection: "chatrooms",
  }
);

let storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, '..', CHAT_PICTURE_PATH));
  },
  filename: function (req, file, cb) {
    cb(null, file.fieldname + '-' + Date.now());
  }
});

//static methods
chatRoomSchema.statics.uploadedChatPicture = multer({ storage: storage }).single('imgUrl');
chatRoomSchema.statics.chatPicturePath = CHAT_PICTURE_PATH;

/**
 * @param {String} userId - id of user
 * @return {Array} array of all chatroom that the user belongs to
 */
chatRoomSchema.statics.getChatRoomsByUserId = async function (userId) {
  try {
    const rooms = await this.find({ userIds: { $in: [userId] } }).lean();
    return rooms;
  } catch (error) {
    throw error;
  }
}

/**
 * @param {String} roomId - id of chatroom
 * @return {Object} chatroom
 */
chatRoomSchema.statics.getChatRoomByRoomId = async function (roomId) {
  try {
    const room = await this.findOne({ _id: roomId });
    return room;
  } catch (error) {
    throw error;
  }
}

/**
 * @param {Array} userIds - array of strings of userIds
 * @param {String} chatInitiator - user who initiated the chat
 */
chatRoomSchema.statics.initiateChat = async function (userIds, chatInitiator, name) {
  try {
    const availableRoom = await this.findOne({
      userIds: {
        $size: userIds.length,
        $all: [...userIds],
      },
      name: name,
    });
    if (availableRoom) {
      return {
        isNew: false,
        message: 'retrieving an old chat room',
        chatRoomId: availableRoom._doc._id,
      };
    }

    const newRoom = await this.create({ userIds, chatInitiator, name });
    return {
      isNew: true,
      message: 'creating a new chatroom',
      chatRoomId: newRoom._doc._id,
    };
  } catch (error) {
    console.log('error on start chat method', error);
    throw error;
  }
}

module.exports = mongoose.model("ChatRoom", chatRoomSchema);