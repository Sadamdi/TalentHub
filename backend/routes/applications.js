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

// Helper function to check if user can apply for job
async function canUserApplyForJob(userId, jobId) {
	try {
		const existingApplication = await Application.findOne({
			talentId: await Talent.findOne({ userId: userId }),
			jobId: jobId,
		});

		if (!existingApplication) {
			return { canApply: true, reason: null };
		}

		// Allow re-apply if previous application was rejected or cancelled
		if (['rejected', 'cancelled'].includes(existingApplication.status)) {
			return {
				canApply: true,
				reason: 'Previous application was ' + existingApplication.status,
			};
		}

		// Don't allow if hired or still in review
		if (
			['hired', 'pending', 'interview'].includes(existingApplication.status)
		) {
			return {
				canApply: false,
				reason: `You already have a ${existingApplication.status} application for this job`,
				existingStatus: existingApplication.status,
			};
		}

		return { canApply: true, reason: null };
	} catch (error) {
		console.error('Error checking application eligibility:', error);
		return { canApply: false, reason: 'Error checking application status' };
	}
}

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

			// Check if user can apply for this job
			const eligibility = await canUserApplyForJob(req.user._id, jobId);
			if (!eligibility.canApply) {
				return res.status(400).json({
					success: false,
					message: eligibility.reason,
					existingStatus: eligibility.existingStatus,
				});
			}

			// If there's a previous rejected/cancelled application, delete it first
			if (
				eligibility.reason &&
				eligibility.reason.includes('Previous application')
			) {
				const talent = await Talent.findOne({ userId: req.user._id });
				await Application.deleteOne({
					talentId: talent._id,
					jobId: jobId,
					status: { $in: ['rejected', 'cancelled'] },
				});
				console.log(
					'🗑️ Deleted previous rejected/cancelled application for re-apply'
				);
			}

			// Helper function to convert experience to enum value
			const convertExperienceToEnum = (experience) => {
				if (!experience) return 'fresh_graduate';

				const exp = experience.toLowerCase();
				if (exp.includes('fresh') || exp.includes('0') || exp === '0 years') {
					return 'fresh_graduate';
				} else if (
					exp.includes('1') ||
					exp.includes('2') ||
					exp === '1-2 years'
				) {
					return '1-2_years';
				} else if (
					exp.includes('3') ||
					exp.includes('4') ||
					exp.includes('5') ||
					exp === '3-5 years'
				) {
					return '3-5_years';
				} else {
					return '5+_years';
				}
			};

			// Get or create talent profile
			let talent = await Talent.findOne({ userId: req.user._id });

			if (!talent) {
				// Create talent profile if it doesn't exist
				talent = new Talent({
					userId: req.user._id,
					name: fullName,
					description: 'Talent profile description', // Add required description
					skills: skills || [],
					experience: convertExperienceToEnum(experienceYears),
					phone: phone,
					resumeUrl: resumeUrl,
				});
				await talent.save();
				console.log('✅ Talent profile created:', talent._id);
			} else {
				// Update talent profile with latest info
				talent.name = fullName;
				talent.phone = phone;
				if (skills && skills.length > 0) {
					talent.skills = skills;
				}
				if (experienceYears) {
					talent.experience = convertExperienceToEnum(experienceYears);
				}
				if (resumeUrl) {
					talent.resumeUrl = resumeUrl;
				}
				await talent.save();
				console.log('📝 Talent profile updated:', talent._id);
			}

			// Create application
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
					select: 'name skills experience portfolio resumeUrl',
					populate: { path: 'userId', select: 'email' },
				},
				{
					path: 'jobId',
					select: 'title description requirements location salary',
				},
				{
					path: 'companyId',
					select: 'companyName logo',
				},
			]);

			// Create chat room for this application
			try {
				const existingChat = await Chat.findOne({
					applicationId: application._id,
				});
				if (!existingChat) {
					// Get the talent's userId and company's userId
					const talentUser = await User.findById(req.user._id);
					const companyUser = await User.findById(job.companyId.userId);

					if (talentUser && companyUser) {
						const chat = new Chat({
							applicationId: application._id,
							talentId: req.user._id,
							companyId: job.companyId.userId,
							messages: [],
							talentUnreadCount: 0,
							companyUnreadCount: 0,
						});
						await chat.save();
						console.log(
							'💬 Chat room created for application:',
							application._id
						);
					}
				}
			} catch (chatError) {
				console.error('Chat creation error (non-critical):', chatError);
			}

			res.status(201).json({
				success: true,
				message: eligibility.reason
					? 'Lamaran berhasil dikirim ulang!'
					: 'Lamaran berhasil dikirim!',
				data: {
					application: {
						_id: application._id,
						status: application.status,
						appliedAt: application.createdAt,
						job: {
							title: job.title,
							company: job.companyId.companyName,
						},
						hasCV: !!application.resumeUrl,
						isReapplication: !!eligibility.reason,
					},
				},
			});
		} catch (error) {
			console.error('Application submission error:', error);
			res.status(500).json({
				success: false,
				message: 'Terjadi kesalahan pada server',
			});
		}
	}
);

// @route   GET /api/applications
// @desc    Get applications for talent
// @access  Private (Talent only)
router.get('/', [auth, requireRole(['talent'])], async (req, res) => {
	try {
		const talent = await Talent.findOne({ userId: req.user._id });
		if (!talent) {
			return res.json({
				success: true,
				data: { applications: [] },
			});
		}

		const applications = await Application.find({ talentId: talent._id })
			.populate({
				path: 'jobId',
				select: 'title description location salary',
				populate: {
					path: 'companyId',
					select: 'companyName logo',
				},
			})
			.sort({ createdAt: -1 });

		const formattedApplications = applications.map((app) => ({
			...app.toObject(),
			jobTitle: app.jobId?.title || 'Job Title',
			companyName: app.jobId?.companyId?.companyName || 'Company Name',
			applicantName: req.user.firstName + ' ' + req.user.lastName,
			applicantEmail: req.user.email,
		}));

		res.json({
			success: true,
			data: { applications: formattedApplications },
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
// @desc    Get applications for company
// @access  Private (Company or Admin only)
router.get('/company', [auth, requireCompanyOrAdmin], async (req, res) => {
	try {
		let company;

		if (req.user.role === 'admin') {
			// Admin can see all applications
			const applications = await Application.find()
				.populate({
					path: 'jobId',
					select: 'title description location salary',
					populate: {
						path: 'companyId',
						select: 'companyName logo',
					},
				})
				.populate({
					path: 'talentId',
					select: 'name skills experience resumeUrl',
					populate: {
						path: 'userId',
						select: 'firstName lastName email',
					},
				})
				.sort({ createdAt: -1 });

			const formattedApplications = applications.map((app) => ({
				...app.toObject(),
				jobTitle: app.jobId?.title || 'Job Title',
				companyName: app.jobId?.companyId?.companyName || 'Company Name',
				applicantName: app.talentId?.userId
					? `${app.talentId.userId.firstName} ${app.talentId.userId.lastName}`
					: app.talentId?.name || 'Unknown Applicant',
				applicantEmail: app.talentId?.userId?.email || 'No Email',
			}));

			return res.json({
				success: true,
				data: { applications: formattedApplications },
			});
		}

		// For company users, get only applications for their jobs
		company = await Company.findOne({ userId: req.user._id });
		if (!company) {
			// Auto-create company profile if it doesn't exist
			company = new Company({
				userId: req.user._id,
				companyName: `${req.user.firstName} ${req.user.lastName}`,
				description: 'Deskripsi perusahaan belum diisi',
			});
			await company.save();
		}

		// Find all jobs created by this company
		const Job = require('../models/Job');
		const companyJobs = await Job.find({ companyId: company._id }).select(
			'_id'
		);
		const companyJobIds = companyJobs.map((job) => job._id);

		// Company can only see applications for their own jobs
		const applications = await Application.find({
			jobId: { $in: companyJobIds },
		})
			.populate({
				path: 'jobId',
				select: 'title description location salary',
				populate: {
					path: 'companyId',
					select: 'companyName logo',
				},
			})
			.populate({
				path: 'talentId',
				select: 'name skills experience resumeUrl',
				populate: {
					path: 'userId',
					select: 'firstName lastName email',
				},
			})
			.sort({ createdAt: -1 });

		const formattedApplications = applications.map((app) => ({
			...app.toObject(),
			jobTitle: app.jobId?.title || 'Job Title',
			companyName: app.jobId?.companyId?.companyName || 'Company Name',
			applicantName: app.talentId?.userId
				? `${app.talentId.userId.firstName} ${app.talentId.userId.lastName}`
				: app.talentId?.name || 'Unknown Applicant',
			applicantEmail: app.talentId?.userId?.email || 'No Email',
		}));

		res.json({
			success: true,
			data: { applications: formattedApplications },
		});
	} catch (error) {
		console.error('Get company applications error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   GET /api/applications/job/:jobId
// @desc    Get applications for specific job
// @access  Private (Company or Admin only)
router.get('/job/:jobId', [auth, requireCompanyOrAdmin], async (req, res) => {
	try {
		const applications = await Application.find({ jobId: req.params.jobId })
			.populate({
				path: 'talentId',
				select: 'name skills experience resumeUrl',
				populate: {
					path: 'userId',
					select: 'firstName lastName email',
				},
			})
			.populate({
				path: 'jobId',
				select: 'title description location salary',
				populate: {
					path: 'companyId',
					select: 'companyName logo',
				},
			})
			.sort({ createdAt: -1 });

		const formattedApplications = applications.map((app) => ({
			...app.toObject(),
			jobTitle: app.jobId?.title || 'Job Title',
			companyName: app.jobId?.companyId?.companyName || 'Company Name',
			applicantName: app.talentId?.userId
				? `${app.talentId.userId.firstName} ${app.talentId.userId.lastName}`
				: app.talentId?.name || 'Unknown Applicant',
			applicantEmail: app.talentId?.userId?.email || 'No Email',
		}));

		res.json({
			success: true,
			data: { applications: formattedApplications },
		});
	} catch (error) {
		console.error('Get job applications error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   PUT /api/applications/:id/status
// @desc    Update application status (Company or Admin only)
// @access  Private (Company or Admin only)
router.put(
	'/:id/status',
	[
		auth,
		requireCompanyOrAdmin,
		body('status')
			.isIn(['pending', 'interview', 'hired', 'rejected'])
			.withMessage('Status tidak valid'),
		body('notes')
			.optional()
			.isLength({ max: 500 })
			.withMessage('Catatan maksimal 500 karakter'),
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

			// Validate ObjectId format
			if (!req.params.id.match(/^[0-9a-fA-F]{24}$/)) {
				return res.status(400).json({
					success: false,
					message: 'Invalid application ID format',
				});
			}

			const { status, notes } = req.body;
			const application = await Application.findById(req.params.id);

			if (!application) {
				return res.status(404).json({
					success: false,
					message: 'Lamaran tidak ditemukan',
				});
			}

			// Update status and notes
			application.status = status;
			if (notes) {
				application.notes = notes;
			}

			// Set timestamp based on status
			if (status === 'hired' || status === 'rejected') {
				application.reviewedAt = new Date();
			} else if (status === 'interview') {
				application.interviewScheduledAt = new Date();
			}

			await application.save();

			// Populate updated application
			await application.populate([
				{
					path: 'talentId',
					select: 'name skills experience phone',
					populate: { path: 'userId', select: 'firstName lastName email' },
				},
				{
					path: 'jobId',
					select: 'title description requirements location salary',
					populate: { path: 'companyId', select: 'companyName logo' },
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

// @route   GET /api/applications/me
// @desc    Get current user's applications
// @access  Private (Talent only)
router.get('/me', [auth], async (req, res) => {
	try {
		const talent = await Talent.findOne({ userId: req.user._id });
		if (!talent) {
			return res.json({
				success: true,
				data: { applications: [] },
			});
		}

		const applications = await Application.find({ talentId: talent._id })
			.populate({
				path: 'jobId',
				select: 'title description location salary',
				populate: {
					path: 'companyId',
					select: 'companyName logo',
				},
			})
			.sort({ createdAt: -1 });

		const formattedApplications = applications.map((app) => ({
			...app.toObject(),
			jobTitle: app.jobId?.title || 'Job Title',
			companyName: app.jobId?.companyId?.companyName || 'Company Name',
			applicantName: req.user.firstName + ' ' + req.user.lastName,
			applicantEmail: req.user.email,
		}));

		res.json({
			success: true,
			data: { applications: formattedApplications },
		});
	} catch (error) {
		console.error('Get my applications error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   GET /api/applications/:id
// @desc    Get single application details
// @access  Private
router.get('/:id', auth, async (req, res) => {
	try {
		// Validate ObjectId format
		if (!req.params.id.match(/^[0-9a-fA-F]{24}$/)) {
			return res.status(400).json({
				success: false,
				message: 'Invalid application ID format',
			});
		}

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

		res.json({
			success: true,
			data: application,
		});
	} catch (error) {
		console.error('Get application error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   GET /api/applications/:id/cv
// @desc    Download CV for application
// @access  Private
router.get('/:id/cv', auth, async (req, res) => {
	try {
		// Validate ObjectId format
		if (!req.params.id.match(/^[0-9a-fA-F]{24}$/)) {
			return res.status(400).json({
				success: false,
				message: 'Invalid application ID format',
			});
		}

		const application = await Application.findById(req.params.id);
		if (!application) {
			return res.status(404).json({
				success: false,
				message: 'Lamaran tidak ditemukan',
			});
		}

		if (!application.resumeUrl) {
			return res.status(404).json({
				success: false,
				message: 'CV tidak ditemukan',
			});
		}

		const filePath = path.join(
			__dirname,
			'..',
			'uploads',
			'applications',
			path.basename(application.resumeUrl)
		);

		if (!fs.existsSync(filePath)) {
			return res.status(404).json({
				success: false,
				message: 'File CV tidak ditemukan di server',
			});
		}

		// Send file
		res.download(filePath, `CV-${application._id}.pdf`);
	} catch (error) {
		console.error('Download CV error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   DELETE /api/applications/:id
// @desc    Cancel/Delete application (Talent only)
// @access  Private (Talent only)
router.delete('/:id', auth, async (req, res) => {
	try {
		const { _id: userId, role } = req.user;
		const applicationId = req.params.id;

		// Validate ObjectId format
		if (!applicationId.match(/^[0-9a-fA-F]{24}$/)) {
			return res.status(400).json({
				success: false,
				message: 'Invalid application ID format',
			});
		}

		// Find application
		const application = await Application.findById(applicationId)
			.populate('talentId')
			.populate('jobId')
			.populate('companyId');

		if (!application) {
			return res.status(404).json({
				success: false,
				message: 'Lamaran tidak ditemukan',
			});
		}

		// Check if user is the talent who applied or admin
		if (role === 'talent') {
			if (application.talentId.userId.toString() !== userId.toString()) {
				return res.status(403).json({
					success: false,
					message: 'Anda tidak memiliki akses untuk membatalkan lamaran ini',
				});
			}
		} else if (role !== 'admin') {
			return res.status(403).json({
				success: false,
				message: 'Akses ditolak',
			});
		}

		// Check if application can be cancelled (only pending, reviewed, or interview status)
		if (!['pending', 'reviewed', 'interview'].includes(application.status)) {
			return res.status(400).json({
				success: false,
				message: `Lamaran dengan status '${application.status}' tidak dapat dibatalkan`,
			});
		}

		// Update status to cancelled instead of deleting
		application.status = 'cancelled';
		application.statusHistory.push({
			status: 'cancelled',
			changedAt: new Date(),
			changedBy: userId,
			notes:
				role === 'talent' ? 'Dibatalkan oleh pelamar' : 'Dibatalkan oleh admin',
		});
		application.updatedAt = new Date();

		await application.save();

		res.json({
			success: true,
			message: 'Lamaran berhasil dibatalkan',
			data: { application },
		});
	} catch (error) {
		console.error('Cancel application error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

module.exports = router;
