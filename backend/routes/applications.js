const express = require('express');
const { body, validationResult } = require('express-validator');
const {
	auth,
	requireRole,
	requireCompanyOrAdmin,
} = require('../middleware/auth');
const Application = require('../models/Application');
const Job = require('../models/Job');
const Talent = require('../models/Talent');
const Company = require('../models/Company');
const Chat = require('../models/Chat');
const User = require('../models/User');
const fs = require('fs');
const path = require('path');

const router = express.Router();

// @route   POST /api/applications
// @desc    Apply for a job (Talent only) - Complete application with all data
// @access  Private (Talent only)
router.post(
	'/',
	[
		auth,
		requireRole(['talent']),
		body('jobId').notEmpty().withMessage('Job ID diperlukan'),
		body('fullName').notEmpty().withMessage('Nama lengkap diperlukan'),
		body('email').isEmail().withMessage('Email tidak valid'),
		body('phone').notEmpty().withMessage('Nomor telepon diperlukan'),
		body('coverLetter')
			.optional()
			.isLength({ max: 1000 })
			.withMessage('Cover letter maksimal 1000 karakter'),
		body('experienceYears')
			.optional()
			.isLength({ min: 0, max: 50 })
			.withMessage('Tahun pengalaman maksimal 50 karakter'),
		body('skills')
			.optional()
			.isArray({ min: 0, max: 20 })
			.withMessage('Skills harus berupa array dengan maksimal 20 item'),
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

			const {
				jobId,
				fullName,
				email,
				phone,
				coverLetter,
				experienceYears,
				skills,
				resumeUrl,
			} = req.body;

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

			// Update talent profile with application data
			if (fullName) talent.name = fullName;
			if (phone) talent.phone = phone;

			// Update experience only if it's a valid enum value
			if (experienceYears && experienceYears.trim() !== '') {
				const validExperiences = [
					'fresh_graduate',
					'1-2_years',
					'3-5_years',
					'5+_years',
				];
				if (validExperiences.includes(experienceYears)) {
					talent.experience = experienceYears;
				}
			}

			if (skills && Array.isArray(skills)) talent.skills = skills;

			// Note: Email update should be done through user profile update, not talent profile
			// For now, we'll skip email update to avoid userId reference issues

			await talent.save();

			// Create application with all data
			const application = new Application({
				talentId: talent._id,
				jobId: jobId,
				companyId: job.companyId._id,
				coverLetter: coverLetter || '',
				resumeUrl: resumeUrl || talent.resumeUrl,
				// Additional application data
				applicationData: {
					fullName,
					email,
					phone,
					experienceYears,
					skills,
					appliedAt: new Date(),
					userAgent: req.get('User-Agent'),
				},
			});

			await application.save();

			// Increment application count for job
			job.applicationCount += 1;
			await job.save();

			// Populate application data
			await application.populate([
				{
					path: 'talentId',
					select: 'name skills experience phone userId',
					populate: { path: 'userId', select: 'email' },
				},
				{
					path: 'jobId',
					select: 'title companyId location salary',
					populate: { path: 'companyId', select: 'companyName' },
				},
			]);

			// Create chat room for this application
			try {
				const existingChat = await Chat.findOne({
					applicationId: application._id,
				});
				if (!existingChat) {
					// Find the company user (admin user with role admin)
					// First check if the companyId is already an admin user
					let companyUser = await User.findOne({
						_id: application.companyId,
						role: { $in: ['admin', 'company'] },
					});

					// If not found, find the admin user associated with this company
					if (!companyUser) {
						const company = await Company.findOne({
							userId: application.companyId,
						});
						if (company) {
							companyUser = await User.findOne({
								_id: company.userId,
								role: 'admin',
							});
						}
					}

					const chat = new Chat({
						applicationId: application._id,
						talentId: application.talentId,
						companyId: companyUser ? companyUser._id : application.companyId,
						messages: [
							{
								senderId: application.talentId,
								senderRole: 'talent',
								message:
									'Halo! Saya telah mengirimkan lamaran untuk posisi ini. Terima kasih atas kesempatan yang diberikan.',
								timestamp: new Date(),
								isRead: false,
							},
						],
						lastMessage:
							'Halo! Saya telah mengirimkan lamaran untuk posisi ini. Terima kasih atas kesempatan yang diberikan.',
						lastMessageTime: new Date(),
						talentUnreadCount: 0,
						companyUnreadCount: 1,
					});
					await chat.save();
					console.log(
						'✅ Chat room created for application:',
						application._id,
						'with company user:',
						companyUser?._id || application.companyId
					);
				}
			} catch (chatError) {
				console.error('❌ Error creating chat room:', chatError);
				// Don't fail the application if chat creation fails
			}

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

// @route   PUT /api/applications/:id/status
// @desc    Update application status (Company or Admin only)
// @access  Private (Company or Admin)
router.put('/:id/status', [auth, requireCompanyOrAdmin], async (req, res) => {
	try {
		const { status, notes, feedback } = req.body;
		const applicationId = req.params.id;

		// Validate status
		const validStatuses = [
			'pending',
			'reviewed',
			'interview',
			'hired',
			'rejected',
		];
		if (!validStatuses.includes(status)) {
			return res.status(400).json({
				success: false,
				message: 'Invalid status',
			});
		}

		// Find application
		const application = await Application.findById(applicationId);
		if (!application) {
			return res.status(404).json({
				success: false,
				message: 'Lamaran tidak ditemukan',
			});
		}

		// Check permissions (company can only update their own applications)
		if (
			req.user.role === 'company' &&
			application.companyId.toString() !== req.user._id.toString()
		) {
			return res.status(403).json({
				success: false,
				message: 'Akses ditolak',
			});
		}

		// Update status and add to history
		const oldStatus = application.status;
		application.status = status;
		application.feedback = feedback || application.feedback;
		application.notes = notes || application.notes;

		// Add to status history
		application.statusHistory.push({
			status: status,
			changedAt: new Date(),
			changedBy: req.user._id,
			notes: notes || `Status changed from ${oldStatus} to ${status}`,
		});

		// Set appropriate timestamps
		if (status === 'reviewed') {
			application.reviewedAt = new Date();
		} else if (status === 'interview') {
			application.interviewScheduledAt = new Date();
		}

		// Delete CV file if status is hired or rejected
		if (
			(status === 'hired' || status === 'rejected') &&
			application.resumeUrl
		) {
			try {
				const filePath = path.join(
					__dirname,
					'..',
					'uploads',
					'applications',
					path.basename(application.resumeUrl)
				);
				if (fs.existsSync(filePath)) {
					fs.unlinkSync(filePath);
					application.fileDeleted = true;
					application.fileDeletedAt = new Date();
					application.fileDeletedBy = req.user._id;
					console.log(`✅ CV file deleted for application ${applicationId}`);
				}
			} catch (fileError) {
				console.error('❌ Error deleting CV file:', fileError);
			}
		}

		await application.save();

		// Populate updated application
		await application.populate([
			{
				path: 'talentId',
				select: 'name skills experience phone',
				populate: { path: 'userId', select: 'email' },
			},
			{
				path: 'jobId',
				select: 'title companyId location salary',
				populate: { path: 'companyId', select: 'companyName' },
			},
		]);

		res.json({
			success: true,
			message: `Status lamaran berhasil diubah menjadi ${status}`,
			data: { application },
		});
	} catch (error) {
		console.error('Update application status error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   DELETE /api/applications/:id
// @desc    Delete/cancel application (Talent or Company or Admin)
// @access  Private
router.delete('/:id', auth, async (req, res) => {
	try {
		const applicationId = req.params.id;

		// Find application
		const application = await Application.findById(applicationId);
		if (!application) {
			return res.status(404).json({
				success: false,
				message: 'Lamaran tidak ditemukan',
			});
		}

		// Check permissions
		const canDelete =
			(req.user.role === 'talent' &&
				application.talentId.toString() === req.user._id.toString()) ||
			(req.user.role === 'company' &&
				application.companyId.toString() === req.user._id.toString()) ||
			req.user.role === 'admin';

		if (!canDelete) {
			return res.status(403).json({
				success: false,
				message: 'Akses ditolak',
			});
		}

		// Delete CV file if exists
		if (application.resumeUrl) {
			try {
				const filePath = path.join(
					__dirname,
					'..',
					'uploads',
					'applications',
					path.basename(application.resumeUrl)
				);
				if (fs.existsSync(filePath)) {
					fs.unlinkSync(filePath);
					console.log(`✅ CV file deleted for application ${applicationId}`);
				}
			} catch (fileError) {
				console.error('❌ Error deleting CV file:', fileError);
			}
		}

		// Delete application
		await Application.findByIdAndDelete(applicationId);

		res.json({
			success: true,
			message: 'Lamaran berhasil dihapus',
		});
	} catch (error) {
		console.error('Delete application error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

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
