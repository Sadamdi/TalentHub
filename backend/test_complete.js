const http = require('http');
const fs = require('fs');
const path = require('path');

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

async function testCompleteSystem() {
	console.log('🚀 Testing Complete Application System');
	console.log('=' .repeat(60));

	let adminToken = null;
	let talentToken = null;
	let jobId = null;
	let applicationId = null;
	let uploadedFileName = null;

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
				title: 'Complete Test Job - ' + new Date().toISOString(),
				description: 'This job was created by complete test script',
				requirements: ['Testing knowledge', 'Problem solving', 'System integration'],
				responsibilities: ['Test features', 'Report bugs', 'Document processes'],
				salary: { amount: 12000000, currency: 'IDR', period: 'monthly' },
				location: 'Jakarta',
				jobType: 'full_time',
				category: 'developer',
				experienceLevel: '3-5_years',
				skills: ['Testing', 'Quality Assurance', 'Documentation'],
				benefits: ['Health insurance', 'Annual bonus', 'Remote work'],
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
					title: 'Complete Test Job (Updated)',
					location: 'Bandung',
					salary: { amount: 15000000, currency: 'IDR', period: 'monthly' }
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

				// Test 12: Create a dummy CV file for upload test
				console.log('\n📋 TEST 12: Create Dummy CV File');
				const dummyCVPath = path.join(__dirname, 'dummy_cv.txt');
				fs.writeFileSync(dummyCVPath, 'This is a dummy CV file for testing purposes.\n\nName: John Doe\nEmail: john.doe@example.com\nPhone: +6281234567890\nExperience: 3 years in software development\nSkills: Flutter, Dart, Firebase, REST API\n\nThis file will be uploaded to test the file upload functionality.');

				// Test 13: Upload CV file
				console.log('\n📋 TEST 13: Upload CV File');
				const uploadResponse = await makeRequest('POST', `${BASE_URL}/file/upload`, {
					'cv': 'dummy_cv.txt'
				}, {
					Authorization: `Bearer ${talentToken}`,
					'Content-Type': 'multipart/form-data',
				});

				if (uploadResponse?.success && uploadResponse?.data?.fileName) {
					uploadedFileName = uploadResponse.data.fileName;
					console.log(`✅ CV file uploaded: ${uploadedFileName}`);

					// Test 14: Apply for job with complete data including CV
					console.log('\n📋 TEST 14: Apply for Job with Complete Data');
					const applyData = {
						jobId: testJobId,
						fullName: 'John Doe',
						email: 'john.doe@example.com',
						phone: '+6281234567890',
						coverLetter: 'I am very interested in this position and would like to apply. I have extensive experience in software development and am confident I can contribute to your team.',
						experienceYears: '3',
						skills: ['Flutter', 'Dart', 'Firebase', 'REST API', 'Git'],
						resumeUrl: uploadedFileName
					};

					const applyResponse = await makeRequest('POST', `${BASE_URL}/applications`, applyData, {
						Authorization: `Bearer ${talentToken}`,
					});

					if (applyResponse?.success) {
						applicationId = applyResponse.data?.application?._id;
						console.log(`✅ Application submitted successfully: ${applicationId}`);

						// Test 15: Get user's applications (should show CV info)
						console.log('\n📋 TEST 15: Get User Applications');
						const applicationsResponse = await makeRequest('GET', `${BASE_URL}/applications/me`, null, {
							Authorization: `Bearer ${talentToken}`,
						});

						if (applicationsResponse?.success) {
							console.log(`✅ Applications loaded successfully: ${applicationsResponse.data?.applications?.length || 0} applications`);
							const latestApp = applicationsResponse.data?.applications?.[0];
							if (latestApp) {
								console.log(`✅ Latest application has CV: ${latestApp.resumeFileName || 'No CV'}`);
							}
						}

						// Test 16: Get chat conversations (should have chat room created)
						console.log('\n📋 TEST 16: Get Chat Conversations');
						const chatResponse = await makeRequest('GET', `${BASE_URL}/chat/conversations`, null, {
							Authorization: `Bearer ${talentToken}`,
						});

						// Test 17: Company updates application status
						console.log('\n📋 TEST 17: Company Updates Application Status');
						if (applicationId) {
							await makeRequest('PUT', `${BASE_URL}/applications/${applicationId}/status`, {
								status: 'reviewed',
								notes: 'Application reviewed and moved to next stage',
								feedback: 'Good qualifications, CV looks promising'
							}, {
								Authorization: `Bearer ${adminToken}`,
							});

							// Test 18: Get application with status history
							console.log('\n📋 TEST 18: Get Application with Status History');
							const appDetailResponse = await makeRequest('GET', `${BASE_URL}/applications/me`, null, {
								Authorization: `Bearer ${talentToken}`,
							});

							if (appDetailResponse?.data?.applications?.[0]?.statusHistory) {
								console.log(`✅ Application has status history: ${appDetailResponse.data.applications[0].statusHistory.length} entries`);
							}

							// Test 19: Delete application
							console.log('\n📋 TEST 19: Delete Application');
							await makeRequest('DELETE', `${BASE_URL}/applications/${applicationId}`, null, {
								Authorization: `Bearer ${talentToken}`,
							});
						}
					}
				} else {
					console.log('❌ CV file upload failed');
				}

				// Clean up dummy file
				if (fs.existsSync(dummyCVPath)) {
					fs.unlinkSync(dummyCVPath);
					console.log('🧹 Cleaned up dummy CV file');
				}

			} else {
				console.log('❌ No jobs available for apply test');
			}

		} else {
			console.log('❌ Talent login failed');
		}

	} catch (error) {
		console.error('❌ Test error:', error.message);
	}

	console.log('\n' + '='.repeat(60));
	console.log('🏁 All Tests Completed');
	console.log('=' .repeat(60));
}

// Run the tests
testCompleteSystem().catch(console.error);
