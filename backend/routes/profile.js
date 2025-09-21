const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, requireRole } = require('../middleware/auth');
const Talent = require('../models/Talent');
const Company = require('../models/Company');

const router = express.Router();

// @route   GET /api/profile/me
// @desc    Get current user profile
// @access  Private
router.get('/me', auth, async (req, res) => {
  try {
    let profile = null;

    if (req.user.role === 'talent') {
      profile = await Talent.findOne({ userId: req.user._id })
        .populate('userId', 'email createdAt');
    } else if (req.user.role === 'company') {
      profile = await Company.findOne({ userId: req.user._id })
        .populate('userId', 'email createdAt');
    }

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: 'Profil tidak ditemukan'
      });
    }

    res.json({
      success: true,
      data: { profile }
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server'
    });
  }
});

// @route   PUT /api/profile/talent
// @desc    Update talent profile
// @access  Private (Talent only)
router.put('/talent', [
  auth,
  requireRole(['talent']),
  body('name').optional().notEmpty().withMessage('Nama tidak boleh kosong'),
  body('description').optional().isLength({ max: 500 }).withMessage('Deskripsi maksimal 500 karakter'),
  body('phone').optional().isMobilePhone('id-ID').withMessage('Nomor telepon tidak valid'),
  body('location').optional().notEmpty().withMessage('Lokasi tidak boleh kosong'),
  body('experience').optional().isIn(['fresh_graduate', '1-2_years', '3-5_years', '5+_years']).withMessage('Level pengalaman tidak valid')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Data tidak valid',
        errors: errors.array()
      });
    }

    const talent = await Talent.findOne({ userId: req.user._id });
    if (!talent) {
      return res.status(404).json({
        success: false,
        message: 'Profil talent tidak ditemukan'
      });
    }

    // Update fields
    const allowedFields = ['name', 'description', 'phone', 'location', 'experience', 'education', 'resumeUrl', 'profilePicture'];
    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        talent[field] = req.body[field];
      }
    });

    // Check if profile is complete
    talent.isProfileComplete = !!(talent.name && talent.description && talent.skills.length > 0);

    await talent.save();

    res.json({
      success: true,
      message: 'Profil berhasil diperbarui',
      data: { talent }
    });

  } catch (error) {
    console.error('Update talent profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server'
    });
  }
});

// @route   PUT /api/profile/company
// @desc    Update company profile
// @access  Private (Company only)
router.put('/company', [
  auth,
  requireRole(['company']),
  body('companyName').optional().notEmpty().withMessage('Nama perusahaan tidak boleh kosong'),
  body('description').optional().isLength({ max: 1000 }).withMessage('Deskripsi maksimal 1000 karakter'),
  body('website').optional().isURL().withMessage('Website tidak valid'),
  body('phone').optional().isMobilePhone('id-ID').withMessage('Nomor telepon tidak valid')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Data tidak valid',
        errors: errors.array()
      });
    }

    const company = await Company.findOne({ userId: req.user._id });
    if (!company) {
      return res.status(404).json({
        success: false,
        message: 'Profil perusahaan tidak ditemukan'
      });
    }

    // Update fields
    const allowedFields = ['companyName', 'description', 'industry', 'website', 'phone', 'address', 'logo', 'companySize', 'foundedYear'];
    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        company[field] = req.body[field];
      }
    });

    await company.save();

    res.json({
      success: true,
      message: 'Profil perusahaan berhasil diperbarui',
      data: { company }
    });

  } catch (error) {
    console.error('Update company profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server'
    });
  }
});

// @route   POST /api/profile/talent/skills
// @desc    Add skill to talent profile
// @access  Private (Talent only)
router.post('/talent/skills', [
  auth,
  requireRole(['talent']),
  body('skill').notEmpty().withMessage('Skill tidak boleh kosong')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Data tidak valid',
        errors: errors.array()
      });
    }

    const talent = await Talent.findOne({ userId: req.user._id });
    if (!talent) {
      return res.status(404).json({
        success: false,
        message: 'Profil talent tidak ditemukan'
      });
    }

    const { skill } = req.body;
    
    // Cek apakah skill sudah ada
    if (talent.skills.includes(skill)) {
      return res.status(400).json({
        success: false,
        message: 'Skill sudah ada dalam profil'
      });
    }

    talent.skills.push(skill);
    await talent.save();

    res.json({
      success: true,
      message: 'Skill berhasil ditambahkan',
      data: { skills: talent.skills }
    });

  } catch (error) {
    console.error('Add skill error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server'
    });
  }
});

// @route   DELETE /api/profile/talent/skills/:skill
// @desc    Remove skill from talent profile
// @access  Private (Talent only)
router.delete('/talent/skills/:skill', [
  auth,
  requireRole(['talent'])
], async (req, res) => {
  try {
    const talent = await Talent.findOne({ userId: req.user._id });
    if (!talent) {
      return res.status(404).json({
        success: false,
        message: 'Profil talent tidak ditemukan'
      });
    }

    const { skill } = req.params;
    talent.skills = talent.skills.filter(s => s !== skill);
    await talent.save();

    res.json({
      success: true,
      message: 'Skill berhasil dihapus',
      data: { skills: talent.skills }
    });

  } catch (error) {
    console.error('Remove skill error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server'
    });
  }
});

// @route   POST /api/profile/talent/portfolio
// @desc    Add portfolio item to talent profile
// @access  Private (Talent only)
router.post('/talent/portfolio', [
  auth,
  requireRole(['talent']),
  body('url').isURL().withMessage('URL tidak valid'),
  body('caption').notEmpty().withMessage('Caption tidak boleh kosong'),
  body('mediaType').isIn(['image', 'video', 'link']).withMessage('Tipe media tidak valid')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Data tidak valid',
        errors: errors.array()
      });
    }

    const talent = await Talent.findOne({ userId: req.user._id });
    if (!talent) {
      return res.status(404).json({
        success: false,
        message: 'Profil talent tidak ditemukan'
      });
    }

    const { url, caption, mediaType } = req.body;
    
    talent.portfolio.push({ url, caption, mediaType });
    await talent.save();

    res.json({
      success: true,
      message: 'Portofolio berhasil ditambahkan',
      data: { portfolio: talent.portfolio }
    });

  } catch (error) {
    console.error('Add portfolio error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server'
    });
  }
});

// @route   DELETE /api/profile/talent/portfolio/:portfolioId
// @desc    Remove portfolio item from talent profile
// @access  Private (Talent only)
router.delete('/talent/portfolio/:portfolioId', [
  auth,
  requireRole(['talent'])
], async (req, res) => {
  try {
    const talent = await Talent.findOne({ userId: req.user._id });
    if (!talent) {
      return res.status(404).json({
        success: false,
        message: 'Profil talent tidak ditemukan'
      });
    }

    const { portfolioId } = req.params;
    talent.portfolio = talent.portfolio.filter(item => item._id.toString() !== portfolioId);
    await talent.save();

    res.json({
      success: true,
      message: 'Item portofolio berhasil dihapus',
      data: { portfolio: talent.portfolio }
    });

  } catch (error) {
    console.error('Remove portfolio error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server'
    });
  }
});

module.exports = router;

