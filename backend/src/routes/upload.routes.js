const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { protect } = require('../middlewares/authMiddleware');
const supabase = require('../config/supabaseClient');
const logger = require('../services/logger');

// Ensure local uploads directory exists as fallback
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Memory storage to handle file buffer before uploading to Supabase Storage
const upload = multer({
    storage: multer.memoryStorage(),
    fileFilter: (req, file, cb) => {
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Only images are allowed'), false);
        }
    },
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// @desc    Upload an image (Supabase Storage with local disk fallback)
// @route   POST /api/upload
// @access  Private
router.post('/', protect, upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        const sanitizedName = req.file.originalname.replace(/[^a-zA-Z0-9.-]/g, '_');
        const fileName = `${Date.now()}-${Math.round(Math.random() * 1e9)}-${sanitizedName}`;

        // 1. Try Supabase Storage (Global CDN)
        if (supabase) {
            try {
                const bucketName = 'turf-media';
                const { data, error } = await supabase.storage
                    .from(bucketName)
                    .upload(fileName, req.file.buffer, {
                        contentType: req.file.mimetype,
                        upsert: true
                    });

                if (!error && data) {
                    const { data: publicUrlData } = supabase.storage
                        .from(bucketName)
                        .getPublicUrl(fileName);

                    logger.info(`File uploaded to Supabase Storage: ${publicUrlData.publicUrl}`);
                    return res.status(200).json({
                        message: 'Image uploaded successfully to cloud storage',
                        url: publicUrlData.publicUrl
                    });
                } else if (error) {
                    logger.warn('Supabase storage upload failed, falling back to disk:', { error: error.message });
                }
            } catch (storageErr) {
                logger.warn('Error in Supabase storage, using fallback:', { error: storageErr.message });
            }
        }

        // 2. Fallback to local disk storage
        const diskPath = path.join(uploadDir, fileName);
        fs.writeFileSync(diskPath, req.file.buffer);

        const localUrl = `/uploads/${fileName}`;
        logger.info(`File saved locally: ${localUrl}`);

        return res.status(200).json({
            message: 'Image uploaded successfully',
            url: localUrl
        });
    } catch (err) {
        logger.error('Upload error', { error: err.message });
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
