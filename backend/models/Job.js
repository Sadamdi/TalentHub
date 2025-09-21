const mongoose = require('mongoose');

const jobSchema = new mongoose.Schema({
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true
  },
  title: {
    type: String,
    required: [true, 'Judul pekerjaan diperlukan'],
    trim: true
  },
  description: {
    type: String,
    required: [true, 'Deskripsi pekerjaan diperlukan']
  },
  requirements: [{
    type: String,
    trim: true
  }],
  responsibilities: [{
    type: String,
    trim: true
  }],
  salary: {
    amount: {
      type: Number,
      required: [true, 'Gaji diperlukan']
    },
    currency: {
      type: String,
      default: 'USD'
    },
    period: {
      type: String,
      enum: ['hourly', 'monthly', 'yearly'],
      default: 'monthly'
    }
  },
  location: {
    type: String,
    required: [true, 'Lokasi pekerjaan diperlukan'],
    trim: true
  },
  jobType: {
    type: String,
    enum: ['full_time', 'part_time', 'contract', 'internship', 'freelance'],
    default: 'full_time'
  },
  category: {
    type: String,
    required: [true, 'Kategori pekerjaan diperlukan'],
    enum: ['designer', 'writer', 'finance', 'developer', 'marketing', 'sales', 'other'],
    trim: true
  },
  experienceLevel: {
    type: String,
    enum: ['fresh_graduate', '1-2_years', '3-5_years', '5+_years'],
    required: [true, 'Level pengalaman diperlukan']
  },
  skills: [{
    type: String,
    trim: true
  }],
  benefits: [{
    type: String,
    trim: true
  }],
  applicationDeadline: {
    type: Date
  },
  isActive: {
    type: Boolean,
    default: true
  },
  applicationCount: {
    type: Number,
    default: 0
  },
  views: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update timestamp
jobSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Index untuk pencarian
jobSchema.index({ title: 'text', description: 'text', location: 'text' });
jobSchema.index({ isActive: 1, createdAt: -1 });

module.exports = mongoose.model('Job', jobSchema);


