const express = require('express');
const router = express.Router();
const cochranfilmsRoutes = require('./cochranfilms');
const ccaRoutes = require('./cca');

router.use('/cf', cochranfilmsRoutes);
router.use('/cca', ccaRoutes);

module.exports = router; 