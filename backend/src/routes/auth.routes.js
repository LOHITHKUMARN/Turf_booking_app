const express = require('express');
const { signup, login, updateFCMToken, refreshToken } = require('../controllers/authController');
const { validate, registerSchema, loginSchema } = require('../middlewares/validation');
const { protect } = require('../middlewares/authMiddleware');
const router = express.Router();

router.post('/signup', validate(registerSchema), signup);
router.post('/login', validate(loginSchema), login);
router.post('/refresh', refreshToken);
router.post('/fcm-token', protect, updateFCMToken);

module.exports = router;
