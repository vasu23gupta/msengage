const mongoose = require('mongoose');

const UserSchema = mongoose.Schema(
  {
    _id: { type: String },
    username: { type: String, required: true },
    imgUrl: { type: String },
    email: { type: String }
  },
  {
    timestamps: true
  });

/**
 * @param {Array} ids, string of user ids
 * @return {Array of Objects} users list
 */
UserSchema.statics.getUserByIds = async function (ids) {
  try {
    const users = await this.find({ _id: { $in: ids } });
    return users;
  } catch (error) {
    throw error;
  }
}

module.exports = mongoose.model('Users', UserSchema);