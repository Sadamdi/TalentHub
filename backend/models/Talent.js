const mongoose = require('mongoose');

const portfolioItemSchema = new mongoose.Schema({
  url: {
    type: String,
    required: [true, 'URL portofolio diperlukan']
  },
  caption: {
    type: String,
    required: [true, 'Caption portofolio diperlukan']
  },
  mediaType: {
    type: String,
    enum: ['image', 'video', 'link'],
    required: [true, 'Tipe media diperlukan']
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const talentSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: [true, 'Nama diperlukan'],
    trim: true
  },
  description: {
    type: String,
    required: [true, 'Deskripsi diperlukan'],
    maxlength: [500, 'Deskripsi maksimal 500 karakter']
  },
  phone: {
    type: String,
    trim: true
  },
  location: {
    type: String,
    trim: true
  },
  portfolio: [portfolioItemSchema],
  skills: [{
    type: String,
    trim: true
  }],
  experience: {
    type: String,
    enum: ['fresh_graduate', '1-2_years', '3-5_years', '5+_years'],
    default: 'fresh_graduate'
  },
  education: {
    degree: String,
    institution: String,
    year: Number
  },
  resumeUrl: {
    type: String
  },
  profilePicture: {
    type: String
  },
  isProfileComplete: {
    type: Boolean,
    default: false
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
talentSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Talent', talentSchema);

