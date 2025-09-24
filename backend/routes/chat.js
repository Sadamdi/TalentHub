const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth, requireRole } = require('../middleware/auth');
const Chat = require('../models/Chat');
const Application = require('../models/Application');
const User = require('../models/User');

const router = express.Router();

// @route   GET /api/chat/conversations
// @desc    Get user's chat conversations
// @access  Private (Talent or Company)
router.get('/conversations', auth, async (req, res) => {
	try {
		const { role, _id: userId } = req.user;

		let chats;
		if (role === 'talent') {
			chats = await Chat.find({ talentId: userId })
				.populate('companyId', 'firstName lastName email')
				.populate('applicationId', 'jobId')
				.sort({ lastMessageTime: -1 });
		} else if (role === 'company') {
			// Company can see all chats (not just their own)
			chats = await Chat.find({})
				.populate('talentId', 'firstName lastName email')
				.populate('companyId', 'firstName lastName email')
				.populate('applicationId', 'jobId')
				.sort({ lastMessageTime: -1 });
		}

		// Mark messages as read
		if (chats && chats.length > 0) {
			for (const chat of chats) {
				await Chat.updateOne(
					{ _id: chat._id },
					{
						$set: {
							lastMessageTime: chat.lastMessageTime,
						},
						$inc:
							role === 'talent'
								? { companyUnreadCount: 0 }
								: { talentUnreadCount: 0 },
					}
				);
			}
		}

		res.json({
			success: true,
			data: { chats },
		});
	} catch (error) {
		console.error('Get conversations error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   GET /api/chat/:applicationId
// @desc    Get chat for specific application
// @access  Private (Talent or Company)
router.get('/:applicationId', auth, async (req, res) => {
	try {
		const { role, _id: userId } = req.user;
		const { applicationId } = req.params;

		// Verify user has access to this application
		const application = await Application.findById(applicationId)
			.populate('talentId', 'userId')
			.populate('companyId', 'userId');

		if (!application) {
			return res.status(404).json({
				success: false,
				message: 'Lamaran tidak ditemukan',
			});
		}

		const hasAccess =
			(role === 'talent' &&
				application.talentId.userId.toString() === userId.toString()) ||
			role === 'company'; // Company can access any chat now

		if (!hasAccess) {
			return res.status(403).json({
				success: false,
				message: 'Akses ditolak',
			});
		}

		let chat = await Chat.findOne({ applicationId })
			.populate('talentId', 'firstName lastName email')
			.populate('companyId', 'firstName lastName email');

		if (!chat) {
			// Create new chat if doesn't exist
			chat = new Chat({
				applicationId,
				talentId: application.talentId.userId,
				companyId: application.companyId.userId,
				messages: [],
				talentUnreadCount: 0,
				companyUnreadCount: 0,
			});
			await chat.save();
		}

		// Mark messages as read
		if (role === 'talent') {
			chat.talentUnreadCount = 0;
		} else {
			chat.companyUnreadCount = 0;
		}
		await chat.save();

		res.json({
			success: true,
			data: { chat },
		});
	} catch (error) {
		console.error('Get chat error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

// @route   POST /api/chat/:applicationId/messages
// @desc    Send message in chat
// @access  Private (Talent or Company)
router.post(
	'/:applicationId/messages',
	[auth, body('message').notEmpty().withMessage('Pesan tidak boleh kosong')],
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

			const { role, _id: userId } = req.user;
			const { applicationId } = req.params;
			const { message } = req.body;

			// Verify user has access to this application
			const application = await Application.findById(applicationId)
				.populate('talentId', 'userId')
				.populate('companyId', 'userId');

			if (!application) {
				return res.status(404).json({
					success: false,
					message: 'Lamaran tidak ditemukan',
				});
			}

			const hasAccess =
				(role === 'talent' &&
					application.talentId.userId.toString() === userId.toString()) ||
				role === 'company'; // Company can access any chat now

			if (!hasAccess) {
				return res.status(403).json({
					success: false,
					message: 'Akses ditolak',
				});
			}

			let chat = await Chat.findOne({ applicationId });

			if (!chat) {
				// Create new chat if doesn't exist
				chat = new Chat({
					applicationId,
					talentId: application.talentId.userId,
					companyId: application.companyId.userId,
					messages: [],
					talentUnreadCount: 0,
					companyUnreadCount: 0,
				});
			}

			// Add new message
			const newMessage = {
				senderId: userId,
				senderRole: role,
				message: message,
				timestamp: new Date(),
				isRead: false,
			};

			chat.messages.push(newMessage);
			chat.lastMessage = message;
			chat.lastMessageTime = new Date();

			// Update unread count
			if (role === 'talent') {
				chat.companyUnreadCount += 1;
			} else {
				chat.talentUnreadCount += 1;
			}

			await chat.save();

			// Populate the new message
			await chat.populate('messages.senderId', 'firstName lastName email');

			res.json({
				success: true,
				message: 'Pesan berhasil dikirim',
				data: {
					message: chat.messages[chat.messages.length - 1],
				},
			});
		} catch (error) {
			console.error('Send message error:', error);
			res.status(500).json({
				success: false,
				message: 'Terjadi kesalahan pada server',
			});
		}
	}
);

// @route   PATCH /api/chat/:applicationId/read
// @desc    Mark messages as read
// @access  Private (Talent or Company)
router.patch('/:applicationId/read', auth, async (req, res) => {
	try {
		const { role, _id: userId } = req.user;
		const { applicationId } = req.params;

		const chat = await Chat.findOne({ applicationId });
		if (!chat) {
			return res.status(404).json({
				success: false,
				message: 'Chat tidak ditemukan',
			});
		}

		// Mark messages as read
		if (role === 'talent') {
			chat.talentUnreadCount = 0;
		} else {
			chat.companyUnreadCount = 0;
		}

		await chat.save();

		res.json({
			success: true,
			message: 'Pesan ditandai sudah dibaca',
		});
	} catch (error) {
		console.error('Mark as read error:', error);
		res.status(500).json({
			success: false,
			message: 'Terjadi kesalahan pada server',
		});
	}
});

module.exports = router;
