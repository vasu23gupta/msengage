const express = require('express');
const router = express.Router();
const Image = require('../models/Image');
const upload = require('../shared/multer_configuration');

/**
 * get an image by id
 * request:
 *   parameters: 
 *     imageId: image id
 * response:
 *   image
 */
router.get('/:imageId', async (req, res) => {
    //https://stackoverflow.com/questions/28440369/rendering-a-base64-png-with-express
    try {
        var imageBase64 = await Image.findById(req.params.imageId);
        imageBase64 = imageBase64['img']['data'];
        const image = Buffer.from(imageBase64, 'base64');
        res.writeHead(200, {
            'Content-Type': 'image',
            'Content-Length': image.length
        });
        res.end(image);
    } catch (err) {
        res.json({ message: err });
    }
});

/**
 * upload an image
 * request:
 *   form data: {
 *       image: image
 *   }
 *   body: {
 *       filter: {boolean} whether to censor this image or not
 *   }
 * response:
 *   json: {
 *     _id: id of saved image
 *   }
 */
router.post('/', upload.single('image'), async function (req, res) {
    try {
        var filter = req.body.filter === 'true';
        var f = req.file;
        var savedImage = await Image.uploadImage(f, filter);
        res.json(savedImage._id);
    } catch (err) {
        res.status(err.status || 500).json({ message: err });
    }
});

module.exports = router;