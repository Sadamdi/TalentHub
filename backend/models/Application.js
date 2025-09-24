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
		enum: [
			'pending',
			'reviewed',
			'interview',
			'hired',
			'rejected',
			'cancelled',
		],
		default: 'pending',
	},
	coverLetter: {
		type: String,
		maxlength: [1000, 'Cover letter maksimal 1000 karakter'],
	},
	resumeUrl: {
		type: String,
	},
	resumeFileName: {
		type: String,
	},
	resumeFileSize: {
		type: Number,
	},
	resumeFileType: {
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
	// Status history tracking
	statusHistory: [
		{
			status: {
				type: String,
				enum: [
					'pending',
					'reviewed',
					'interview',
					'hired',
					'rejected',
					'cancelled',
				],
			},
			changedAt: {
				type: Date,
				default: Date.now,
			},
			changedBy: {
				type: mongoose.Schema.Types.ObjectId,
				ref: 'User',
			},
			notes: {
				type: String,
				default: '',
			},
		},
	],
	// File deletion tracking
	fileDeleted: {
		type: Boolean,
		default: false,
	},
	fileDeletedAt: {
		type: Date,
	},
	fileDeletedBy: {
		type: mongoose.Schema.Types.ObjectId,
		ref: 'User',
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

// Track status history
applicationSchema.pre('save', function (next) {
	// If status is being changed, add to history
	if (this.isModified('status') && !this.isNew) {
		this.statusHistory.push({
			status: this.status,
			changedAt: new Date(),
			changedBy: null, // Will be set by controller
			notes: `Status changed to ${this.status}`,
		});
	}

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
