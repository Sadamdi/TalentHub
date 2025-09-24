const axios = require('axios');

const BASE_URL = 'http://43.157.211.134:2550/api';
const EMAIL = 'perusahaan@demo.com';
const PASSWORD = '12345678';

let authToken = '';

// Helper function to make authenticated requests
const api = axios.create({
	baseURL: BASE_URL,
	timeout: 10000,
});

// Add token to requests
api.interceptors.request.use((config) => {
	if (authToken) {
		config.headers.Authorization = `Bearer ${authToken}`;
	}
	return config;
});

// Test login
async function testLogin() {
	console.log('\n🔐 Testing Login...');
	try {
		const response = await api.post('/auth/login', {
			email: EMAIL,
			password: PASSWORD,
		});

		if (response.data.success) {
			authToken = response.data.data.token;
			console.log('✅ Login successful');
			console.log('👤 User:', {
				id: response.data.data.user.id,
				email: response.data.data.user.email,
				role: response.data.data.user.role,
				firstName: response.data.data.user.firstName,
				lastName: response.data.data.user.lastName,
			});
			return true;
		} else {
			console.log('❌ Login failed:', response.data.message);
			return false;
		}
	} catch (error) {
		console.log('❌ Login error:', error.response?.data || error.message);
		return false;
	}
}

// Test get current user
async function testGetCurrentUser() {
	console.log('\n👤 Testing Get Current User...');
	try {
		const response = await api.get('/auth/me');
		console.log('✅ Current user:', response.data.data.user);
		return response.data.data.user;
	} catch (error) {
		console.log(
			'❌ Get current user error:',
			error.response?.data || error.message
		);
		return null;
	}
}

// Test company jobs endpoint
async function testCompanyJobs() {
	console.log('\n💼 Testing Company Jobs Endpoint...');
	try {
		const response = await api.get('/jobs/company-jobs');
		console.log('✅ Company Jobs Response Status:', response.status);
		console.log('📄 Response Data:', JSON.stringify(response.data, null, 2));

		if (response.data.success && response.data.data.jobs) {
			console.log(`📊 Found ${response.data.data.jobs.length} jobs`);
			response.data.data.jobs.forEach((job, index) => {
				console.log(
					`  Job ${index + 1}: ${job.title} (ID: ${job._id || job.id})`
				);
			});
		} else {
			console.log('⚠️ No jobs found or unexpected response structure');
		}
		return response.data;
	} catch (error) {
		console.log(
			'❌ Company jobs error:',
			error.response?.data || error.message
		);
		return null;
	}
}

// Test company applications endpoint
async function testCompanyApplications() {
	console.log('\n📝 Testing Company Applications Endpoint...');
	try {
		const response = await api.get('/applications/company');
		console.log('✅ Company Applications Response Status:', response.status);
		console.log('📄 Response Data:', JSON.stringify(response.data, null, 2));

		if (response.data.success && response.data.data.applications) {
			console.log(
				`📊 Found ${response.data.data.applications.length} applications`
			);
			response.data.data.applications.forEach((app, index) => {
				console.log(
					`  Application ${index + 1}: ${app.jobId?.title || 'Unknown Job'} - ${
						app.status
					}`
				);
			});
		} else {
			console.log('⚠️ No applications found or unexpected response structure');
		}
		return response.data;
	} catch (error) {
		console.log(
			'❌ Company applications error:',
			error.response?.data || error.message
		);
		return null;
	}
}

// Test chat conversations endpoint
async function testChatConversations() {
	console.log('\n💬 Testing Chat Conversations Endpoint...');
	try {
		const response = await api.get('/chat/conversations');
		console.log('✅ Chat Conversations Response Status:', response.status);
		console.log('📄 Response Data:', JSON.stringify(response.data, null, 2));

		if (response.data.success && response.data.data.chats) {
			console.log(
				`📊 Found ${response.data.data.chats.length} chat conversations`
			);
			response.data.data.chats.forEach((chat, index) => {
				console.log(
					`  Chat ${index + 1}: Application ${chat.applicationId} - Last: ${
						chat.lastMessage || 'No messages'
					}`
				);
			});
		} else {
			console.log('⚠️ No chats found or unexpected response structure');
		}
		return response.data;
	} catch (error) {
		console.log(
			'❌ Chat conversations error:',
			error.response?.data || error.message
		);
		return null;
	}
}

// Test debug endpoint
async function testDebugCompanyData() {
	console.log('\n🔍 Testing Debug Company Data Endpoint...');
	try {
		const response = await api.get('/jobs/debug/company-data');
		console.log('✅ Debug Response Status:', response.status);
		console.log('📄 Debug Data:', JSON.stringify(response.data, null, 2));
		return response.data;
	} catch (error) {
		console.log('❌ Debug error:', error.response?.data || error.message);
		return null;
	}
}

// Test fix company data endpoint
async function testFixCompanyData() {
	console.log('\n🔧 Testing Fix Company Data Endpoint...');
	try {
		const response = await api.post('/jobs/debug/fix-company-data');
		console.log('✅ Fix Response Status:', response.status);
		console.log('📄 Fix Data:', JSON.stringify(response.data, null, 2));
		return response.data;
	} catch (error) {
		console.log('❌ Fix error:', error.response?.data || error.message);
		return null;
	}
}

// Test update application status
async function testUpdateApplicationStatus() {
	console.log('\n📝 Testing Update Application Status...');
	try {
		// First get applications to find one to update
		const appsResponse = await api.get('/applications/company');
		if (
			appsResponse.data.success &&
			appsResponse.data.data.applications.length > 0
		) {
			const firstApp = appsResponse.data.data.applications[0];
			console.log(
				`📝 Attempting to update application ${
					firstApp._id || firstApp.id
				} status to 'reviewed'`
			);

			const response = await api.put(
				`/applications/${firstApp._id || firstApp.id}/status`,
				{
					status: 'reviewed',
					notes: 'Test status update from script',
				}
			);

			console.log('✅ Update Application Status Response:', response.status);
			console.log('📄 Response Data:', JSON.stringify(response.data, null, 2));
			return response.data;
		} else {
			console.log('⚠️ No applications found to update');
			return null;
		}
	} catch (error) {
		console.log(
			'❌ Update application status error:',
			error.response?.data || error.message
		);
		return null;
	}
}

// Main test function
async function runAllTests() {
	console.log('🚀 Starting Company Endpoint Tests');
	console.log('=====================================');

	// Test login first
	const loginSuccess = await testLogin();
	if (!loginSuccess) {
		console.log('❌ Cannot proceed without login');
		return;
	}

	// Test all endpoints
	await testGetCurrentUser();
	await testDebugCompanyData();
	await testFixCompanyData();
	await testCompanyJobs();
	await testCompanyApplications();
	await testChatConversations();
	await testUpdateApplicationStatus();

	console.log('\n🏁 All tests completed!');
	console.log('=====================================');
}

// Run the tests
runAllTests().catch(console.error);
