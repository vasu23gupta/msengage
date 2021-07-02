const mongoose = require('mongoose');
const fs = require('fs');
const deepai = require('deepai');
deepai.setApiKey('506d04ca-79e2-4daa-97cd-7eb4c8722a1a');

const ImageSchema = mongoose.Schema({
    img:
    {
        data: Buffer,
        contentType: String,
    },
}, { timestamps: true });

/**
 * @param {Object} file of image to be uploaded
 * @param {boolean} filter to filter nudity or not
 * @return {Object} saved image
 */
ImageSchema.statics.uploadImage = async function (file, filter) {
    try {
        var data = fs.readFileSync(file.path);
        var contentType = file.mimetype;
        var image = await this.create({ img: { data, contentType } });
        // if image has to be censored
        if (filter) {
            var score = 0; // nsfw score between 0 for normal and 1 for explicit image
            var resp = await deepai.callStandardApi("nsfw-detector", {
                image: fs.createReadStream(file.path),
            });
            score = resp.output.nsfw_score;
            console.log(score);
            
            // if image contains less than 15% nudity, then only save it
            if (score < 0.15) {
                const savedImage = await image.save();
                return savedImage;
            }
            else {
                //res.json({ "imageRejected": true });
            }
        }
        else {
            const savedImage = await image.save();
            return savedImage;
        }

    } catch (err) {
        return { message: err };
    }
}

module.exports = mongoose.model('Image', ImageSchema);