const express = require('express');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Talent = require('../models/Talent');
const Company = require('../models/Company');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Generate JWT token
const generateToken = (userId) => {
	return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

// @route   POST /api/auth/register
// @desc    Register user baru
// @access  Public
router.post(
	'/register',
	[
		body('firstName').notEmpty().withMessage('Nama depan diperlukan'),
		body('lastName').notEmpty().withMessage('Nama belakang diperlukan'),
		body('email').isEmail().normalizeEmail().withMessage('Email tidak valid'),
		body('password')
			.isLength({ min: 6 })
			.withMessage('Password minimal 6 karakter'),
		body('role')
			.optional()
			.isIn(['talent', 'company'])
			.withMessage('Role harus talent atau company'),
		body('location')
			.optional()
			.isString()
			.withMessage('Lokasi harus berupa string'),
		body('phoneNumber')
			.optional()
			.isString()
			.withMessage('Nomor telepon harus berupa string'),
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
				firstName,
				lastName,
				email,
				password,
				role = 'talent', // Default to talent if not provided
				location,
				phoneNumber,
			} = req.body;

			// Cek apakah email sudah terdaftar
			const existingUser = await User.findOne({ email });
			if (existingUser) {
				return res.status(400).json({
					success: false,
					message: 'Email sudah terdaftar',
				});
			}

			// Buat user baru
			const user = new User({
				firstName,
				lastName,
				email,
				password,
				role,
				location,
				phoneNumber,
			});
			await user.save();

			// Buat profil sesuai role
			if (role === 'talent') {
				const talent = new Talent({
					userId: user._id,
					name: `${firstName} ${lastName}`,
					description: 'Deskripsi belum diisi',
				});
				await talent.save();
			} else if (role === 'company') {
				const company = new Company({
					userId: user._id,
					companyName: `${firstName} ${lastName}`,
					description: 'Deskripsi perusahaan belum diisi',
				});
				await company.save();
			}

			// Generate token
			const token = generateToken(user._id);

			res.status(201).json({
				success: true,
				message: 'Registrasi berhasil',
				data: {
					token,
					user: {
						id: user._id,
						firstName: user.firstName,
						lastName: user.lastName,
						email: user.email,
						role: user.role,
						location: user.location,
						phoneNumber: user.phoneNumber,
					},
				},
			});
		} catch (error) {
			console.error('Register error:', error);
			res.status(500).json({
				success: false,
				message: 'Terjadi kesalahan pada server',
			});
		}
	}
);

// @route   POST /api/auth/login
// @desc    Login user
// @access  Public
router.post(
	'/login',
	[
		body('email').isEmail().normalizeEmail().withMessage('Email tidak valid'),
		body('password').notEmpty().withMessage('Password diperlukan'),
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

			const { email, password } = req.body;

			// Cari user
			const user = await User.findOne({ email });
			if (!user) {
				return res.status(401).json({
					success: false,
					message: 'Email atau password salah',
				});
			}

			// Cek password
			const isPasswordValid = await user.comparePassword(password);
			if (!isPasswordValid) {
				return res.status(401).json({
					success: false,
					message: 'Email atau password salah',
				});
			}

			// Cek status aktif
			if (!user.isActive) {
				return res.status(401).json({
					success: false,
					message: 'Akun tidak aktif',
				});
			}

			// Generate token
			const token = generateToken(user._id);

			res.json({
				success: true,
				message: 'Login berhasil',
				data: {
					token,
					user: {
						id: user._id,
						firstName: user.firstName,
						lastName: user.lastName,
						email: user.email,
						role: user.role,
						location: user.location,
						phoneNumber: user.phoneNumber,
						profilePicture: user.profilePicture,
					},
				},
			});
		} catch (error) {
			console.error('Login error:', error);
			res.status(500).json({
				success: false,
				message: 'Terjadi kesalahan pada server',
			});
		}
	}
);

// @route   POST /api/auth/google
// @desc    Google Sign In
// @access  Public
router.post('/google', async (req, res) => {
	try {
		const { email, firstName, lastName, googleId, accessToken, idToken } =
			req.body;

		// Cari user berdasarkan email atau googleId
		let user = await User.findOne({
			$or: [{ email }, { googleId }],
		});

		let isNewUser = false;

		if (!user) {
			// Buat user baru jika belum ada
			isNewUser = true;
			user = new User({
				firstName,
				lastName,
				email,
				password: googleId, // Password default untuk Google Sign In
				role: 'talent', // Default role untuk Google Sign In
				googleId,
				isGoogleAccount: true,
			});
			await user.save();

			// Buat profil talent
			const talent = new Talent({
				userId: user._id,
				name: `${firstName} ${lastName}`,
				description: 'Deskripsi belum diisi',
			});
			await talent.save();
		} else {
			// Update googleId jika belum ada
			if (!user.googleId) {
				user.googleId = googleId;
				user.isGoogleAccount = true;
				await user.save();
			}
		}

		// Generate token
		const token = generateToken(user._id);

		res.status(isNewUser ? 201 : 200).json({
			success: true,
			message: isNewUser
				? 'Registrasi Google berhasil'
				: 'Login Google berhasil',
			data: {
				token,
				user: {
					id: user._id,
					firstName: user.firstName,
					lastName: user.lastName,
					email: user.email,
					role: user.role,
					location: user.location,
					phoneNumber: user.phoneNumber,
					profilePicture: user.profilePicture,
				},
			},
		});
	} catch (error) {
		console.error('Google Sign In error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   GET /api/auth/me
// @desc    Get current user info
// @access  Private
router.get('/me', auth, async (req, res) => {
	try {
		const user = await User.findById(req.user._id).select('-password');

		if (!user) {
			return res.status(404).json({
				success: false,
				message: 'Pengguna tidak ditemukan',
			});
		}

		res.json({
			success: true,
			data: {
				user: {
					id: user._id,
					firstName: user.firstName,
					lastName: user.lastName,
					email: user.email,
					role: user.role,
					location: user.location,
					phoneNumber: user.phoneNumber,
					profilePicture: user.profilePicture,
					createdAt: user.createdAt,
				},
			},
		});
	} catch (error) {
		console.error('Get user error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

module.exports = router;
