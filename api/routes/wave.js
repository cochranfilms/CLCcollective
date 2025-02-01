const express = require('express');
const router = express.Router();
const axios = require('axios');

const waveApi = axios.create({
    baseURL: 'https://gql.waveapps.com/graphql/public',
    headers: {
        'Authorization': `Bearer ${process.env.WAVE_API_KEY}`,
        'Content-Type': 'application/json'
    }
});

router.post('/invoice', async (req, res) => {
    try {
        const { clientName, amount, description } = req.body;
        // Wave API implementation
        const response = await waveApi.post('', {
            // Wave GraphQL query
        });
        res.json(response.data);
    } catch (error) {
        console.error('Wave Error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router; 