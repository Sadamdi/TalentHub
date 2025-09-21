const mongoose = require('mongoose');

const applicationSchema = new mongoose.Schema({
	talentId: {
		type: mongoose.Schema.Types.ObjectId,
		ref: 'Talent',
		required: true,
	},
	jobId: {
		type: mongoose.Schema.Types.ObjectId,
		ref: 'Job',
		required: true,
	},
	companyId: {
		type: mongoose.Schema.Types.ObjectId,
		ref: 'Company',
		required: true,
	},
	status: {
		type: String,
		enum: ['pending', 'reviewed', 'interview', 'hired', 'rejected'],
		default: 'pending',
	},
	coverLetter: {
		type: String,
		maxlength: [1000, 'Cover letter maksimal 1000 karakter'],
	},
	resumeUrl: {
		type: String,
	},
	appliedAt: {
		type: Date,
		default: Date.now,
	},
	reviewedAt: {
		type: Date,
	},
	interviewScheduledAt: {
		type: Date,
	},
	notes: {
		type: String,
	},
	// Feedback dari perusahaan
	feedback: {
		type: String,
	},
	createdAt: {
		type: Date,
		default: Date.now,
	},
	updatedAt: {
		type: Date,
		default: Date.now,
	},
});

// Update timestamp
applicationSchema.pre('save', function (next) {
	this.updatedAt = Date.now();
	next();
});

// Index untuk performa query
applicationSchema.index({ talentId: 1, appliedAt: -1 });
applicationSchema.index({ jobId: 1, status: 1 });
applicationSchema.index({ companyId: 1, status: 1 });

// Compound index untuk mencegah duplikasi lamaran
applicationSchema.index({ talentId: 1, jobId: 1 }, { unique: true });

module.exports = mongoose.model('Application', applicationSchema);
