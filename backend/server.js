const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Import API handlers
const openaiRoutes = require('./routes/openai');
const waveRoutes = require('./routes/wave');
const wixRoutes = require('./routes/wix');
const cloudinaryRoutes = require('./routes/cloudinary');
const postmarkRoutes = require('./routes/postmark');
const googleRoutes = require('./routes/google');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Rate limiting middleware
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Routes
app.use('/api/chat', openaiRoutes);
app.use('/api/wave', waveRoutes);
app.use('/api/wix', wixRoutes);
app.use('/api/cloudinary', cloudinaryRoutes);
app.use('/api/postmark', postmarkRoutes);
app.use('/api/google', googleRoutes);

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
}); 