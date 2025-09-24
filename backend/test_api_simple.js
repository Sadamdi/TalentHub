const http = require('http');

// Base URL for the API
const BASE_URL = 'http://43.157.211.134:2550/api';

// Helper function to make requests with logging
function makeRequest(method, url, data = null, headers = {}) {
	return new Promise((resolve, reject) => {
		const parsedUrl = new URL(url);

		const options = {
			hostname: parsedUrl.hostname,
			port: parsedUrl.port,
			path: parsedUrl.pathname + parsedUrl.search,
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

async function testAPIEndpoints() {
	console.log('🚀 Starting API Endpoint Tests');
	console.log('='.repeat(50));

	let adminToken = null;
	let jobId = null;

	try {
		// Test 1: Login as Admin (perusahaan@demo.com)
		console.log('\n📋 TEST 1: Login as Admin');
		const adminLogin = await makeRequest('POST', `${BASE_URL}/auth/login`, {
			email: 'perusahaan@demo.com',
			password: '12345678',
		});

		if (adminLogin?.data?.token) {
			adminToken = adminLogin.data.token;
			console.log('✅ Admin login successful');

			// Test 2: Get all jobs (admin view)
			console.log('\n📋 TEST 2: Get All Jobs (Admin View)');
			const jobsResponse = await makeRequest(
				'GET',
				`${BASE_URL}/admin/jobs`,
				null,
				{
					Authorization: `Bearer ${adminToken}`,
				}
			);

			if (jobsResponse?.data?.jobs?.length > 0) {
				jobId = jobsResponse.data.jobs[0]._id; // Take first job for testing
				console.log(`📌 Selected job for testing: ${jobId}`);

				// Test 3: Edit job
				console.log('\n📋 TEST 3: Edit Job');
				await makeRequest(
					'PUT',
					`${BASE_URL}/jobs/${jobId}`,
					{
						title: 'API Test Job (Updated)',
						location: 'Bandung',
					},
					{
						Authorization: `Bearer ${adminToken}`,
					}
				);

				// Test 4: Deactivate job
				console.log('\n📋 TEST 4: Deactivate Job');
				await makeRequest('DELETE', `${BASE_URL}/jobs/${jobId}`, null, {
					Authorization: `Bearer ${adminToken}`,
				});

				// Test 5: Get job applications (admin view)
				console.log('\n📋 TEST 5: Get Job Applications (Admin View)');
				await makeRequest(
					'GET',
					`${BASE_URL}/jobs/${jobId}/applications`,
					null,
					{
						Authorization: `Bearer ${adminToken}`,
					}
				);
			} else {
				console.log('❌ No jobs found for testing');
			}

			// Test 6: Create new job as admin
			console.log('\n📋 TEST 6: Create New Job as Admin');
			const newJobData = {
				title: 'API Test Job - ' + new Date().toISOString(),
				description: 'This job was created by API test script',
				requirements: ['Node.js knowledge', 'API testing experience'],
				responsibilities: ['Test API endpoints', 'Write test scripts'],
				salary: { amount: 8000000, currency: 'IDR', period: 'monthly' },
				location: 'Jakarta',
				jobType: 'full_time',
				category: 'developer',
				experienceLevel: '1-2_years',
				skills: ['Node.js', 'API Testing', 'JavaScript'],
				benefits: ['Health insurance', 'Remote work'],
				applicationDeadline: '2025-12-31T23:59:59.000Z',
			};

			const createJobResponse = await makeRequest(
				'POST',
				`${BASE_URL}/jobs`,
				newJobData,
				{
					Authorization: `Bearer ${adminToken}`,
				}
			);

			if (createJobResponse?.data?.job?._id) {
				const newJobId = createJobResponse.data.job._id;
				console.log(`✅ New job created successfully: ${newJobId}`);

				// Test 7: Get company jobs to verify job was added
				console.log('\n📋 TEST 7: Verify Job Was Added');
				const companyJobsResponse = await makeRequest(
					'GET',
					`${BASE_URL}/jobs/company-jobs`,
					null,
					{
						Authorization: `Bearer ${adminToken}`,
					}
				);

				if (companyJobsResponse?.data?.jobs) {
					const jobExists = companyJobsResponse.data.jobs.some(
						(job) => job._id === newJobId
					);
					console.log(`✅ Job found in company jobs: ${jobExists}`);
				}
			} else {
				console.log('❌ Failed to create job');
			}

			// Test 8: Get user profile
			console.log('\n📋 TEST 8: Get Current User Profile');
			await makeRequest('GET', `${BASE_URL}/profile/me`, null, {
				Authorization: `Bearer ${adminToken}`,
			});
		} else {
			console.log('❌ Admin login failed');
		}
	} catch (error) {
		console.error('❌ Test error:', error.message);
	}

	// Test 9: Login as Talent for apply job test
	console.log('\n📋 TEST 9: Login as Talent');
	const talentLogin = await makeRequest('POST', `${BASE_URL}/auth/login`, {
		email: '123@gmail.com',
		password: '12345678',
	});

	if (talentLogin?.data?.token) {
		const talentToken = talentLogin.data.token;
		console.log('✅ Talent login successful');

		// Test 10: Get user profile
		console.log('\n📋 TEST 10: Get Talent Profile');
		await makeRequest('GET', `${BASE_URL}/profile/me`, null, {
			Authorization: `Bearer ${talentToken}`,
		});

		// Test 11: Get jobs (public view)
		console.log('\n📋 TEST 11: Get Public Jobs');
		const publicJobsResponse = await makeRequest('GET', `${BASE_URL}/jobs`);

		if (publicJobsResponse?.data?.jobs?.length > 0) {
			const testJobId = publicJobsResponse.data.jobs[0]._id;
			console.log(`📌 Selected job for apply test: ${testJobId}`);

			// Test 12: Apply for job
			console.log('\n📋 TEST 12: Apply for Job');
			await makeRequest(
				'POST',
				`${BASE_URL}/applications`,
				{
					jobId: testJobId,
					coverLetter:
						'I am interested in this position and would like to apply.',
				},
				{
					Authorization: `Bearer ${talentToken}`,
				}
			);

			// Test 13: Get user's applications
			console.log('\n📋 TEST 13: Get User Applications');
			await makeRequest('GET', `${BASE_URL}/applications/me`, null, {
				Authorization: `Bearer ${talentToken}`,
			});
		} else {
			console.log('❌ No jobs available for apply test');
		}
	} else {
		console.log('❌ Talent login failed');
	}

	console.log('\n' + '='.repeat(50));
	console.log('🏁 API Endpoint Tests Completed');
	console.log('='.repeat(50));
}

// Run the tests
testAPIEndpoints();
