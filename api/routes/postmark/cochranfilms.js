const express = require('express');
const router = express.Router();
const postmark = require('postmark');

const client = new postmark.ServerClient(process.env.POSTMARK_SERVER_TOKEN_CF);

router.post('/send', async (req, res) => {
    try {
        const { to, subject, body } = req.body;
        const response = await client.sendEmail({
            "From": "contact@cochranfilms.com",
            "To": to,
            "Subject": subject,
            "HtmlBody": body,
            "TextBody": body,
            "MessageStream": "outbound"
        });
        res.json(response);
    } catch (error) {
        console.error('Postmark CF Error:', error);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router; 