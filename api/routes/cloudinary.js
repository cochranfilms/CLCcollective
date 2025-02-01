const express = require('express');
const router = express.Router();
const cloudinary = require('cloudinary').v2;

cloudinary.config({
    cloud_name: 'your_cloud_name',
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_SECRET
});

router.post('/upload', async (req, res) => {
    try {
        const { file } = req.body;
        const result = await cloudinary.uploader.upload(file);
        res.json(result);
    } catch (error) {
        console.error('Cloudinary Error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router; 