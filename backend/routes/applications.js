const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, requireRole } = require('../middleware/auth');
const Application = require('../models/Application');
const Job = require('../models/Job');
const Talent = require('../models/Talent');
const Company = require('../models/Company');

const router = express.Router();

// @route   POST /api/applications/jobs/:jobId/apply
// @desc    Apply for a job (Talent only)
// @access  Private (Talent only)
router.post(
	'/jobs/:jobId/apply',
	[
		auth,
		requireRole(['talent']),
		body('coverLetter')
			.optional()
			.isLength({ max: 1000 })
			.withMessage('Cover letter maksimal 1000 karakter'),
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

			const { jobId } = req.params;
			const { coverLetter, resumeUrl } = req.body;

			// Check if job exists and is active
			const job = await Job.findOne({ _id: jobId, isActive: true }).populate(
				'companyId'
			);

			if (!job) {
				return res.status(404).json({
					success: false,
					message: 'Lowongan pekerjaan tidak ditemukan atau sudah tidak aktif',
				});
			}

			// Check if application deadline has passed
			if (job.applicationDeadline && new Date() > job.applicationDeadline) {
				return res.status(400).json({
					success: false,
					message: 'Batas waktu lamaran sudah lewat',
				});
			}

			// Get talent profile
			const talent = await Talent.findOne({ userId: req.user._id });
			if (!talent) {
				return res.status(404).json({
					success: false,
					message: 'Profil talent tidak ditemukan',
				});
			}

			// Check if already applied
			const existingApplication = await Application.findOne({
				talentId: talent._id,
				jobId: jobId,
			});

			if (existingApplication) {
				return res.status(400).json({
					success: false,
					message: 'Anda sudah melamar pekerjaan ini',
				});
			}

			// Create application
			const application = new Application({
				talentId: talent._id,
				jobId: jobId,
				companyId: job.companyId._id,
				coverLetter: coverLetter || '',
				resumeUrl: resumeUrl || talent.resumeUrl,
			});

			await application.save();

			// Increment application count for job
			job.applicationCount += 1;
			await job.save();

			// Populate application data
			await application.populate([
				{ path: 'talentId', select: 'name skills experience' },
				{
					path: 'jobId',
					select: 'title companyId',
					populate: { path: 'companyId', select: 'companyName' },
				},
			]);

			res.status(201).json({
				success: true,
				message: 'Lamaran berhasil dikirim',
				data: { application },
			});
		} catch (error) {
			console.error('Apply job error:', error);
			res.status(500).json({
				success: false,
				message: 'Terjadi kesalahan pada server',
			});
		}
	}
);

// @route   GET /api/applications/me
// @desc    Get current user's applications (Talent only)
// @access  Private (Talent only)
router.get('/me', [auth, requireRole(['talent'])], async (req, res) => {
	try {
		const talent = await Talent.findOne({ userId: req.user._id });
		if (!talent) {
			return res.status(404).json({
				success: false,
				message: 'Profil talent tidak ditemukan',
			});
		}

		const page = parseInt(req.query.page) || 1;
		const limit = parseInt(req.query.limit) || 10;
		const skip = (page - 1) * limit;

		// Filter by status if provided
		const filter = { talentId: talent._id };
		if (req.query.status) {
			filter.status = req.query.status;
		}

		const applications = await Application.find(filter)
			.populate([
				{
					path: 'jobId',
					select:
						'title location salary jobType experienceLevel applicationDeadline',
					populate: { path: 'companyId', select: 'companyName logo' },
				},
			])
			.sort({ appliedAt: -1 })
			.skip(skip)
			.limit(limit);

		const total = await Application.countDocuments(filter);

		// Get application statistics
		const stats = await Application.aggregate([
			{ $match: { talentId: talent._id } },
			{
				$group: {
					_id: '$status',
					count: { $sum: 1 },
				},
			},
		]);

		const statusStats = {
			pending: 0,
			reviewed: 0,
			interview: 0,
			hired: 0,
			rejected: 0,
		};

		stats.forEach((stat) => {
			statusStats[stat._id] = stat.count;
		});

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
				statistics: statusStats,
			},
		});
	} catch (error) {
		console.error('Get applications error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   GET /api/applications/company
// @desc    Get applications for company (Company only)
// @access  Private (Company only)
router.get('/company', [auth, requireRole(['company'])], async (req, res) => {
	try {
		const company = await Company.findOne({ userId: req.user._id });
		if (!company) {
			return res.status(404).json({
				success: false,
				message: 'Profil perusahaan tidak ditemukan',
			});
		}

		const page = parseInt(req.query.page) || 1;
		const limit = parseInt(req.query.limit) || 10;
		const skip = (page - 1) * limit;

		// Filter by status if provided
		const filter = { companyId: company._id };
		if (req.query.status) {
			filter.status = req.query.status;
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

		// Get application statistics
		const stats = await Application.aggregate([
			{ $match: { companyId: company._id } },
			{
				$group: {
					_id: '$status',
					count: { $sum: 1 },
				},
			},
		]);

		const statusStats = {
			pending: 0,
			reviewed: 0,
			interview: 0,
			hired: 0,
			rejected: 0,
		};

		stats.forEach((stat) => {
			if (statusStats.hasOwnProperty(stat._id)) {
				statusStats[stat._id] = stat.count;
			}
		});

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
				statistics: statusStats,
			},
		});
	} catch (error) {
		console.error('Get company applications error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   GET /api/applications/:id
// @desc    Get application details
// @access  Private
router.get('/:id', auth, async (req, res) => {
	try {
		const application = await Application.findById(req.params.id).populate([
			{
				path: 'talentId',
				select: 'name skills experience portfolio resumeUrl',
				populate: { path: 'userId', select: 'email' },
			},
			{
				path: 'jobId',
				select: 'title description requirements location salary',
				populate: { path: 'companyId', select: 'companyName logo' },
			},
		]);

		if (!application) {
			return res.status(404).json({
				success: false,
				message: 'Lamaran tidak ditemukan',
			});
		}

		// Check access permissions
		const talent = await Talent.findOne({ userId: req.user._id });
		const company = await Company.findOne({ userId: req.user._id });

		const hasAccess =
			(talent &&
				application.talentId._id.toString() === talent._id.toString()) ||
			(company && application.companyId.toString() === company._id.toString());

		if (!hasAccess) {
			return res.status(403).json({
				success: false,
				message: 'Akses ditolak',
			});
		}

		res.json({
			success: true,
			data: { application },
		});
	} catch (error) {
		console.error('Get application error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   PUT /api/applications/:id/status
// @desc    Update application status (Company only)
// @access  Private (Company only)
router.put(
	'/:id/status',
	[
		auth,
		requireRole(['company']),
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

			const company = await Company.findOne({ userId: req.user._id });
			if (!company) {
				return res.status(404).json({
					success: false,
					message: 'Profil perusahaan tidak ditemukan',
				});
			}

			const application = await Application.findOne({
				_id: req.params.id,
				companyId: company._id,
			});

			if (!application) {
				return res.status(404).json({
					success: false,
					message: 'Lamaran tidak ditemukan atau tidak memiliki akses',
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
			console.error('Update application status error:', error);
			res.status(500).json({
				success: false,
				message: 'Terjadi kesalahan pada server',
			});
		}
	}
);

// @route   DELETE /api/applications/:id
// @desc    Withdraw application (Talent only)
// @access  Private (Talent only)
router.delete('/:id', [auth, requireRole(['talent'])], async (req, res) => {
	try {
		const talent = await Talent.findOne({ userId: req.user._id });
		if (!talent) {
			return res.status(404).json({
				success: false,
				message: 'Profil talent tidak ditemukan',
			});
		}

		const application = await Application.findOne({
			_id: req.params.id,
			talentId: talent._id,
		});

		if (!application) {
			return res.status(404).json({
				success: false,
				message: 'Lamaran tidak ditemukan',
			});
		}

		// Only allow withdrawal if status is pending or reviewed
		if (!['pending', 'reviewed'].includes(application.status)) {
			return res.status(400).json({
				success: false,
				message: 'Tidak dapat menarik lamaran dengan status ini',
			});
		}

		await Application.findByIdAndDelete(application._id);

		// Decrement application count for job
		const job = await Job.findById(application.jobId);
		if (job && job.applicationCount > 0) {
			job.applicationCount -= 1;
			await job.save();
		}

		res.json({
			success: true,
			message: 'Lamaran berhasil ditarik',
		});
	} catch (error) {
		console.error('Withdraw application error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

module.exports = router;
