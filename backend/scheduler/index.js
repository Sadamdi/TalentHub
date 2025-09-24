const cron = require('node-cron');
const ApplicationCleanup = require('../utils/cleanup');

class Scheduler {
	/**
	 * Initialize all scheduled tasks
	 */
	static init() {
		console.log('⏰ Initializing scheduler...');

		// Run cleanup every day at 2:00 AM
		cron.schedule(
			'0 2 * * *',
			async () => {
				console.log('🕐 Running daily application cleanup at 2:00 AM...');
				try {
					const result = await ApplicationCleanup.cleanupApplications();
					console.log('✅ Scheduled cleanup completed:', result);
				} catch (error) {
					console.error('❌ Scheduled cleanup failed:', error);
				}
			},
			{
				timezone: 'Asia/Jakarta',
			}
		);

		// Run cleanup every 6 hours (for more frequent cleanup)
		cron.schedule(
			'0 */6 * * *',
			async () => {
				console.log('🕕 Running 6-hourly application cleanup...');
				try {
					const result = await ApplicationCleanup.cleanupApplications();
					console.log('✅ 6-hourly cleanup completed:', result);
				} catch (error) {
					console.error('❌ 6-hourly cleanup failed:', error);
				}
			},
			{
				timezone: 'Asia/Jakarta',
			}
		);

		console.log('✅ Scheduler initialized successfully');
		console.log('📅 Scheduled tasks:');
		console.log('   - Daily cleanup: Every day at 2:00 AM');
		console.log('   - 6-hourly cleanup: Every 6 hours');
	}

	/**
	 * Run cleanup manually (for testing)
	 */
	static async runCleanupNow() {
		console.log('🚀 Running manual cleanup...');
		return await ApplicationCleanup.cleanupApplications();
	}

	/**
	 * Preview what would be cleaned up
	 */
	static async previewCleanup() {
		console.log('👁️ Previewing cleanup...');
		return await ApplicationCleanup.previewCleanup();
	}
}

module.exports = Scheduler;
