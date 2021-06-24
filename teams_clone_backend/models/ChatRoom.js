const mongoose = require("mongoose");

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

//static methods

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
 * @param {String} name - name of chatroom
 */
chatRoomSchema.statics.initiateChat = async function (userIds, chatInitiator, name, image) {
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

    const savedImage = await image.save();
    const imgUrl = savedImage._id;
    const newRoom = await this.create({ userIds, chatInitiator, name, imgUrl });
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