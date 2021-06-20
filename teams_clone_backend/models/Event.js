const mongoose = require("mongoose");

const EventSchema = mongoose.Schema({
    title: {
        type: String,
        required: true,
    },
    startTime: {
        type: Date,
        required: true,
    },
    endTime: {
        type: Date,
        required: true,
    },
    createdBy: {
        type: String,
        required: true,
    },
}, { timestamps: true });

module.exports = mongoose.model('Events', EventSchema);