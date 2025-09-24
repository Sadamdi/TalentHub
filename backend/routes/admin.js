const express = require('express');
const { auth, requireRole } = require('../middleware/auth');
const ApplicationCleanup = require('../utils/cleanup');
const Scheduler = require('../scheduler');

const router = express.Router();

// @route   POST /api/admin/cleanup/applications
// @desc    Manual cleanup of old applications
// @access  Private (Admin only)
router.post(
	'/cleanup/applications',
	[auth, requireRole(['admin'])],
	async (req, res) => {
		try {
			console.log('🔧 Admin requested manual application cleanup...');

			const result = await ApplicationCleanup.cleanupApplications();

			res.json({
				success: true,
				message: 'Application cleanup completed',
				data: result,
			});
		} catch (error) {
			console.error('Admin cleanup error:', error);
			res.status(500).json({
				success: false,
				message: 'Cleanup failed',
				error: error.message,
			});
		}
	}
);

// @route   GET /api/admin/cleanup/preview
// @desc    Preview applications that would be deleted
// @access  Private (Admin only)
router.get(
	'/cleanup/preview',
	[auth, requireRole(['admin'])],
	async (req, res) => {
		try {
			console.log('👁️ Admin requested cleanup preview...');

			const applications = await ApplicationCleanup.previewCleanup();

			res.json({
				success: true,
				message: 'Cleanup preview completed',
				data: {
					applicationsToDelete: applications,
					count: applications.length,
				},
			});
		} catch (error) {
			console.error('Admin cleanup preview error:', error);
			res.status(500).json({
				success: false,
				message: 'Preview failed',
				error: error.message,
			});
		}
	}
);

// @route   POST /api/admin/cleanup/run-now
// @desc    Run cleanup immediately (for testing)
// @access  Private (Admin only)
router.post(
	'/cleanup/run-now',
	[auth, requireRole(['admin'])],
	async (req, res) => {
		try {
			console.log('🚀 Admin requested immediate cleanup...');

			const result = await Scheduler.runCleanupNow();

			res.json({
				success: true,
				message: 'Immediate cleanup completed',
				data: result,
			});
		} catch (error) {
			console.error('Admin immediate cleanup error:', error);
			res.status(500).json({
				success: false,
				message: 'Immediate cleanup failed',
				error: error.message,
			});
		}
	}
);

// @route   GET /api/admin/cleanup/status
// @desc    Get cleanup system status
// @access  Private (Admin only)
router.get(
	'/cleanup/status',
	[auth, requireRole(['admin'])],
	async (req, res) => {
		try {
			const Application = require('../models/Application');

			// Get statistics
			const totalApplications = await Application.countDocuments();
			const pendingApplications = await Application.countDocuments({
				status: { $in: ['pending', 'interview'] },
			});
			const reviewedApplications = await Application.countDocuments({
				status: { $in: ['hired', 'rejected'] },
			});

			// Get applications older than thresholds
			const now = new Date();
			const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
			const twoDaysAgo = new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000);

			const oldReviewedCount = await Application.countDocuments({
				status: { $in: ['hired', 'rejected'] },
				reviewedAt: { $lte: oneDayAgo },
			});

			const oldPendingCount = await Application.countDocuments({
				status: { $in: ['pending', 'interview'] },
				createdAt: { $lte: twoDaysAgo },
			});

			res.json({
				success: true,
				data: {
					statistics: {
						totalApplications,
						pendingApplications,
						reviewedApplications,
						oldReviewedCount,
						oldPendingCount,
						totalToCleanup: oldReviewedCount + oldPendingCount,
					},
					cleanupRules: {
						reviewedApplications: '1 day after review',
						pendingApplications: '2 days after creation',
					},
					schedulerStatus: 'Active (runs every 6 hours and daily at 2 AM)',
					timezone: 'Asia/Jakarta',
				},
			});
		} catch (error) {
			console.error('Admin cleanup status error:', error);
			res.status(500).json({
				success: false,
				message: 'Failed to get cleanup status',
				error: error.message,
			});
		}
	}
);

module.exports = router;
