const express = require('express');
const path = require('path');
const fs = require('fs');
const { auth, requireRole } = require('../middleware/auth');

const router = express.Router();

// @route   POST /api/file/upload
// @desc    Upload file for application (using global multer middleware)
// @access  Private (Talent only)
router.post('/upload', [auth, requireRole(['talent'])], async (req, res) => {
	try {
		// Check if file was uploaded by global multer middleware
		if (!req.files || req.files.length === 0) {
			return res.status(400).json({
				success: false,
				message: 'No file uploaded',
			});
		}

		const uploadedFile = req.files[0]; // Get first uploaded file

		// Validate file size (10MB limit)
		if (uploadedFile.size > 10 * 1024 * 1024) {
			return res.status(400).json({
				success: false,
				message: 'File size too large. Maximum size is 10MB',
			});
		}

		// Validate file type
		const allowedTypes = [
			'.pdf',
			'.doc',
			'.docx',
			'.txt',
			'.rtf',
			'.odt',
			'.jpg',
			'.jpeg',
			'.png',
			'.gif',
			'.wpd',
		];

		const ext = path.extname(uploadedFile.originalname).toLowerCase();
		if (!allowedTypes.includes(ext)) {
			return res.status(400).json({
				success: false,
				message: 'File type not supported',
			});
		}

		const fileInfo = {
			fileName: uploadedFile.filename,
			originalName: uploadedFile.originalname,
			size: uploadedFile.size,
			type: uploadedFile.mimetype,
			url: `/uploads/applications/${uploadedFile.filename}`,
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
});

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
