const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Import API handlers
const openaiRoutes = require('./routes/openai');
const waveRoutes = require('./routes/wave');
const wixRoutes = require('./routes/wix');
const cloudinaryRoutes = require('./routes/cloudinary');
const postmarkCFRoutes = require('./routes/postmark/cochranfilms');
const postmarkCCARoutes = require('./routes/postmark/cca');
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

// Add logging middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    if (req.body) console.log('Request body:', JSON.stringify(req.body, null, 2));
    next();
});

// Routes
app.use('/api/chat', openaiRoutes);
app.use('/api/wave', waveRoutes);
app.use('/api/wix', wixRoutes);
app.use('/api/cloudinary', cloudinaryRoutes);
app.use('/api/postmark/cf', postmarkCFRoutes);
app.use('/api/postmark/cca', postmarkCCARoutes);
app.use('/api/google', googleRoutes);

// Test route with detailed response
app.get('/api/test', (req, res) => {
    console.log('Test endpoint hit');
    res.json({ 
        message: 'Server is running!',
        environment: process.env.NODE_ENV,
        apis: {
            openai: !!process.env.OPENAI_API_KEY,
            wave: !!process.env.WAVE_API_KEY,
            wix: !!process.env.WIX_API_KEY,
            cloudinary: !!process.env.CLOUDINARY_API_KEY,
            postmarkCF: !!process.env.POSTMARK_SERVER_TOKEN_CF,
            postmarkCCA: !!process.env.POSTMARK_SERVER_TOKEN_CCA
        }
    });
});

// Enhanced error handling
app.use((err, req, res, next) => {
    console.error('Error details:', {
        message: err.message,
        stack: err.stack,
        path: req.path,
        method: req.method,
        body: req.body
    });
    res.status(500).json({ 
        error: 'Something went wrong!',
        message: err.message,
        path: req.path
    });
});

// Add this after your require statements
console.log('Environment Variables Status:', {
    OPENAI_API: process.env.OPENAI_API_KEY ? '✅' : '❌',
    WAVE_API: process.env.WAVE_API_KEY ? '✅' : '❌',
    WIX_API: process.env.WIX_API_KEY ? '✅' : '❌',
    CLOUDINARY_API: process.env.CLOUDINARY_API_KEY ? '✅' : '❌',
    CLOUDINARY_SECRET: process.env.CLOUDINARY_SECRET ? '✅' : '❌',
    POSTMARK_CF: process.env.POSTMARK_SERVER_TOKEN_CF ? '✅' : '❌',
    POSTMARK_CCA: process.env.POSTMARK_SERVER_TOKEN_CCA ? '✅' : '❌',
    GOOGLE_CLOUD: process.env.GOOGLE_CLOUD_API_KEY ? '✅' : '❌',
    AUTH0: process.env.AUTH0_API_KEY ? '✅' : '❌'
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
}); 