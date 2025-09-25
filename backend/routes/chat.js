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
		console.log(
			'🔍 GET Chat: Received request for applicationId:',
			req.params.applicationId
		);
		console.log('👤 GET Chat: User role:', req.user.role);
		console.log('🆔 GET Chat: User ID:', req.user._id);

		const { role, _id: userId } = req.user;
		const { applicationId } = req.params;

		// Verify user has access to this application
		console.log('🔍 GET Chat: Looking for application:', applicationId);
		const application = await Application.findById(applicationId)
			.populate('talentId', 'userId')
			.populate('companyId', 'userId');

		if (!application) {
			console.log('❌ GET Chat: Application not found:', applicationId);
			return res.status(404).json({
				success: false,
				message: 'Lamaran tidak ditemukan',
			});
		}

		console.log('✅ GET Chat: Application found:', application._id);
		console.log('👥 GET Chat: Talent ID:', application.talentId?.userId);
		console.log('🏢 GET Chat: Company ID:', application.companyId?.userId);

		// FIXED: Company should only access their own applications, like talent
		const hasAccess =
			(role === 'talent' &&
				application.talentId.userId.toString() === userId.toString()) ||
			(role === 'company' &&
				application.companyId.userId.toString() === userId.toString()) ||
			role === 'admin'; // Admin can access any chat

		console.log(
			'🔐 GET Chat: Access check - Role:',
			role,
			'Has access:',
			hasAccess
		);
		console.log(
			'🔍 GET Chat: Talent match:',
			role === 'talent' &&
				application.talentId.userId.toString() === userId.toString()
		);
		console.log(
			'🔍 GET Chat: Company match:',
			role === 'company' &&
				application.companyId.userId.toString() === userId.toString()
		);

		if (!hasAccess) {
			console.log(
				'❌ GET Chat: Access denied for user:',
				userId,
				'role:',
				role
			);
			return res.status(403).json({
				success: false,
				message: 'Akses ditolak',
			});
		}

		console.log('💬 GET Chat: Finding chat for application:', applicationId);
		let chat = await Chat.findOne({ applicationId })
			.populate('talentId', 'firstName lastName email')
			.populate('companyId', 'firstName lastName email');

		if (!chat) {
			console.log(
				'📝 GET Chat: Creating new chat for application:',
				applicationId
			);
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
			console.log('✅ GET Chat: New chat created:', chat._id);
		} else {
			console.log('✅ GET Chat: Found existing chat:', chat._id);
			console.log(
				'📊 GET Chat: Chat has',
				chat.messages?.length || 0,
				'messages'
			);
		}

		// Mark messages as read
		if (role === 'talent') {
			chat.talentUnreadCount = 0;
			console.log('📊 GET Chat: Reset talent unread count');
		} else {
			chat.companyUnreadCount = 0;
			console.log('📊 GET Chat: Reset company unread count');
		}
		await chat.save();

		console.log(
			'📤 GET Chat: Sending chat response with',
			chat.messages?.length || 0,
			'messages'
		);
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
			console.log('🚀 Chat: Received send message request');
			console.log('👤 Chat: User role:', req.user.role);
			console.log('🆔 Chat: User ID:', req.user._id);
			console.log('📧 Chat: Application ID:', req.params.applicationId);
			console.log('💬 Chat: Message:', req.body.message);

			const errors = validationResult(req);
			if (!errors.isEmpty()) {
				console.log('❌ Chat: Validation errors:', errors.array());
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
			console.log('🔍 Chat: Looking for application:', applicationId);
			const application = await Application.findById(applicationId)
				.populate('talentId', 'userId')
				.populate('companyId', 'userId');

			if (!application) {
				console.log('❌ Chat: Application not found:', applicationId);
				return res.status(404).json({
					success: false,
					message: 'Lamaran tidak ditemukan',
				});
			}

			console.log('✅ Chat: Application found:', application._id);
			console.log('👥 Chat: Talent ID:', application.talentId?.userId);
			console.log('🏢 Chat: Company ID:', application.companyId?.userId);

			const hasAccess =
				(role === 'talent' &&
					application.talentId.userId.toString() === userId.toString()) ||
				role === 'company' || // Company can access any chat now
				role === 'admin'; // Admin can access any chat

			console.log(
				'🔐 Chat: Access check - Role:',
				role,
				'Has access:',
				hasAccess
			);

			if (!hasAccess) {
				console.log('❌ Chat: Access denied for user:', userId, 'role:', role);
				return res.status(403).json({
					success: false,
					message: 'Akses ditolak',
				});
			}

			console.log('💬 Chat: Finding chat for application:', applicationId);
			let chat = await Chat.findOne({ applicationId });

			if (!chat) {
				console.log(
					'📝 Chat: Creating new chat for application:',
					applicationId
				);
				// Create new chat if doesn't exist
				chat = new Chat({
					applicationId,
					talentId: application.talentId.userId,
					companyId: application.companyId.userId,
					messages: [],
					talentUnreadCount: 0,
					companyUnreadCount: 0,
				});
			} else {
				console.log('✅ Chat: Found existing chat:', chat._id);
			}

			// Add new message
			const newMessage = {
				senderId: userId,
				senderRole: role,
				message: message,
				timestamp: new Date(),
				isRead: false,
			};

			console.log('📨 Chat: Adding new message:', newMessage);
			chat.messages.push(newMessage);
			chat.lastMessage = message;
			chat.lastMessageTime = new Date();

			// Update unread count
			if (role === 'talent') {
				chat.companyUnreadCount += 1;
				console.log('📊 Chat: Updated company unread count');
			} else {
				chat.talentUnreadCount += 1;
				console.log('📊 Chat: Updated talent unread count');
			}

			console.log('💾 Chat: Saving chat...');
			await chat.save();
			console.log('✅ Chat: Chat saved successfully');

			// Populate the new message
			console.log('🔗 Chat: Populating message data...');
			await chat.populate('messages.senderId', 'firstName lastName email');

			const responseMessage = chat.messages[chat.messages.length - 1];
			console.log(
				'📤 Chat: Sending response with message:',
				responseMessage._id
			);

			res.json({
				success: true,
				message: 'Pesan berhasil dikirim',
				data: {
					message: responseMessage,
				},
			});
		} catch (error) {
			console.error('❌ Chat: Send message error:', error);
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
