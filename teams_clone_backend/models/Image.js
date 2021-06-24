const mongoose = require('mongoose');

const ImageSchema = mongoose.Schema({
    img:
    {
        data: Buffer,
        contentType: String
    },
},{timestamps : true});

module.exports = mongoose.model('Image', ImageSchema);