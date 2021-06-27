const mongoose = require("mongoose");

/*
https://www.freecodecamp.org/news/create-a-professional-node-express/
https://github.com/adeelibr/node-playground/tree/master/chapter-1-chat
*/

const chatMessageSchema = new mongoose.Schema(
    {
        chatRoomId: String,
        message: {
            type: String,
            required: true,
        },
        postedByUser: {
            type: String,
            ref: 'Users',
            required: true,
        },
        type: {
            type: String,
            required: true,
        }
    },
    {
        timestamps: true,
        collection: "chatmessages",
    }
);

/**
 * This method will create a post in chat
 * @param {String} roomId - id of chat room
 * @param {String} message - message you want to post in the chat room
 * @param {String} postedByUser - user who is posting the message
 * @param {String} type - whether the message is media or normal message
 */

chatMessageSchema.statics.createPostInChatRoom = async function (chatRoomId, message, postedByUser, type) {
    try {
        const post = await this.create({
            chatRoomId,
            message,
            postedByUser,
            type,
        });
        return post;
    } catch (error) {
        throw error;
    }
}

/**
 * @param {String} chatRoomId - chat room id
 */
chatMessageSchema.statics.getConversationByRoomId = async function (chatRoomId, options = {}) {
    try {
        return this.aggregate([
            { $match: { chatRoomId } },
            { $sort: { createdAt: -1 } },
            // apply pagination
            { $skip: options.page * options.limit },
            { $limit: options.limit },
            { $sort: { createdAt: 1 } },
        ]);
    } catch (error) {
        throw error;
    }
}

/**
 * @param {Array} chatRoomIds - chat room ids
 * @param {{ page, limit }} options - pagination options
 */
chatMessageSchema.statics.getRecentConversation = async function (chatRoomIds, options) {
    try {
        return this.aggregate([
            { $match: { chatRoomId: { $in: chatRoomIds } } },
            {
                $group: {
                    _id: '$chatRoomId',
                    messageId: { $last: '$_id' },
                    chatRoomId: { $last: '$chatRoomId' },
                    message: { $last: '$message' },
                    postedByUser: { $last: '$postedByUser' },
                    createdAt: { $last: '$createdAt' },
                    type: { $last: '$type' },
                }
            },
            { $sort: { createdAt: -1 } },
            // do a join on another table called users, and 
            // get me a user whose _id = postedByUser
            {
                $lookup: {
                    from: 'users',
                    localField: 'postedByUser',
                    foreignField: '_id',
                    as: 'postedByUser',
                }
            },
            {
                $set: { _id: { $toObjectId: "$_id" } }
            },
            { $unwind: "$postedByUser" },
            // do a join on another table called chatrooms, and 
            // get me room details
            {
                $lookup: {
                    from: 'chatrooms',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'roomInfo',
                }
            },
            { $unwind: "$roomInfo" },
            { $unwind: "$roomInfo.userIds" },
            // do a join on another table called users 
            {
                $lookup: {
                    from: 'users',
                    localField: 'roomInfo.userIds',
                    foreignField: '_id',
                    as: 'roomInfo.userProfile',
                }
            },
            {
                $group: {
                    _id: '$roomInfo._id',
                    messageId: { $last: '$messageId' },
                    chatRoomId: { $last: '$chatRoomId' },
                    message: { $last: '$message' },
                    postedByUser: { $last: '$postedByUser' },
                    type: { $last: '$type' },
                    roomInfo: { $addToSet: '$roomInfo.userProfile' },
                    createdAt: { $last: '$createdAt' },
                    name: { $last: '$roomInfo.name' },
                    imgUrl: { $last: '$roomInfo.imgUrl' },
                },
            },
            { $sort: { createdAt: -1 } },
            //apply pagination
            { $skip: options.page * options.limit },
            { $limit: options.limit },
        ]);

    } catch (error) {
        throw error;
    }
}

module.exports = mongoose.model("ChatMessage", chatMessageSchema);