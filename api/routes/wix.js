const express = require('express');
const router = express.Router();
const axios = require('axios');

const wixApi = axios.create({
    baseURL: 'https://www.wixapis.com/v1',
    headers: {
        'Authorization': process.env.WIX_API_KEY,
        'Content-Type': 'application/json'
    }
});

router.get('/portfolio', async (req, res) => {
    try {
        const response = await wixApi.get('/portfolio/items');
        res.json(response.data);
    } catch (error) {
        console.error('Wix Error:', error);
        res.status(500).json({ error: error.message });
    }
});

router.post('/contact', async (req, res) => {
    try {
        const { name, email, message } = req.body;
        const response = await wixApi.post('/contact/submissions', {
            name,
            email,
            message
        });
        res.json(response.data);
    } catch (error) {
        console.error('Wix Contact Error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router; 