const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Load environment variables
dotenv.config({ path: './config.env' });

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Configure multer for global file uploads
const storage = multer.diskStorage({
	destination: function (req, file, cb) {
		const uploadDir = path.join(__dirname, 'uploads', 'applications');

		// Create directory if it doesn't exist
		if (!fs.existsSync(uploadDir)) {
			fs.mkdirSync(uploadDir, { recursive: true });
		}

		cb(null, uploadDir);
	},
	filename: function (req, file, cb) {
		// Generate unique filename with timestamp
		const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
		const ext = path.extname(file.originalname);
		const basename = path.basename(file.originalname, ext);

		cb(null, `${basename}-${uniqueSuffix}${ext}`);
	},
});

const upload = multer({
	storage: storage,
	limits: {
		fileSize: 10 * 1024 * 1024, // 10MB limit
	},
	fileFilter: function (req, file, cb) {
		// Allow all file types for CV
		const allowedTypes = [
			// Documents
			'.pdf',
			'.doc',
			'.docx',
			'.txt',
			'.rtf',
			'.odt',
			// Images
			'.jpg',
			'.jpeg',
			'.png',
			'.gif',
			// Others
			'.wpd',
		];

		const ext = path.extname(file.originalname).toLowerCase();

		if (allowedTypes.includes(ext)) {
			cb(null, true);
		} else {
			cb(new Error('File type not supported'), false);
		}
	},
});

// Global multer middleware for all routes
app.use(upload.any());

// Serve uploaded files statically
app.use('/uploads', express.static('uploads'));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/profile', require('./routes/profile'));
app.use('/api/jobs', require('./routes/jobs'));
app.use('/api/applications', require('./routes/applications'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/chat', require('./routes/chat'));
app.use('/api/file', require('./routes/file'));

// Error handling middleware
app.use((err, req, res, next) => {
	console.error(err.stack);
	res.status(500).json({
		success: false,
		message: 'Terjadi kesalahan pada server',
	});
});

// 404 handler
app.use('*', (req, res) => {
	res.status(404).json({
		success: false,
		message: 'Endpoint tidak ditemukan',
	});
});

// Connect to MongoDB
mongoose
	.connect(process.env.MONGODB_URI, {
		useNewUrlParser: true,
		useUnifiedTopology: true,
	})
	.then(() => {
		console.log('✅ Terhubung ke MongoDB');
	})
	.catch((err) => {
		console.error('❌ Error koneksi MongoDB:', err);
		process.exit(1);
	});

// Initialize scheduler for automatic cleanup
const Scheduler = require('./scheduler');
Scheduler.init();

const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
	console.log(`🚀 Server berjalan di port ${PORT}`);
	console.log(`📱 Akses dari HP: http://[IP_ADDRESS]:${PORT}`);
	console.log(`🧹 Application cleanup scheduler is active`);
});

module.exports = app;
