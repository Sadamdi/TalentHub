const express = require('express');
const { body, validationResult } = require('express-validator');
const {
	auth,
	requireRole,
	requireCompanyOrAdmin,
} = require('../middleware/auth');
const Job = require('../models/Job');
const Company = require('../models/Company');
const User = require('../models/User');
const Application = require('../models/Application');

const router = express.Router();

// @route   GET /api/jobs
// @desc    Get all active jobs with pagination and filters
// @access  Public
router.get('/', async (req, res) => {
	try {
		const page = parseInt(req.query.page) || 1;
		const limit = parseInt(req.query.limit) || 10;
		const skip = (page - 1) * limit;

		// Build filter object
		const filter = { isActive: true };

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

		if (req.query.salaryMin) {
			filter['salary.amount'] = { $gte: parseInt(req.query.salaryMin) };
		}

		if (req.query.category) {
			filter.category = req.query.category;
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
		console.error('Get jobs error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   GET /api/jobs/company-jobs
// @desc    Get company's jobs (Company) or all jobs (Admin)
// @access  Private (Company or Admin)
router.get('/company-jobs', [auth, requireCompanyOrAdmin], async (req, res) => {
	try {
		let jobs;
		let total;

		if (req.user.role === 'admin') {
			// Admin gets all jobs
			console.log('Admin accessing all jobs');
			const page = parseInt(req.query.page) || 1;
			const limit = parseInt(req.query.limit) || 50;
			const skip = (page - 1) * limit;

			jobs = await Job.find({})
				.populate('companyId', 'companyName logo')
				.sort({ createdAt: -1 })
				.skip(skip)
				.limit(limit);

			total = await Job.countDocuments();

			console.log(`Admin found ${jobs.length} jobs out of ${total} total jobs`);

			res.json({
				success: true,
				message: 'Admin accessing all jobs',
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
		} else {
			// Company gets ALL jobs (same as admin)
			let company = await Company.findOne({ userId: req.user._id });
			if (!company) {
				console.log('❌ Company profile not found for user:', req.user._id);
				console.log('👤 User info:', {
					id: req.user._id,
					email: req.user.email,
					role: req.user.role,
					firstName: req.user.firstName,
					lastName: req.user.lastName,
				});

				// Auto-create company profile
				console.log('🏗️ Auto-creating company profile...');
				company = new Company({
					userId: req.user._id,
					companyName: `${req.user.firstName} ${req.user.lastName}`,
					description: 'Deskripsi perusahaan belum diisi',
					industry: 'Technology',
					location: req.user.location || 'Jakarta',
					phone: req.user.phoneNumber || '+6281234567890',
				});
				await company.save();
				console.log('✅ Company profile auto-created:', company._id);
			}

			console.log('Company accessing all jobs (same as admin)');
			const page = parseInt(req.query.page) || 1;
			const limit = parseInt(req.query.limit) || 50;
			const skip = (page - 1) * limit;

			jobs = await Job.find({})
				.populate('companyId', 'companyName logo')
				.sort({ createdAt: -1 })
				.skip(skip)
				.limit(limit);

			total = await Job.countDocuments();

			console.log(
				`Company found ${jobs.length} jobs out of ${total} total jobs`
			);

			res.json({
				success: true,
				message: 'Company accessing all jobs',
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
		}
	} catch (error) {
		console.error('Get company jobs error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   GET /api/jobs/:id
// @desc    Get job by ID
// @access  Public
router.get('/:id', async (req, res) => {
	try {
		const job = await Job.findById(req.params.id).populate(
			'companyId',
			'companyName logo industry description website'
		);

		if (!job) {
			return res.status(404).json({
				success: false,
				message: 'Lowongan pekerjaan tidak ditemukan',
			});
		}

		// Increment view count
		job.views += 1;
		await job.save();

		res.json({
			success: true,
			data: { job },
		});
	} catch (error) {
		console.error('Get job error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   POST /api/jobs
// @desc    Create new job (Company or Admin)
// @access  Private (Company or Admin)
router.post(
	'/',
	[
		auth,
		requireCompanyOrAdmin,
		body('title').notEmpty().withMessage('Judul pekerjaan diperlukan'),
		body('description')
			.notEmpty()
			.withMessage('Deskripsi pekerjaan diperlukan'),
		body('salary.amount').isNumeric().withMessage('Gaji harus berupa angka'),
		body('category')
			.isIn([
				'technology',
				'designer',
				'writer',
				'finance',
				'developer',
				'marketing',
				'sales',
				'hr',
				'operations',
				'design',
				'other',
			])
			.withMessage('Kategori tidak valid'),
		body('location').notEmpty().withMessage('Lokasi pekerjaan diperlukan'),
		body('experienceLevel')
			.isIn(['fresh_graduate', '1-2_years', '3-5_years', '5+_years'])
			.withMessage('Level pengalaman tidak valid'),
		body('jobType')
			.isIn(['full_time', 'part_time', 'contract', 'internship', 'freelance'])
			.withMessage('Tipe pekerjaan tidak valid'),
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

			let company;
			if (req.user.role === 'admin') {
				// For admin, try to find existing company profile or create minimal one
				company = await Company.findOne({ userId: req.user._id });
				if (!company) {
					// Create minimal company profile for admin
					const companyData = {
						userId: req.user._id,
						companyName: req.body.companyName || 'Admin Company',
						industry: req.body.industry || 'Technology',
						description: 'Company created by admin',
						website: 'https://admin.company',
						location: req.body.location || 'Jakarta',
						phone: '+6281234567890',
					};
					company = new Company(companyData);
					await company.save();
				}
			} else {
				// For regular company, find or create profile
				company = await Company.findOne({ userId: req.user._id });
				if (!company) {
					console.log(
						'Creating company profile for job creation, user:',
						req.user._id
					);
					company = new Company({
						userId: req.user._id,
						companyName: `${req.user.firstName} ${req.user.lastName}`,
						description: 'Deskripsi perusahaan belum diisi',
					});
					await company.save();
					console.log(
						'✅ Company profile created for job creation:',
						company._id
					);
				}
			}

			const jobData = {
				...req.body,
				companyId: company._id,
			};

			const job = new Job(jobData);
			await job.save();

			// Populate company info for response
			await job.populate('companyId', 'companyName logo industry');

			res.status(201).json({
				success: true,
				message: 'Lowongan pekerjaan berhasil dibuat',
				data: { job },
			});
		} catch (error) {
			console.error('Create job error:', error);
			res.status(500).json({
				success: false,
				message: 'Terjadi kesalahan pada server',
			});
		}
	}
);

// @route   PUT /api/jobs/:id
// @desc    Update job (Company or Admin)
// @access  Private (Company or Admin)
router.put('/:id', [auth, requireCompanyOrAdmin], async (req, res) => {
	try {
		let job;

		if (req.user.role === 'admin') {
			// Admin can update any job
			job = await Job.findById(req.params.id);
		} else {
			// Company can also update any job (same as admin)
			let company = await Company.findOne({ userId: req.user._id });
			if (!company) {
				console.log(
					'Creating company profile for job update, user:',
					req.user._id
				);
				company = new Company({
					userId: req.user._id,
					companyName: `${req.user.firstName} ${req.user.lastName}`,
					description: 'Deskripsi perusahaan belum diisi',
				});
				await company.save();
				console.log('✅ Company profile created for job update:', company._id);
			}
			// Company can update any job now
			job = await Job.findById(req.params.id);
		}

		if (!job) {
			return res.status(404).json({
				success: false,
				message: 'Lowongan pekerjaan tidak ditemukan atau tidak memiliki akses',
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
		console.error('Update job error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   DELETE /api/jobs/:id
// @desc    Delete job (Company or Admin)
// @access  Private (Company or Admin)
router.delete('/:id', [auth, requireCompanyOrAdmin], async (req, res) => {
	try {
		let job;

		if (req.user.role === 'admin') {
			// Admin can delete any job
			job = await Job.findById(req.params.id);
		} else {
			// Company can also delete any job (same as admin)
			let company = await Company.findOne({ userId: req.user._id });
			if (!company) {
				console.log(
					'Creating company profile for job delete, user:',
					req.user._id
				);
				company = new Company({
					userId: req.user._id,
					companyName: `${req.user.firstName} ${req.user.lastName}`,
					description: 'Deskripsi perusahaan belum diisi',
				});
				await company.save();
				console.log('✅ Company profile created for job delete:', company._id);
			}
			// Company can delete any job now
			job = await Job.findById(req.params.id);
		}

		if (!job) {
			return res.status(404).json({
				success: false,
				message: 'Lowongan pekerjaan tidak ditemukan atau tidak memiliki akses',
			});
		}

		// Hard delete - permanently remove from database
		await Job.findByIdAndDelete(req.params.id);

		res.json({
			success: true,
			message: 'Lowongan pekerjaan berhasil dihapus secara permanen',
		});
	} catch (error) {
		console.error('Delete job error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// Helper function to get all jobs for admin
async function getAllJobsForAdmin(req) {
	try {
		const page = parseInt(req.query.page) || 1;
		const limit = parseInt(req.query.limit) || 50;
		const skip = (page - 1) * limit;

		const jobs = await Job.find({})
			.populate('companyId', 'companyName logo')
			.sort({ createdAt: -1 })
			.skip(skip)
			.limit(limit);

		const total = await Job.countDocuments();

		return {
			jobs,
			pagination: {
				currentPage: page,
				totalPages: Math.ceil(total / limit),
				totalJobs: total,
				hasNext: page < Math.ceil(total / limit),
				hasPrev: page > 1,
			},
		};
	} catch (error) {
		console.error('Get all jobs for admin error:', error);
		throw error;
	}
}

// @route   GET /api/jobs/recommendations
// @desc    Get job recommendations for talent
// @access  Public
router.get('/recommendations', async (req, res) => {
	try {
		const limit = parseInt(req.query.limit) || 10;
		const category = req.query.category;

		// Build filter
		const filter = { isActive: true };
		if (category && category !== 'all') {
			filter.category = category;
		}

		const jobs = await Job.find(filter)
			.populate('companyId', 'companyName logo industry')
			.sort({ createdAt: -1 })
			.limit(limit);

		res.json({
			success: true,
			data: { jobs },
		});
	} catch (error) {
		console.error('Get recommendations error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   GET /api/jobs/:id/applications
// @desc    Get applications for a specific job (Company or Admin)
// @access  Private (Company or Admin)
router.get(
	'/:id/applications',
	[auth, requireCompanyOrAdmin],
	async (req, res) => {
		try {
			let job;

			if (req.user.role === 'admin') {
				// Admin can access any job's applications
				job = await Job.findById(req.params.id);
			} else {
				// Regular company can only access their own job's applications
				const company = await Company.findOne({ userId: req.user._id });
				if (!company) {
					return res.status(404).json({
						success: false,
						message: 'Profil perusahaan tidak ditemukan',
					});
				}
				job = await Job.findOne({
					_id: req.params.id,
					companyId: company._id,
				});
			}

			if (!job) {
				return res.status(404).json({
					success: false,
					message:
						'Lowongan pekerjaan tidak ditemukan atau tidak memiliki akses',
				});
			}

			const applications = await Application.find({ jobId: job._id })
				.populate('talentId', 'name skills experience')
				.sort({ appliedAt: -1 });

			res.json({
				success: true,
				data: { applications },
			});
		} catch (error) {
			console.error('Get job applications error:', error);
			res.status(500).json({
				success: false,
				message: 'Terjadi kesalahan pada server',
			});
		}
	}
);

// @route   GET /api/jobs/debug/company-data
// @desc    Debug company data and relationships
// @access  Private (Company only)
router.get('/debug/company-data', auth, async (req, res) => {
	try {
		const userId = req.user._id;
		const userEmail = req.user.email;

		console.log(`🔍 DEBUG: Looking for data for user ${userId} (${userEmail})`);

		// Find user
		const user = await User.findById(userId);
		console.log(
			'👤 User found:',
			user
				? {
						id: user._id,
						email: user.email,
						role: user.role,
						firstName: user.firstName,
						lastName: user.lastName,
				  }
				: 'NOT FOUND'
		);

		// Find company profile
		const company = await Company.findOne({ userId: userId });
		console.log(
			'🏢 Company profile:',
			company
				? {
						id: company._id,
						userId: company.userId,
						companyName: company.companyName,
						description: company.description,
				  }
				: 'NOT FOUND'
		);

		// Find all companies in database
		const allCompanies = await Company.find({});
		console.log(`📊 Total companies in DB: ${allCompanies.length}`);
		allCompanies.forEach((comp, index) => {
			console.log(`Company ${index + 1}:`, {
				id: comp._id,
				userId: comp.userId,
				companyName: comp.companyName,
			});
		});

		// Find jobs by this company (if exists)
		let jobs = [];
		if (company) {
			jobs = await Job.find({ companyId: company._id });
			console.log(`💼 Jobs found for company ${company._id}: ${jobs.length}`);
		}

		// Find all jobs and see their companyId
		const allJobs = await Job.find({}).populate(
			'companyId',
			'companyName userId'
		);
		console.log(`📊 Total jobs in DB: ${allJobs.length}`);
		allJobs.forEach((job, index) => {
			console.log(`Job ${index + 1}:`, {
				id: job._id,
				title: job.title,
				companyId: job.companyId ? job.companyId._id : 'NULL',
				companyName: job.companyId ? job.companyId.companyName : 'NULL',
				companyUserId: job.companyId ? job.companyId.userId : 'NULL',
			});
		});

		// Check if any job belongs to this user through companyId.userId
		const jobsByUserThroughCompany = await Job.find({}).populate({
			path: 'companyId',
			match: { userId: userId },
		});
		const validJobsByUser = jobsByUserThroughCompany.filter(
			(job) => job.companyId
		);
		console.log(`🔗 Jobs linked to user ${userId}: ${validJobsByUser.length}`);

		res.json({
			success: true,
			debug: {
				user: user
					? {
							id: user._id,
							email: user.email,
							role: user.role,
							firstName: user.firstName,
							lastName: user.lastName,
					  }
					: null,
				company: company
					? {
							id: company._id,
							userId: company.userId,
							companyName: company.companyName,
							description: company.description,
					  }
					: null,
				totalCompanies: allCompanies.length,
				allCompanies: allCompanies.map((c) => ({
					id: c._id,
					userId: c.userId,
					companyName: c.companyName,
				})),
				directJobs: jobs.length,
				totalJobs: allJobs.length,
				jobsLinkedToUser: validJobsByUser.length,
				allJobs: allJobs.map((j) => ({
					id: j._id,
					title: j.title,
					companyId: j.companyId ? j.companyId._id : null,
					companyName: j.companyId ? j.companyId.companyName : null,
					companyUserId: j.companyId ? j.companyId.userId : null,
				})),
			},
		});
	} catch (error) {
		console.error('Debug error:', error);
		res.status(500).json({
			success: false,
			message: 'Debug error',
			error: error.message,
		});
	}
});

// @route   POST /api/jobs/debug/fix-company-data
// @desc    Fix company data mapping for specific user
// @access  Private (Company only)
router.post('/debug/fix-company-data', auth, async (req, res) => {
	try {
		const userId = req.user._id;
		const userEmail = req.user.email;

		console.log(`🔧 FIXING: Data for user ${userId} (${userEmail})`);

		// Find or create company profile
		let company = await Company.findOne({ userId: userId });
		if (!company) {
			console.log('🏗️ Creating new company profile...');
			company = new Company({
				userId: userId,
				companyName: `${req.user.firstName} ${req.user.lastName}`,
				description: 'Deskripsi perusahaan belum diisi',
			});
			await company.save();
			console.log('✅ Company profile created:', company._id);
		} else {
			console.log('✅ Company profile found:', company._id);
		}

		// Find jobs that might belong to this user but linked to different companies
		const allJobs = await Job.find({}).populate(
			'companyId',
			'userId companyName'
		);
		const orphanJobs = allJobs.filter(
			(job) =>
				job.companyId &&
				job.companyId.userId &&
				job.companyId.userId.toString() === userId.toString() &&
				job.companyId._id.toString() !== company._id.toString()
		);

		console.log(`🔍 Found ${orphanJobs.length} orphan jobs to reassign`);

		// Reassign orphan jobs to the correct company
		const fixedJobs = [];
		for (const job of orphanJobs) {
			console.log(
				`🔧 Reassigning job "${job.title}" from company ${job.companyId._id} to ${company._id}`
			);
			job.companyId = company._id;
			await job.save();
			fixedJobs.push({
				id: job._id,
				title: job.title,
				oldCompanyId: job.companyId._id,
				newCompanyId: company._id,
			});
		}

		// Find applications that need fixing
		const allApplications = await Application.find({}).populate(
			'companyId',
			'userId companyName'
		);
		const orphanApplications = allApplications.filter(
			(app) =>
				app.companyId &&
				app.companyId.userId &&
				app.companyId.userId.toString() === userId.toString() &&
				app.companyId._id.toString() !== company._id.toString()
		);

		console.log(
			`🔍 Found ${orphanApplications.length} orphan applications to reassign`
		);

		// Reassign orphan applications to the correct company
		const fixedApplications = [];
		for (const app of orphanApplications) {
			console.log(
				`🔧 Reassigning application ${app._id} from company ${app.companyId._id} to ${company._id}`
			);
			app.companyId = company._id;
			await app.save();
			fixedApplications.push({
				id: app._id,
				oldCompanyId: app.companyId._id,
				newCompanyId: company._id,
			});
		}

		// Get updated counts
		const finalJobs = await Job.find({ companyId: company._id });
		const finalApplications = await Application.find({
			companyId: company._id,
		});

		res.json({
			success: true,
			message: 'Data mapping fixed successfully',
			result: {
				userId: userId,
				userEmail: userEmail,
				company: {
					id: company._id,
					name: company.companyName,
					userId: company.userId,
				},
				fixes: {
					jobsReassigned: fixedJobs.length,
					applicationsReassigned: fixedApplications.length,
					fixedJobs: fixedJobs,
					fixedApplications: fixedApplications,
				},
				finalCounts: {
					totalJobs: finalJobs.length,
					totalApplications: finalApplications.length,
				},
			},
		});
	} catch (error) {
		console.error('Fix data error:', error);
		res.status(500).json({
			success: false,
			message: 'Fix data error',
			error: error.message,
		});
	}
});

module.exports = router;
