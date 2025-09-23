const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, requireRole } = require('../middleware/auth');
const Job = require('../models/Job');
const Company = require('../models/Company');
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

// @route   GET /api/jobs/test-endpoint
// @desc    Test endpoint
// @access  Public
router.get('/test-endpoint', (req, res) => {
	console.log('Test endpoint called successfully');
	res.json({
		success: true,
		message: 'Jobs endpoint is working',
		timestamp: new Date().toISOString(),
	});
});

// @route   GET /api/jobs/ping
// @desc    Simple ping endpoint for connectivity testing
// @access  Public
router.get('/ping', (req, res) => {
	console.log('Ping endpoint called successfully');
	res.json({
		success: true,
		message: 'Server is reachable',
		timestamp: new Date().toISOString(),
		serverInfo: {
			port: process.env.PORT || 2550,
			nodeVersion: process.version,
			uptime: process.uptime(),
		},
	});
});

// @route   GET /api/jobs/debug-jwt
// @desc    Debug JWT token
// @access  Public
router.get('/debug-jwt', async (req, res) => {
	try {
		const token = req.header('Authorization')?.replace('Bearer ', '');

		if (!token) {
			return res.json({
				success: false,
				message: 'No token provided',
				debug: {
					jwtSecretLength: process.env.JWT_SECRET?.length || 0,
					jwtSecretPreview:
						process.env.JWT_SECRET?.substring(0, 10) + '...' || 'undefined',
				},
			});
		}

		const jwt = require('jsonwebtoken');

		try {
			const decoded = jwt.verify(token, process.env.JWT_SECRET);
			res.json({
				success: true,
				message: 'Token is valid',
				tokenData: decoded,
				debug: {
					jwtSecretLength: process.env.JWT_SECRET?.length || 0,
					jwtSecretPreview:
						process.env.JWT_SECRET?.substring(0, 10) + '...' || 'undefined',
				},
			});
		} catch (jwtError) {
			res.json({
				success: false,
				message: 'Token is invalid: ' + jwtError.message,
				error: jwtError.message,
				debug: {
					jwtSecretLength: process.env.JWT_SECRET?.length || 0,
					jwtSecretPreview:
						process.env.JWT_SECRET?.substring(0, 10) + '...' || 'undefined',
					tokenPreview: token.substring(0, 20) + '...',
				},
			});
		}
	} catch (error) {
		res.status(500).json({
			success: false,
			message: 'Server error: ' + error.message,
		});
	}
});

// @route   GET /api/jobs/test-company-jobs
// @desc    Test company jobs endpoint (debugging)
// @access  Public (for testing)
router.get('/test-company-jobs', async (req, res) => {
	try {
		// Get token from header (optional for testing)
		const token = req.header('Authorization')?.replace('Bearer ', '');

		if (!token) {
			return res.json({
				success: false,
				message: 'No token provided - this endpoint requires authentication',
				debug: {
					jwtSecretLength: process.env.JWT_SECRET?.length || 0,
					jwtSecretPreview:
						process.env.JWT_SECRET?.substring(0, 10) + '...' || 'undefined',
				},
			});
		}

		const jwt = require('jsonwebtoken');

		try {
			const decoded = jwt.verify(token, process.env.JWT_SECRET);
			const User = require('../models/User');
			const user = await User.findById(decoded.userId).select('-password');

			if (!user || !user.isActive || user.role !== 'company') {
				return res.status(401).json({
					success: false,
					message: 'Invalid user or role',
				});
			}

			const Company = require('../models/Company');
			const company = await Company.findOne({ userId: user._id });

			if (!company) {
				return res.status(404).json({
					success: false,
					message: 'Company profile not found',
				});
			}

			const Job = require('../models/Job');
			const jobs = await Job.find({ companyId: company._id })
				.populate('companyId', 'companyName logo')
				.sort({ createdAt: -1 });

			res.json({
				success: true,
				message: 'Company jobs retrieved successfully',
				data: {
					jobs,
					company: {
						id: company._id,
						name: company.companyName,
					},
					user: {
						id: user._id,
						email: user.email,
						role: user.role,
					},
				},
			});
		} catch (jwtError) {
			res.json({
				success: false,
				message: 'Token verification failed: ' + jwtError.message,
				debug: {
					jwtSecretLength: process.env.JWT_SECRET?.length || 0,
					jwtSecretPreview:
						process.env.JWT_SECRET?.substring(0, 10) + '...' || 'undefined',
					tokenPreview: token.substring(0, 20) + '...',
				},
			});
		}
	} catch (error) {
		res.status(500).json({
			success: false,
			message: 'Server error: ' + error.message,
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
// @desc    Create new job (Company only)
// @access  Private (Company only)
router.post(
	'/',
	[
		auth,
		requireRole(['company']),
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

			// Get company info
			const company = await Company.findOne({ userId: req.user._id });
			if (!company) {
				return res.status(404).json({
					success: false,
					message: 'Profil perusahaan tidak ditemukan',
				});
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
// @desc    Update job (Company only)
// @access  Private (Company only)
router.put('/:id', [auth, requireRole(['company'])], async (req, res) => {
	try {
		const company = await Company.findOne({ userId: req.user._id });
		if (!company) {
			return res.status(404).json({
				success: false,
				message: 'Profil perusahaan tidak ditemukan',
			});
		}

		const job = await Job.findOne({
			_id: req.params.id,
			companyId: company._id,
		});

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
// @desc    Delete job (Company only)
// @access  Private (Company only)
router.delete('/:id', [auth, requireRole(['company'])], async (req, res) => {
	try {
		const company = await Company.findOne({ userId: req.user._id });
		if (!company) {
			return res.status(404).json({
				success: false,
				message: 'Profil perusahaan tidak ditemukan',
			});
		}

		const job = await Job.findOne({
			_id: req.params.id,
			companyId: company._id,
		});

		if (!job) {
			return res.status(404).json({
				success: false,
				message: 'Lowongan pekerjaan tidak ditemukan atau tidak memiliki akses',
			});
		}

		// Soft delete by setting isActive to false
		job.isActive = false;
		await job.save();

		res.json({
			success: true,
			message: 'Lowongan pekerjaan berhasil dihapus',
		});
	} catch (error) {
		console.error('Delete job error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   GET /api/jobs/company-jobs
// @desc    Get company's jobs
// @access  Private (Company only)
router.get('/company-jobs', async (req, res) => {
	try {
		// Get token from header
		const token = req.header('Authorization')?.replace('Bearer ', '');
		if (!token) {
			return res.status(401).json({
				success: false,
				message: 'Token akses diperlukan',
			});
		}

		// Verify token manually
		const jwt = require('jsonwebtoken');
		let decoded;
		try {
			decoded = jwt.verify(token, process.env.JWT_SECRET);
			console.log('Token decoded:', decoded);
		} catch (jwtError) {
			console.log('JWT verification error:', jwtError.message);
			console.log('JWT_SECRET used:', process.env.JWT_SECRET);
			console.log(
				'Token received:',
				token ? token.substring(0, 20) + '...' : 'null'
			);
			return res.status(401).json({
				success: false,
				message: 'Token tidak valid: ' + jwtError.message,
			});
		}

		const User = require('../models/User');
		const user = await User.findById(decoded.userId).select('-password');
		console.log('User found:', user);

		if (!user || !user.isActive || user.role !== 'company') {
			return res.status(401).json({
				success: false,
				message: 'Token tidak valid atau role tidak sesuai',
			});
		}

		console.log('User:', user);
		console.log('User ID:', user._id);

		const company = await Company.findOne({ userId: user._id });
		console.log('Company found:', company);

		if (!company) {
			return res.status(404).json({
				success: false,
				message: 'Profil perusahaan tidak ditemukan',
			});
		}

		const page = parseInt(req.query.page) || 1;
		const limit = parseInt(req.query.limit) || 10;
		const skip = (page - 1) * limit;

		const jobs = await Job.find({ companyId: company._id })
			.populate('companyId', 'companyName logo')
			.sort({ createdAt: -1 })
			.skip(skip)
			.limit(limit);

		const total = await Job.countDocuments({ companyId: company._id });

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
		console.error('Get company jobs error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

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
// @desc    Get applications for a specific job (Company only)
// @access  Private (Company only)
router.get(
	'/:id/applications',
	[auth, requireRole(['company'])],
	async (req, res) => {
		try {
			const company = await Company.findOne({ userId: req.user._id });
			if (!company) {
				return res.status(404).json({
					success: false,
					message: 'Profil perusahaan tidak ditemukan',
				});
			}

			const job = await Job.findOne({
				_id: req.params.id,
				companyId: company._id,
			});

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

module.exports = router;
