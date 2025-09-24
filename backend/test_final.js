const http = require('http');

// Base URL for the API
const BASE_URL = 'http://43.157.211.134:2550/api';

// Helper function to make requests with logging
function makeRequest(method, url, data = null, headers = {}) {
	return new Promise((resolve, reject) => {
		const options = {
			hostname: '43.157.211.134',
			port: 2550,
			path: url,
			method: method.toUpperCase(),
			headers: {
				'Content-Type': 'application/json',
				...headers,
			},
		};

		console.log(`\n🔄 ${method.toUpperCase()} ${url}`);
		if (data) {
			console.log('📤 Request Data:', JSON.stringify(data, null, 2));
			options.headers['Content-Length'] = Buffer.byteLength(
				JSON.stringify(data)
			);
		}

		const req = http.request(options, (res) => {
			let responseData = '';

			res.on('data', (chunk) => {
				responseData += chunk;
			});

			res.on('end', () => {
				try {
					const parsedData = responseData ? JSON.parse(responseData) : {};
					console.log('✅ Response Status:', res.statusCode);
					console.log('📥 Response Data:', JSON.stringify(parsedData, null, 2));
					resolve(parsedData);
				} catch (e) {
					console.log('❌ Error parsing response:', e.message);
					resolve({ error: e.message, rawResponse: responseData });
				}
			});
		});

		req.on('error', (err) => {
			console.log('❌ Request Error:', err.message);
			reject(err);
		});

		if (data) {
			req.write(JSON.stringify(data));
		}

		req.end();
	});
}

async function testAllFeatures() {
	console.log('🚀 Testing All Fixed Features');
	console.log('=' .repeat(50));

	let adminToken = null;
	let talentToken = null;
	let jobId = null;
	let applicationId = null;

	try {
		// Test 1: Login as Admin
		console.log('\n📋 TEST 1: Admin Login');
		const adminLogin = await makeRequest('POST', `${BASE_URL}/auth/login`, {
			email: 'perusahaan@demo.com',
			password: '12345678',
		});

		if (adminLogin?.data?.token) {
			adminToken = adminLogin.data.token;
			console.log('✅ Admin login successful');

			// Test 2: Get Admin Profile
			console.log('\n📋 TEST 2: Get Admin Profile');
			await makeRequest('GET', `${BASE_URL}/profile/me`, null, {
				Authorization: `Bearer ${adminToken}`,
			});

			// Test 3: Get All Jobs (Admin View)
			console.log('\n📋 TEST 3: Get All Jobs (Admin View)');
			const jobsResponse = await makeRequest('GET', `${BASE_URL}/admin/jobs`, null, {
				Authorization: `Bearer ${adminToken}`,
			});

			if (jobsResponse?.data?.jobs?.length > 0) {
				jobId = jobsResponse.data.jobs[0]._id;
				console.log(`📌 Selected job for testing: ${jobId}`);
			}

			// Test 4: Get Company Jobs (Admin View) - Should show ALL jobs
			console.log('\n📋 TEST 4: Get Company Jobs (Admin View)');
			const companyJobsResponse = await makeRequest('GET', `${BASE_URL}/jobs/company-jobs`, null, {
				Authorization: `Bearer ${adminToken}`,
			});

			if (companyJobsResponse?.success) {
				console.log(`✅ Admin can see ${companyJobsResponse.data?.jobs?.length || 0} jobs (should be all jobs)`);
			}

			// Test 5: Create new job as admin
			console.log('\n📋 TEST 5: Create New Job as Admin');
			const newJobData = {
				title: 'Final Test Job - ' + new Date().toISOString(),
				description: 'This job was created by final test script',
				requirements: ['Testing knowledge', 'Problem solving'],
				responsibilities: ['Test features', 'Report bugs'],
				salary: { amount: 10000000, currency: 'IDR', period: 'monthly' },
				location: 'Jakarta',
				jobType: 'full_time',
				category: 'developer',
				experienceLevel: '1-2_years',
				skills: ['Testing', 'Quality Assurance'],
				benefits: ['Health insurance', 'Annual bonus'],
				applicationDeadline: '2025-12-31T23:59:59.000Z'
			};

			const createJobResponse = await makeRequest('POST', `${BASE_URL}/jobs`, newJobData, {
				Authorization: `Bearer ${adminToken}`,
			});

			if (createJobResponse?.data?.job?._id) {
				const newJobId = createJobResponse.data.job._id;
				console.log(`✅ New job created: ${newJobId}`);

				// Test 6: Edit job
				console.log('\n📋 TEST 6: Edit Job');
				await makeRequest('PUT', `${BASE_URL}/jobs/${newJobId}`, {
					title: 'Final Test Job (Updated)',
					location: 'Bandung'
				}, {
					Authorization: `Bearer ${adminToken}`,
				});

				// Test 7: Deactivate job
				console.log('\n📋 TEST 7: Deactivate Job');
				await makeRequest('DELETE', `${BASE_URL}/jobs/${newJobId}`, null, {
					Authorization: `Bearer ${adminToken}`,
				});

				// Test 8: Get job applications (admin view)
				console.log('\n📋 TEST 8: Get Job Applications (Admin View)');
				await makeRequest('GET', `${BASE_URL}/jobs/${jobId}/applications`, null, {
					Authorization: `Bearer ${adminToken}`,
				});
			}

		} else {
			console.log('❌ Admin login failed');
		}

		// Test 9: Login as Talent
		console.log('\n📋 TEST 9: Talent Login');
		const talentLogin = await makeRequest('POST', `${BASE_URL}/auth/login`, {
			email: '123@gmail.com',
			password: '12345678',
		});

		if (talentLogin?.data?.token) {
			talentToken = talentLogin.data.token;
			console.log('✅ Talent login successful');

			// Test 10: Get Talent Profile
			console.log('\n📋 TEST 10: Get Talent Profile');
			await makeRequest('GET', `${BASE_URL}/profile/me`, null, {
				Authorization: `Bearer ${talentToken}`,
			});

			// Test 11: Get public jobs
			console.log('\n📋 TEST 11: Get Public Jobs');
			const publicJobsResponse = await makeRequest('GET', `${BASE_URL}/jobs`);

			if (publicJobsResponse?.data?.jobs?.length > 0) {
				const testJobId = publicJobsResponse.data.jobs[0]._id;
				console.log(`📌 Selected job for apply test: ${testJobId}`);

				// Test 12: Apply for job with complete data
				console.log('\n📋 TEST 12: Apply for Job with Complete Data');
				const applyData = {
					jobId: testJobId,
					fullName: 'John Doe',
					email: 'john.doe@example.com',
					phone: '+6281234567890',
					coverLetter: 'I am very interested in this position and would like to apply. I have 3 years of experience in software development.',
					experienceYears: '3',
					skills: ['JavaScript', 'React', 'Node.js', 'MongoDB'],
					resumeUrl: 'https://example.com/resume.pdf'
				};

				await makeRequest('POST', `${BASE_URL}/applications`, applyData, {
					Authorization: `Bearer ${talentToken}`,
				});

				// Test 13: Get user's applications (should not have parsing error)
				console.log('\n📋 TEST 13: Get User Applications');
				const applicationsResponse = await makeRequest('GET', `${BASE_URL}/applications/me`, null, {
					Authorization: `Bearer ${talentToken}`,
				});

				if (applicationsResponse?.success) {
					console.log(`✅ Applications loaded successfully: ${applicationsResponse.data?.applications?.length || 0} applications`);
				}

				// Test 14: Get conversations (should have chat room created)
				console.log('\n📋 TEST 14: Get Chat Conversations');
				await makeRequest('GET', `${BASE_URL}/chat/conversations`, null, {
					Authorization: `Bearer ${talentToken}`,
				});

			} else {
				console.log('❌ No jobs available for apply test');
			}

		} else {
			console.log('❌ Talent login failed');
		}

	} catch (error) {
		console.error('❌ Test error:', error.message);
	}

	console.log('\n' + '='.repeat(50));
	console.log('🏁 All Tests Completed');
	console.log('=' .repeat(50));
}

// Run the tests
testAllFeatures().catch(console.error);
