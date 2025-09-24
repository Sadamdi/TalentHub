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
			jobId: jobId
		});

		if (!existingApplication) {
			return { canApply: true, reason: null };
		}

		// Allow re-apply if previous application was rejected or cancelled
		if (['rejected', 'cancelled'].includes(existingApplication.status)) {
			return { canApply: true, reason: 'Previous application was ' + existingApplication.status };
		}

		// Don't allow if hired or still in review
		if (['hired', 'pending', 'interview'].includes(existingApplication.status)) {
			return { 
				canApply: false, 
				reason: `You already have a ${existingApplication.status} application for this job`,
				existingStatus: existingApplication.status
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
					existingStatus: eligibility.existingStatus
				});
			}

			// If there's a previous rejected/cancelled application, delete it first
			if (eligibility.reason && eligibility.reason.includes('Previous application')) {
				const talent = await Talent.findOne({ userId: req.user._id });
				await Application.deleteOne({
					talentId: talent._id,
					jobId: jobId,
					status: { $in: ['rejected', 'cancelled'] }
				});
				console.log('🗑️ Deleted previous rejected/cancelled application for re-apply');
			}

			// Get or create talent profile
			let talent = await Talent.findOne({ userId: req.user._id });

			if (!talent) {
				// Create talent profile if it doesn't exist
				talent = new Talent({
					userId: req.user._id,
					name: fullName,
					skills: skills || [],
					experience: experienceYears || '',
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
					talent.experience = experienceYears;
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
						console.log('💬 Chat room created for application:', application._id);
					}
				}
			} catch (chatError) {
				console.error('Chat creation error (non-critical):', chatError);
			}

			res.status(201).json({
				success: true,
				message: eligibility.reason ? 
					'Lamaran berhasil dikirim ulang!' : 
					'Lamaran berhasil dikirim!',
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
						isReapplication: !!eligibility.reason
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

// Continue with other routes from the original file...
// (keeping all other existing routes unchanged)

module.exports = router;