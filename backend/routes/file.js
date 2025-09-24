const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { auth, requireRole } = require('../middleware/auth');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
	destination: function (req, file, cb) {
		const uploadDir = path.join(__dirname, '..', 'uploads', 'applications');

		// Create directory if it doesn't exist
		if (!fs.existsSync(uploadDir)) {
			fs.mkdirSync(uploadDir, { recursive: true });
		}

		cb(null, uploadDir);
	},
	filename: function (req, file, cb) {
		// Generate unique filename with timestamp
		const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
		const ext = path.extname(file.originalname);
		const basename = path.basename(file.originalname, ext);

		cb(null, `${basename}-${uniqueSuffix}${ext}`);
	},
});

const upload = multer({
	storage: storage,
	limits: {
		fileSize: 10 * 1024 * 1024, // 10MB limit
	},
	fileFilter: function (req, file, cb) {
		// Allow all file types for CV
		const allowedTypes = [
			// Documents
			'.pdf',
			'.doc',
			'.docx',
			'.txt',
			'.rtf',
			'.odt',
			// Images
			'.jpg',
			'.jpeg',
			'.png',
			'.gif',
			// Others
			'.wpd',
		];

		const ext = path.extname(file.originalname).toLowerCase();

		if (allowedTypes.includes(ext)) {
			cb(null, true);
		} else {
			cb(new Error('File type not supported'), false);
		}
	},
});

// @route   POST /api/file/upload
// @desc    Upload file for application
// @access  Private (Talent only)
router.post(
	'/upload',
	[auth, requireRole(['talent'])],
	upload.single('cv'),
	async (req, res) => {
		try {
			if (!req.file) {
				return res.status(400).json({
					success: false,
					message: 'No file uploaded',
				});
			}

			const fileInfo = {
				fileName: req.file.filename,
				originalName: req.file.originalname,
				size: req.file.size,
				type: req.file.mimetype,
				url: `/uploads/applications/${req.file.filename}`,
				uploadedAt: new Date(),
			};

			res.json({
				success: true,
				message: 'File uploaded successfully',
				data: fileInfo,
			});
		} catch (error) {
			console.error('File upload error:', error);
			res.status(500).json({
				success: false,
				message: 'File upload failed',
			});
		}
	}
);

// @route   GET /api/file/:filename
// @desc    Get uploaded file
// @access  Private
router.get('/:filename', auth, async (req, res) => {
	try {
		const filename = req.params.filename;
		const filePath = path.join(
			__dirname,
			'..',
			'uploads',
			'applications',
			filename
		);

		if (!fs.existsSync(filePath)) {
			return res.status(404).json({
				success: false,
				message: 'File not found',
			});
		}

		// Check if user has permission to access this file
		// For now, allow access if authenticated
		res.sendFile(filePath);
	} catch (error) {
		console.error('Get file error:', error);
		res.status(500).json({
			success: false,
			message: 'Error accessing file',
		});
	}
});

// @route   DELETE /api/file/:filename
// @desc    Delete uploaded file
// @access  Private (Talent or Company or Admin)
router.delete('/:filename', auth, async (req, res) => {
	try {
		const filename = req.params.filename;
		const filePath = path.join(
			__dirname,
			'..',
			'uploads',
			'applications',
			filename
		);

		if (!fs.existsSync(filePath)) {
			return res.status(404).json({
				success: false,
				message: 'File not found',
			});
		}

		// Check permissions (for now allow if authenticated)
		fs.unlinkSync(filePath);

		res.json({
			success: true,
			message: 'File deleted successfully',
		});
	} catch (error) {
		console.error('Delete file error:', error);
		res.status(500).json({
			success: false,
			message: 'Error deleting file',
		});
	}
});

module.exports = router;
