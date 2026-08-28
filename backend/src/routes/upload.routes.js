const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { protect } = require('../middlewares/authMiddleware');

// Configure storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        cb(null, `${Date.now()}-${file.originalname}`);
    }
});

// File filter
const fileFilter = (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
        cb(null, true);
    } else {
        cb(new Error('Only images are allowed'), false);
    }
};

const upload = multer({
    storage,
    fileFilter,
    limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
});

// @desc    Upload an image
// @route   POST /api/upload
// @access  Private
router.post('/', protect, (req, res, next) => {
    console.log('Upload request received');
    next();
}, upload.single('image'), (req, res) => {
    console.log('File processing complete');
    if (!req.file) {
        console.log('No file in request');
        return res.status(400).json({ message: 'No file uploaded' });
    }

    console.log('File uploaded:', req.file.filename);
    const filePath = `/uploads/${req.file.filename}`;
    res.status(200).json({
        message: 'Image uploaded successfully',
        url: filePath
    });
});

module.exports = router;
