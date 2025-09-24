const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

const BASE_URL = 'http://43.157.211.134/:2550/api';

async function debugCVIssue() {
	console.log('🔍 Debugging CV Upload & Download Issue');
	console.log('=====================================\n');

	try {
		// 1. Login as talent
		console.log('🔐 Step 1: Login as talent...');
		const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
			email: '3@gmail.com',
			password: '12345678',
		});

		const talentToken = loginResponse.data.data.token;
		const authHeaders = { Authorization: `Bearer ${talentToken}` };
		console.log('✅ Talent login successful');

		// 2. Check existing applications
		console.log('\n📋 Step 2: Check existing applications...');
		const appsResponse = await axios.get(`${BASE_URL}/applications`, {
			headers: authHeaders,
		});

		const applications = appsResponse.data.data?.applications || [];
		console.log(`Found ${applications.length} existing applications`);

		applications.forEach((app) => {
			console.log(`- App ID: ${app._id}`);
			console.log(`  Job: ${app.jobTitle || 'Unknown'}`);
			console.log(`  Status: ${app.status}`);
			console.log(`  Resume URL: ${app.resumeUrl || 'No CV'}`);
			console.log(`  Has CV file: ${app.resumeUrl ? 'Yes' : 'No'}`);
			console.log('');
		});

		if (applications.length > 0) {
			// 3. Test CV download for existing application
			console.log('\n⬇️ Step 3: Test CV download for existing application...');
			const appWithCV = applications.find((app) => app.resumeUrl);

			if (appWithCV) {
				console.log(`Testing download for application: ${appWithCV._id}`);
				console.log(`Resume URL: ${appWithCV.resumeUrl}`);

				// Login as company to test download
				console.log('\n🏢 Logging in as company...');
				const companyLogin = await axios.post(`${BASE_URL}/auth/login`, {
					email: 'perusahaan@demo.com',
					password: '12345678',
				});

				const companyHeaders = {
					Authorization: `Bearer ${companyLogin.data.data.token}`,
				};

				try {
					const downloadResponse = await axios.get(
						`${BASE_URL}/applications/${appWithCV._id}/cv`,
						{
							headers: companyHeaders,
						}
					);

					console.log('✅ CV download successful!');
					console.log(`Response status: ${downloadResponse.status}`);
				} catch (downloadError) {
					console.log('❌ CV download failed:');
					console.log(`Status: ${downloadError.response?.status}`);
					console.log(
						`Error: ${
							downloadError.response?.data?.message || downloadError.message
						}`
					);

					// Check if file exists on server
					console.log('\n🔍 Checking server file system...');
					const serverCheck = await axios.get(
						`${BASE_URL}/admin/cleanup/status`,
						{
							headers: companyHeaders,
						}
					);
					console.log('Server accessible, checking file manually...');
				}
			} else {
				console.log('❌ No applications with CV found');
			}
		}

		// 4. Test fresh upload
		console.log('\n📤 Step 4: Test fresh CV upload...');

		// Create test CV file
		const testCV = 'test-cv-content.txt';
		fs.writeFileSync(
			testCV,
			'This is a test CV file for debugging upload/download flow.'
		);

		const formData = new FormData();
		formData.append('cv', fs.createReadStream(testCV));

		try {
			const uploadResponse = await axios.post(
				`${BASE_URL}/file/upload`,
				formData,
				{
					headers: {
						...authHeaders,
						...formData.getHeaders(),
					},
				}
			);

			console.log('✅ CV upload successful!');
			console.log('Upload response:', uploadResponse.data);

			const uploadedFileName = uploadResponse.data.data.fileName;
			console.log(`Uploaded filename: ${uploadedFileName}`);

			// Now test application with this CV
			console.log('\n📝 Step 5: Test application with uploaded CV...');

			// Get available jobs
			const jobsResponse = await axios.get(`${BASE_URL}/jobs`, {
				headers: authHeaders,
			});

			if (jobsResponse.data.data.jobs.length > 0) {
				const testJob = jobsResponse.data.data.jobs[0];

				const applicationData = {
					jobId: testJob._id,
					fullName: 'Debug Test User',
					email: 'talent@demo.com',
					phone: '+6281234567890',
					coverLetter: 'Debug test application',
					resumeUrl: uploadedFileName,
				};

				const applyResponse = await axios.post(
					`${BASE_URL}/applications`,
					applicationData,
					{
						headers: authHeaders,
					}
				);

				console.log('✅ Application with CV submitted!');
				console.log('Application ID:', applyResponse.data.data.application._id);

				// Test download immediately
				console.log('\n⬇️ Step 6: Test immediate CV download...');
				const newAppId = applyResponse.data.data.application._id;

				const companyLogin = await axios.post(`${BASE_URL}/auth/login`, {
					email: 'perusahaan@demo.com',
					password: '12345678',
				});

				const companyHeaders = {
					Authorization: `Bearer ${companyLogin.data.data.token}`,
				};

				const downloadResponse = await axios.get(
					`${BASE_URL}/applications/${newAppId}/cv`,
					{
						headers: companyHeaders,
					}
				);

				console.log('✅ Fresh CV download successful!');
				console.log(`Download status: ${downloadResponse.status}`);
			} else {
				console.log('❌ No jobs available for testing');
			}
		} catch (uploadError) {
			console.log('❌ CV upload failed:');
			console.log(`Status: ${uploadError.response?.status}`);
			console.log(
				`Error: ${uploadError.response?.data?.message || uploadError.message}`
			);
		}

		// Cleanup
		try {
			fs.unlinkSync(testCV);
		} catch (e) {
			// Ignore cleanup errors
		}
	} catch (error) {
		console.error('❌ Debug error:', error.response?.data || error.message);
	}

	console.log('\n🏁 CV debug completed!');
}

debugCVIssue().catch(console.error);
