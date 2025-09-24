const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

async function checkDatabase() {
	try {
		await mongoose.connect(process.env.MONGODB_URI);
		console.log('✅ Connected to MongoDB');

		const User = require('./models/User');
		const Job = require('./models/Job');
		const Company = require('./models/Company');
		const Application = require('./models/Application');

		// Check user perusahaan@demo.com
		console.log('\n=== CHECKING USER ===');
		const user = await User.findOne({ email: 'perusahaan@demo.com' }).select(
			'-password'
		);
		if (user) {
			console.log('User found:', {
				_id: user._id,
				email: user.email,
				role: user.role,
				isActive: user.isActive,
			});
		} else {
			console.log('❌ User perusahaan@demo.com not found');
		}

		// Check all jobs
		console.log('\n=== CHECKING JOBS ===');
		const jobs = await Job.find({}).populate('companyId', 'companyName');
		console.log(`Total jobs: ${jobs.length}`);
		jobs.forEach((job, index) => {
			console.log(`${index + 1}. ${job.title} (${job._id})`);
			console.log(`   Company: ${job.companyId?.companyName || 'No company'}`);
			console.log(`   Location: ${job.location}`);
			console.log(`   Active: ${job.isActive}`);
			console.log(`   Created: ${job.createdAt}`);
			console.log('---');
		});

		// Check company profiles
		console.log('\n=== CHECKING COMPANY PROFILES ===');
		const companies = await Company.find({});
		console.log(`Total companies: ${companies.length}`);
		companies.forEach((company, index) => {
			console.log(`${index + 1}. ${company.companyName} (${company._id})`);
			console.log(`   User ID: ${company.userId}`);
			console.log(`   Industry: ${company.industry}`);
			console.log('---');
		});

		// Check applications
		console.log('\n=== CHECKING APPLICATIONS ===');
		const applications = await Application.find({});
		console.log(`Total applications: ${applications.length}`);

		await mongoose.connection.close();
		console.log('\n✅ Database check completed');
	} catch (error) {
		console.error('❌ Error checking database:', error);
	}
}

checkDatabase();
