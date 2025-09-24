const Application = require('../models/Application');
const fs = require('fs');
const path = require('path');

class ApplicationCleanup {
	/**
	 * Clean up old applications based on status and time
	 */
	static async cleanupApplications() {
		console.log('🧹 Starting application cleanup...');

		try {
			const now = new Date();
			const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000); // 1 day ago
			const twoDaysAgo = new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000); // 2 days ago

			// Find applications to delete
			const applicationsToDelete = await Application.find({
				$or: [
					{
						// Applications that have been reviewed (hired/rejected) for more than 1 day
						status: { $in: ['hired', 'rejected'] },
						reviewedAt: { $lte: oneDayAgo },
					},
					{
						// Applications that are still pending/in review for more than 2 days
						status: { $in: ['pending', 'interview'] },
						createdAt: { $lte: twoDaysAgo },
					},
				],
			});

			console.log(
				`📋 Found ${applicationsToDelete.length} applications to cleanup`
			);

			let deletedCount = 0;
			let cvFilesDeleted = 0;

			for (const application of applicationsToDelete) {
				try {
					// Delete CV file if exists
					if (application.resumeUrl) {
						const cvPath = path.join(
							__dirname,
							'..',
							'uploads',
							'applications',
							path.basename(application.resumeUrl)
						);

						if (fs.existsSync(cvPath)) {
							fs.unlinkSync(cvPath);
							cvFilesDeleted++;
							console.log(`🗑️ Deleted CV file: ${application.resumeUrl}`);
						}
					}

					// Delete application from database
					await Application.findByIdAndDelete(application._id);
					deletedCount++;

					console.log(
						`✅ Deleted application ${application._id} (Status: ${
							application.status
						}, Age: ${this.getApplicationAge(application)} days)`
					);
				} catch (error) {
					console.error(
						`❌ Error deleting application ${application._id}:`,
						error
					);
				}
			}

			console.log(
				`🎉 Cleanup completed! Deleted ${deletedCount} applications and ${cvFilesDeleted} CV files`
			);

			return {
				success: true,
				deletedApplications: deletedCount,
				deletedCVFiles: cvFilesDeleted,
				message: `Cleanup completed. Deleted ${deletedCount} applications and ${cvFilesDeleted} CV files`,
			};
		} catch (error) {
			console.error('❌ Application cleanup error:', error);
			return {
				success: false,
				error: error.message,
			};
		}
	}

	/**
	 * Get application age in days
	 */
	static getApplicationAge(application) {
		const now = new Date();
		const createdAt = new Date(application.createdAt);
		const ageInMs = now.getTime() - createdAt.getTime();
		return Math.floor(ageInMs / (24 * 60 * 60 * 1000));
	}

	/**
	 * Get review age in days (for reviewed applications)
	 */
	static getReviewAge(application) {
		if (!application.reviewedAt) return null;

		const now = new Date();
		const reviewedAt = new Date(application.reviewedAt);
		const ageInMs = now.getTime() - reviewedAt.getTime();
		return Math.floor(ageInMs / (24 * 60 * 60 * 1000));
	}

	/**
	 * Preview applications that would be deleted (for testing)
	 */
	static async previewCleanup() {
		console.log('👀 Previewing applications that would be deleted...');

		try {
			const now = new Date();
			const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
			const twoDaysAgo = new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000);

			const applicationsToDelete = await Application.find({
				$or: [
					{
						status: { $in: ['hired', 'rejected'] },
						reviewedAt: { $lte: oneDayAgo },
					},
					{
						status: { $in: ['pending', 'interview'] },
						createdAt: { $lte: twoDaysAgo },
					},
				],
			})
				.populate('jobId', 'title')
				.populate('talentId', 'name');

			console.log(
				`📋 ${applicationsToDelete.length} applications would be deleted:`
			);

			applicationsToDelete.forEach((app) => {
				const age = this.getApplicationAge(app);
				const reviewAge = this.getReviewAge(app);

				console.log(`- ID: ${app._id}`);
				console.log(`  Status: ${app.status}`);
				console.log(`  Job: ${app.jobId?.title || 'Unknown'}`);
				console.log(`  Talent: ${app.talentId?.name || 'Unknown'}`);
				console.log(`  Age: ${age} days`);
				if (reviewAge !== null) console.log(`  Review Age: ${reviewAge} days`);
				console.log(`  Has CV: ${app.resumeUrl ? 'Yes' : 'No'}`);
				console.log('');
			});

			return applicationsToDelete;
		} catch (error) {
			console.error('❌ Preview cleanup error:', error);
			return [];
		}
	}

	/**
	 * Manual cleanup with confirmation (for admin use)
	 */
	static async manualCleanup(confirm = false) {
		if (!confirm) {
			console.log(
				'⚠️ Manual cleanup requires confirmation. Set confirm=true to proceed.'
			);
			return { success: false, message: 'Confirmation required' };
		}

		console.log('🔧 Running manual cleanup...');
		return await this.cleanupApplications();
	}
}

module.exports = ApplicationCleanup;
