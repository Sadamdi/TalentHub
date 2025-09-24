import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late final Dio _dio;
  late final FlutterSecureStorage _storage;

  static const String baseUrl = 'http://43.157.211.134:2550/api';

  ApiService() {
    _storage = const FlutterSecureStorage();

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      // Let us inspect 4xx responses instead of throwing, we'll handle them downstream
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // Detailed logging for debugging
        // ignore: avoid_print
        print('=== API REQUEST ===');
        // ignore: avoid_print
        print('[API] → ${options.method} ${options.uri}');
        // ignore: avoid_print
        print('[API] Headers: ${options.headers}');
        // ignore: avoid_print
        print('[API] Data: ${options.data}');
        // ignore: avoid_print
        print('[API] Query: ${options.queryParameters}');
        // ignore: avoid_print
        print('===================');
        handler.next(options);
      },
      onError: (error, handler) {
        // Detailed error logging
        // ignore: avoid_print
        print('=== API ERROR ===');
        // ignore: avoid_print
        print(
            '[API] ⨯ ${error.requestOptions.method} ${error.requestOptions.uri}');
        // ignore: avoid_print
        print('[API] Status: ${error.response?.statusCode}');
        // ignore: avoid_print
        print('[API] Response: ${error.response?.data}');
        // ignore: avoid_print
        print('[API] Message: ${error.message}');
        // ignore: avoid_print
        print('=================');
        handler.next(error);
      },
    ));

    // Add a general logger for requests/responses (trim bodies to keep logs readable)
    _dio.interceptors.add(LogInterceptor(
      request: false,
      requestHeader: false,
      requestBody: true,
      responseHeader: false,
      responseBody: false,
      error: true,
    ));
  }

  // Token management
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> removeToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Auth endpoints
  Future<Response> login(Map<String, dynamic> data) async {
    return await _dio.post('/auth/login', data: data);
  }

  Future<Response> register(Map<String, dynamic> data) async {
    return await _dio.post('/auth/register', data: data);
  }

  Future<Response> getCurrentUser() async {
    return await _dio.get('/auth/me');
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await _dio.put('/auth/profile', data: data);
  }

  Future<Response> googleSignIn(Map<String, dynamic> data) async {
    return await _dio.post('/auth/google', data: data);
  }

  // Job endpoints
  Future<Response> getJobs({
    int page = 1,
    String? search,
    String? category,
    String? location,
    String? sort,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': 10,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (category != null && category.isNotEmpty && category != 'all') {
      queryParams['category'] = category;
    }
    if (location != null && location.isNotEmpty) {
      queryParams['location'] = location;
    }
    if (sort != null && sort.isNotEmpty) {
      queryParams['sort'] = sort;
    }

    return await _dio.get('/jobs', queryParameters: queryParams);
  }

  Future<Response> getJob(String jobId) async {
    return await _dio.get('/jobs/$jobId');
  }

  Future<Response> getCompanyJobs() async {
    return await _dio.get('/jobs/company-jobs');
  }

  Future<Response> createJob(Map<String, dynamic> data) async {
    await ensureCompanyProfile();
    return await _dio.post('/jobs', data: data);
  }

  Future<Response> updateJob(String jobId, Map<String, dynamic> data) async {
    return await _dio.put('/jobs/$jobId', data: data);
  }

  Future<Response> deleteJob(String jobId) async {
    return await _dio.delete('/jobs/$jobId');
  }

  Future<Response> getJobRecommendations({
    String category = 'all',
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };

    if (category != 'all') {
      queryParams['category'] = category;
    }

    return await _dio.get('/jobs/recommendations',
        queryParameters: queryParams);
  }

  // Application endpoints
  Future<Response> getApplications() async {
    return await _dio.get('/applications/me');
  }

  Future<Response> getCompanyApplications() async {
    return await _dio.get('/applications/company');
  }

  Future<Response> getApplicationsByJobId(String jobId) async {
    return await _dio.get('/applications/job/$jobId');
  }

  Future<Response> getApplication(String applicationId) async {
    return await _dio.get('/applications/$applicationId');
  }

  // Apply for job - try common endpoint patterns
  Future<Response> applyForJob(Map<String, dynamic> data) async {
    // Try /applications first (original)
    try {
      print('ApiService: Trying /applications endpoint');
      return await _dio.post('/applications', data: data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Try alternative endpoints if 404
        final jobId = data['jobId'];
        if (jobId != null) {
          // Try /jobs/{jobId}/apply (correct backend endpoint)
          try {
            print('ApiService: Trying /jobs/$jobId/apply endpoint');
            return await _dio.post('/jobs/$jobId/apply', data: data);
          } on DioException catch (_) {
            // Try /jobs/{jobId}/applications as fallback
            try {
              print('ApiService: Trying /jobs/$jobId/applications endpoint');
              return await _dio.post('/jobs/$jobId/applications', data: data);
            } on DioException catch (_) {
              // Try /applications/apply/{jobId} as last resort
              print('ApiService: Trying /applications/apply/$jobId endpoint');
              return await _dio.post('/applications/apply/$jobId', data: data);
            }
          }
        }
      }
      rethrow;
    }
  }

  // Apply with CV upload (multipart) - try common endpoint patterns
  Future<Response> uploadFile(File file) async {
    try {
      final formData = FormData.fromMap({
        'cv': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });

      print('ApiService: Uploading file to /file/upload');
      return await _dio.post('/file/upload', data: formData);
    } catch (e) {
      print('ApiService: File upload error: $e');
      rethrow;
    }
  }

  Future<Response> updateApplicationStatus({
    required String applicationId,
    required String status,
    String? notes,
    String? feedback,
  }) async {
    try {
      print(
          'ApiService: Updating application status: $applicationId to $status');
      return await _dio.put(
        '/applications/$applicationId/status',
        data: {
          'status': status,
          'notes': notes,
          'feedback': feedback,
        },
      );
    } catch (e) {
      print('ApiService: Update application status error: $e');
      rethrow;
    }
  }

  Future<Response> deleteApplication(String applicationId) async {
    try {
      print('ApiService: Deleting application: $applicationId');
      return await _dio.delete('/applications/$applicationId');
    } catch (e) {
      print('ApiService: Delete application error: $e');
      rethrow;
    }
  }

  Future<Response> getChatConversations() async {
    try {
      print('ApiService: Getting chat conversations');
      return await _dio.get('/chat/conversations');
    } catch (e) {
      print('ApiService: Get chat conversations error: $e');
      rethrow;
    }
  }

  Future<Response> getChatByApplicationId(String applicationId) async {
    try {
      print('ApiService: Getting chat for application: $applicationId');
      return await _dio.get('/chat/$applicationId');
    } catch (e) {
      print('ApiService: Get chat by application error: $e');
      rethrow;
    }
  }

  Future<Response> sendChatMessage(
      String applicationId, String message, String? senderRole) async {
    try {
      print(
          'ApiService: Sending message to application: $applicationId with role: $senderRole');

      final data = {'message': message};
      if (senderRole != null) {
        data['senderRole'] = senderRole;
      }

      return await _dio.post('/chat/$applicationId/messages', data: data);
    } catch (e) {
      print('ApiService: Send chat message error: $e');
      rethrow;
    }
  }

  Future<Response> downloadCv(String applicationId) async {
    try {
      print('ApiService: Downloading CV for application: $applicationId');
      return await _dio.get('/applications/$applicationId/cv');
    } catch (e) {
      print('ApiService: Download CV error: $e');
      rethrow;
    }
  }

  // Debug and fix company data
  Future<Response> debugCompanyData() async {
    try {
      print('ApiService: Debug company data');
      return await _dio.get('/jobs/debug/company-data');
    } catch (e) {
      print('ApiService: Debug company data error: $e');
      rethrow;
    }
  }

  Future<Response> fixCompanyData() async {
    try {
      print('ApiService: Fix company data');
      return await _dio.post('/jobs/debug/fix-company-data');
    } catch (e) {
      print('ApiService: Fix company data error: $e');
      rethrow;
    }
  }

  Future<Response> applyForJobWithFile({
    required Map<String, dynamic> data,
    File? cvFile,
  }) async {
    final formMap = <String, dynamic>{...data};
    if (cvFile != null) {
      final fileName = cvFile.path.split(Platform.pathSeparator).last;
      formMap['cv'] = await MultipartFile.fromFile(
        cvFile.path,
        filename: fileName,
      );
    }
    final formData = FormData.fromMap(formMap);

    // Try /applications first (original)
    try {
      print('ApiService: Trying /applications endpoint (with file)');
      return await _dio.post('/applications', data: formData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Try alternative endpoints if 404
        final jobId = data['jobId'];
        if (jobId != null) {
          // Try /jobs/{jobId}/apply (correct backend endpoint)
          try {
            print('ApiService: Trying /jobs/$jobId/apply endpoint (with file)');
            return await _dio.post('/jobs/$jobId/apply', data: formData);
          } on DioException catch (_) {
            // Try /jobs/{jobId}/applications as fallback
            try {
              print(
                  'ApiService: Trying /jobs/$jobId/applications endpoint (with file)');
              return await _dio.post('/jobs/$jobId/applications',
                  data: formData);
            } on DioException catch (_) {
              // Try /applications/apply/{jobId} as last resort
              print(
                  'ApiService: Trying /applications/apply/$jobId endpoint (with file)');
              return await _dio.post('/applications/apply/$jobId',
                  data: formData);
            }
          }
        }
      }
      rethrow;
    }
  }

  // Company endpoints
  Future<Response> getCompanyProfile() async {
    return await _dio.get('/company/profile');
  }

  Future<Response> updateCompanyProfile(Map<String, dynamic> data) async {
    return await _dio.put('/company/profile', data: data);
  }

  Future<Response> createCompanyProfile(Map<String, dynamic> data) async {
    return await _dio.post('/company/profile', data: data);
  }

  // Ensure company profile exists for current user. If missing, create minimal placeholder.
  Future<void> ensureCompanyProfile() async {
    try {
      await getCompanyProfile();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final minimalProfile = <String, dynamic>{
          'companyName': 'Demo Company',
          'industry': 'Demo',
          'description': 'Demo company for testing',
          'website': 'https://demo.com',
          'location': 'Jakarta',
          'size': '1-10',
        };
        try {
          await createCompanyProfile(minimalProfile);
        } on DioException catch (e2) {
          // If POST fails, try PUT as fallback
          await updateCompanyProfile(minimalProfile);
        }
      } else {
        rethrow;
      }
    }
  }

  // Talent endpoints
  Future<Response> getTalentProfile() async {
    return await _dio.get('/talent/profile');
  }

  Future<Response> updateTalentProfile(Map<String, dynamic> data) async {
    return await _dio.put('/talent/profile', data: data);
  }

  // Admin endpoints - for managing all jobs and applications (requires admin role)
  Future<Response> getAllJobs({
    int page = 1,
    String? search,
    String? category,
    String? location,
    String? sort,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': 50, // Higher limit for admin view
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (category != null && category.isNotEmpty && category != 'all') {
      queryParams['category'] = category;
    }
    if (location != null && location.isNotEmpty) {
      queryParams['location'] = location;
    }
    if (sort != null && sort.isNotEmpty) {
      queryParams['sort'] = sort;
    }

    return await _dio.get('/admin/jobs', queryParameters: queryParams);
  }

  Future<Response> adminUpdateJob(
      String jobId, Map<String, dynamic> data) async {
    return await _dio.put('/admin/jobs/$jobId', data: data);
  }

  Future<Response> adminDeleteJob(String jobId) async {
    return await _dio.delete('/admin/jobs/$jobId');
  }

  Future<Response> adminActivateJob(String jobId) async {
    return await _dio.patch('/admin/jobs/$jobId/activate');
  }

  Future<Response> adminDeactivateJob(String jobId) async {
    return await _dio.patch('/admin/jobs/$jobId/deactivate');
  }

  Future<Response> getAllApplications({
    int page = 1,
    String? status,
    String? jobId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': 50,
    };

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (jobId != null && jobId.isNotEmpty) {
      queryParams['jobId'] = jobId;
    }

    return await _dio.get('/admin/applications', queryParameters: queryParams);
  }

  Future<Response> adminUpdateApplicationStatus(
      String applicationId, Map<String, dynamic> data) async {
    return await _dio.put('/admin/applications/$applicationId/status',
        data: data);
  }
}
