const express = require('express');
const router = express.Router();
const { google } = require('googleapis');

const auth = new google.auth.GoogleAuth({
    credentials: {
        client_email: process.env.GOOGLE_CLIENT_EMAIL,
        private_key: process.env.GOOGLE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    },
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
});

router.post('/analytics', async (req, res) => {
    try {
        const analyticsData = await google.analytics('v3').data.ga.get({
            auth: auth,
            ids: 'ga:' + process.env.GOOGLE_ANALYTICS_VIEW_ID,
            'start-date': '30daysAgo',
            'end-date': 'today',
            metrics: 'ga:sessions'
        });
        res.json(analyticsData.data);
    } catch (error) {
        console.error('Google Analytics Error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router; 