const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, requireRole, requireAdmin } = require('../middleware/auth');
const Job = require('../models/Job');
const Company = require('../models/Company');
const Application = require('../models/Application');
const User = require('../models/User');

const router = express.Router();

// @route   GET /api/admin/jobs
// @desc    Get all jobs (Admin only)
// @access  Private (Admin only)
router.get('/jobs', [auth, requireAdmin], async (req, res) => {
	try {
		const page = parseInt(req.query.page) || 1;
		const limit = parseInt(req.query.limit) || 50;
		const skip = (page - 1) * limit;

		// Build filter object
		const filter = {};
		if (req.query.search) {
			filter.$text = { $search: req.query.search };
		}
		if (req.query.location) {
			filter.location = { $regex: req.query.location, $options: 'i' };
		}
		if (req.query.jobType) {
			filter.jobType = req.query.jobType;
		}
		if (req.query.experienceLevel) {
			filter.experienceLevel = req.query.experienceLevel;
		}
		if (req.query.category && req.query.category !== 'all') {
			filter.category = req.query.category;
		}
		if (req.query.companyId) {
			filter.companyId = req.query.companyId;
		}

		// Sort options
		let sort = { createdAt: -1 };
		if (req.query.sort === 'salary') {
			sort = { 'salary.amount': -1 };
		} else if (req.query.sort === 'recent') {
			sort = { createdAt: -1 };
		}

		const jobs = await Job.find(filter)
			.populate('companyId', 'companyName logo industry')
			.sort(sort)
			.skip(skip)
			.limit(limit);

		const total = await Job.countDocuments(filter);

		res.json({
			success: true,
			data: {
				jobs,
				pagination: {
					currentPage: page,
					totalPages: Math.ceil(total / limit),
					totalJobs: total,
					hasNext: page < Math.ceil(total / limit),
					hasPrev: page > 1,
				},
			},
		});
	} catch (error) {
		console.error('Get admin jobs error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   PUT /api/admin/jobs/:id
// @desc    Update any job (Admin only)
// @access  Private (Admin only)
router.put('/:id', [auth, requireAdmin], async (req, res) => {
	try {
		const job = await Job.findById(req.params.id);
		if (!job) {
			return res.status(404).json({
				success: false,
				message: 'Lowongan pekerjaan tidak ditemukan',
			});
		}

		// Update allowed fields
		const allowedFields = [
			'title',
			'description',
			'requirements',
			'responsibilities',
			'salary',
			'location',
			'jobType',
			'experienceLevel',
			'skills',
			'benefits',
			'applicationDeadline',
			'isActive',
			'category',
		];

		allowedFields.forEach((field) => {
			if (req.body[field] !== undefined) {
				job[field] = req.body[field];
			}
		});

		await job.save();
		await job.populate('companyId', 'companyName logo industry');

		res.json({
			success: true,
			message: 'Lowongan pekerjaan berhasil diperbarui',
			data: { job },
		});
	} catch (error) {
		console.error('Admin update job error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   DELETE /api/admin/jobs/:id
// @desc    Delete any job (Admin only)
// @access  Private (Admin only)
router.delete('/jobs/:id', [auth, requireAdmin], async (req, res) => {
	try {
		const job = await Job.findById(req.params.id);
		if (!job) {
			return res.status(404).json({
				success: false,
				message: 'Lowongan pekerjaan tidak ditemukan',
			});
		}

		await Job.findByIdAndDelete(job._id);

		res.json({
			success: true,
			message: 'Lowongan pekerjaan berhasil dihapus',
		});
	} catch (error) {
		console.error('Admin delete job error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   PATCH /api/admin/jobs/:id/activate
// @desc    Activate job (Admin only)
// @access  Private (Admin only)
router.patch('/jobs/:id/activate', [auth, requireAdmin], async (req, res) => {
	try {
		const job = await Job.findById(req.params.id);
		if (!job) {
			return res.status(404).json({
				success: false,
				message: 'Lowongan pekerjaan tidak ditemukan',
			});
		}

		job.isActive = true;
		await job.save();

		res.json({
			success: true,
			message: 'Lowongan pekerjaan berhasil diaktifkan',
		});
	} catch (error) {
		console.error('Admin activate job error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   PATCH /api/admin/jobs/:id/deactivate
// @desc    Deactivate job (Admin only)
// @access  Private (Admin only)
router.patch('/jobs/:id/deactivate', [auth, requireAdmin], async (req, res) => {
	try {
		const job = await Job.findById(req.params.id);
		if (!job) {
			return res.status(404).json({
				success: false,
				message: 'Lowongan pekerjaan tidak ditemukan',
			});
		}

		job.isActive = false;
		await job.save();

		res.json({
			success: true,
			message: 'Lowongan pekerjaan berhasil dinonaktifkan',
		});
	} catch (error) {
		console.error('Admin deactivate job error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   GET /api/admin/applications
// @desc    Get all applications (Admin only)
// @access  Private (Admin only)
router.get('/applications', [auth, requireAdmin], async (req, res) => {
	try {
		const page = parseInt(req.query.page) || 1;
		const limit = parseInt(req.query.limit) || 50;
		const skip = (page - 1) * limit;

		// Build filter object
		const filter = {};
		if (req.query.status) {
			filter.status = req.query.status;
		}
		if (req.query.jobId) {
			filter.jobId = req.query.jobId;
		}
		if (req.query.companyId) {
			filter.companyId = req.query.companyId;
		}

		const applications = await Application.find(filter)
			.populate([
				{
					path: 'talentId',
					select: 'name skills experience',
					populate: { path: 'userId', select: 'email' },
				},
				{
					path: 'jobId',
					select: 'title location salary jobType experienceLevel',
					populate: { path: 'companyId', select: 'companyName' },
				},
			])
			.sort({ appliedAt: -1 })
			.skip(skip)
			.limit(limit);

		const total = await Application.countDocuments(filter);

		res.json({
			success: true,
			data: {
				applications,
				pagination: {
					currentPage: page,
					totalPages: Math.ceil(total / limit),
					totalApplications: total,
					hasNext: page < Math.ceil(total / limit),
					hasPrev: page > 1,
				},
			},
		});
	} catch (error) {
		console.error('Get admin applications error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   PUT /api/admin/applications/:id/status
// @desc    Update application status (Admin only)
// @access  Private (Admin only)
router.put(
	'/applications/:id/status',
	[
		auth,
		requireAdmin,
		body('status')
			.isIn(['pending', 'reviewed', 'interview', 'hired', 'rejected'])
			.withMessage('Status tidak valid'),
		body('notes')
			.optional()
			.isLength({ max: 500 })
			.withMessage('Notes maksimal 500 karakter'),
		body('feedback')
			.optional()
			.isLength({ max: 1000 })
			.withMessage('Feedback maksimal 1000 karakter'),
	],
	async (req, res) => {
		try {
			const errors = validationResult(req);
			if (!errors.isEmpty()) {
				return res.status(400).json({
					success: false,
					message: 'Data tidak valid',
					errors: errors.array(),
				});
			}

			const application = await Application.findById(req.params.id);
			if (!application) {
				return res.status(404).json({
					success: false,
					message: 'Lamaran tidak ditemukan',
				});
			}

			const { status, notes, feedback, interviewScheduledAt } = req.body;

			// Update application
			application.status = status;
			if (notes) application.notes = notes;
			if (feedback) application.feedback = feedback;
			if (interviewScheduledAt)
				application.interviewScheduledAt = interviewScheduledAt;

			// Set reviewed date if status changes from pending
			if (application.status === 'pending' && status !== 'pending') {
				application.reviewedAt = new Date();
			}

			await application.save();

			// Populate for response
			await application.populate([
				{
					path: 'talentId',
					select: 'name skills experience',
					populate: { path: 'userId', select: 'email' },
				},
				{
					path: 'jobId',
					select: 'title',
					populate: { path: 'companyId', select: 'companyName' },
				},
			]);

			res.json({
				success: true,
				message: 'Status lamaran berhasil diperbarui',
				data: { application },
			});
		} catch (error) {
			console.error('Admin update application status error:', error);
			res.status(500).json({
				success: false,
				message: 'Terjadi kesalahan pada server',
			});
		}
	}
);

// @route   GET /api/admin/users
// @desc    Get all users (Admin only)
// @access  Private (Admin only)
router.get('/users', [auth, requireAdmin], async (req, res) => {
	try {
		const page = parseInt(req.query.page) || 1;
		const limit = parseInt(req.query.limit) || 50;
		const skip = (page - 1) * limit;

		// Build filter object
		const filter = {};
		if (req.query.role) {
			filter.role = req.query.role;
		}
		if (req.query.isActive !== undefined) {
			filter.isActive = req.query.isActive === 'true';
		}

		const users = await User.find(filter)
			.select('-password')
			.sort({ createdAt: -1 })
			.skip(skip)
			.limit(limit);

		const total = await User.countDocuments(filter);

		res.json({
			success: true,
			data: {
				users,
				pagination: {
					currentPage: page,
					totalPages: Math.ceil(total / limit),
					totalUsers: total,
					hasNext: page < Math.ceil(total / limit),
					hasPrev: page > 1,
				},
			},
		});
	} catch (error) {
		console.error('Get admin users error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

module.exports = router;
