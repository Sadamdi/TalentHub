const jwt = require('jsonwebtoken');
const User = require('../models/User');

const auth = async (req, res, next) => {
	try {
		const token = req.header('Authorization')?.replace('Bearer ', '');

		if (!token) {
			return res.status(401).json({
				success: false,
				message: 'Token akses diperlukan',
			});
		}

		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const user = await User.findById(decoded.userId).select('-password');

		if (!user || !user.isActive) {
			return res.status(401).json({
				success: false,
				message: 'Token tidak valid atau pengguna tidak aktif',
			});
		}

		req.user = user;
		next();
	} catch (error) {
		console.error('Auth middleware error:', error);
		res.status(401).json({
			success: false,
			message: 'Token tidak valid',
		});
	}
};

// Middleware untuk memeriksa role
const requireRole = (roles) => {
	return (req, res, next) => {
		if (!req.user) {
			return res.status(401).json({
				success: false,
				message: 'Autentikasi diperlukan',
			});
		}

		if (!roles.includes(req.user.role)) {
			return res.status(403).json({
				success: false,
				message: 'Akses ditolak. Role tidak sesuai',
			});
		}

		next();
	};
};

// Middleware untuk memeriksa admin role
const requireAdmin = (req, res, next) => {
	if (!req.user) {
		return res.status(401).json({
			success: false,
			message: 'Autentikasi diperlukan',
		});
	}

	if (req.user.role !== 'admin') {
		return res.status(403).json({
			success: false,
			message: 'Akses admin diperlukan',
		});
	}

	next();
};

module.exports = { auth, requireRole, requireAdmin };
