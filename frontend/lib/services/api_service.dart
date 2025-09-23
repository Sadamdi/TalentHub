import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Backend server berjalan di server publik
  static const String baseUrl = 'http://43.157.211.134:2550/api';

  // Alternative URLs untuk debugging
  static const String localhostUrl =
      'http://10.0.2.2:2550/api'; // Untuk emulator Android
  static const String ipv4Url =
      'http://192.168.1.100:2550/api'; // Contoh IP lokal

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print(
            '📡 API Request: ${options.method} ${options.baseUrl}${options.path}');
        print('📝 Headers: ${options.headers}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print(
            '✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        print(
            '❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}');
        print('❌ Error Message: ${error.message}');
        print('❌ Error Response: ${error.response?.data}');

        if (error.response?.statusCode == 401) {
          // Token expired or invalid
          removeToken();
        }
        handler.next(error);
      },
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

  // Method untuk test endpoint tanpa authentication (debugging)
  Future<Response> testEndpointWithoutAuth(String endpoint) async {
    print('🔍 Testing endpoint without auth: $baseUrl$endpoint');

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add logging interceptor for debugging
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    return await dio.get(endpoint);
  }

  // Method untuk test dengan base URL alternatif (untuk emulator)
  Future<Response> testWithAlternativeUrl(
      String endpoint, String altBaseUrl) async {
    print('🔍 Testing with alternative URL: $altBaseUrl$endpoint');

    final dio = Dio(BaseOptions(
      baseUrl: altBaseUrl,
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    return await dio.get(endpoint);
  }

  // Method untuk test semua base URL yang tersedia
  Future<Map<String, dynamic>> testAllUrls(String endpoint) async {
    print('🔍 Testing all available URLs for endpoint: $endpoint');

    final urls = {
      'public_ip': baseUrl,
      'localhost': localhostUrl,
      'ipv4': ipv4Url,
    };

    final results = <String, dynamic>{};

    for (var entry in urls.entries) {
      try {
        print('🧪 Testing ${entry.key}: ${entry.value}$endpoint');
        final response = await testWithAlternativeUrl(endpoint, entry.value);
        results[entry.key] = {
          'success': true,
          'statusCode': response.statusCode,
          'data': response.data,
        };
        print('✅ ${entry.key} berhasil: ${response.statusCode}');
      } catch (e) {
        results[entry.key] = {
          'success': false,
          'error': e.toString(),
        };
        print('❌ ${entry.key} error: $e');
      }
    }

    return results;
  }

  // Method untuk ping server dan cek connectivity
  Future<Map<String, dynamic>> pingServer() async {
    print('🔍 Pinging server...');

    final urls = {
      'public_ip': 'http://43.157.211.134:2550',
      'localhost': 'http://10.0.2.2:2550',
      'ipv4': 'http://192.168.1.100:2550',
    };

    final results = <String, dynamic>{};

    for (var entry in urls.entries) {
      try {
        print('🧪 Pinging ${entry.key}: ${entry.value}');
        final response = await Dio().get('${entry.value}/api/jobs/ping',
            options: Options(
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));
        results[entry.key] = {
          'success': true,
          'statusCode': response.statusCode,
          'responseTime': DateTime.now().toString(),
          'serverInfo': response.data['serverInfo'],
        };
        print('✅ ${entry.key} reachable: ${response.statusCode}');
      } catch (e) {
        results[entry.key] = {
          'success': false,
          'error': e.toString(),
          'errorTime': DateTime.now().toString(),
        };
        print('❌ ${entry.key} unreachable: $e');
      }
    }

    return results;
  }

  // Auth endpoints
  Future<Response> login(Map<String, dynamic> data) async {
    return await _dio.post('/auth/login', data: data);
  }

  Future<Response> register(Map<String, dynamic> data) async {
    return await _dio.post('/auth/register', data: data);
  }

  Future<Response> googleSignIn(Map<String, dynamic> data) async {
    return await _dio.post('/auth/google', data: data);
  }

  Future<Response> getCurrentUser() async {
    return await _dio.get('/auth/me');
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await _dio.put('/auth/profile', data: data);
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

  Future<Response> testCompanyJobs() async {
    return await _dio.get('/jobs/test-company-jobs');
  }

  Future<Response> createJob(Map<String, dynamic> data) async {
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
      'category': category,
      'limit': limit,
    };

    return await _dio.get('/jobs/recommendations',
        queryParameters: queryParams);
  }

  // Application endpoints
  Future<Response> getApplications() async {
    return await _dio.get('/applications');
  }

  Future<Response> getCompanyApplications() async {
    return await _dio.get('/applications/company');
  }

  Future<Response> getApplication(String applicationId) async {
    return await _dio.get('/applications/$applicationId');
  }

  Future<Response> applyForJob(Map<String, dynamic> data) async {
    return await _dio.post('/applications', data: data);
  }

  Future<Response> updateApplicationStatus(
      String applicationId, Map<String, dynamic> data) async {
    return await _dio.put('/applications/$applicationId/status', data: data);
  }

  // Company endpoints
  Future<Response> getCompanyProfile() async {
    return await _dio.get('/company/profile');
  }

  Future<Response> updateCompanyProfile(Map<String, dynamic> data) async {
    return await _dio.put('/company/profile', data: data);
  }

  // Talent endpoints
  Future<Response> getTalentProfile() async {
    return await _dio.get('/talent/profile');
  }

  Future<Response> updateTalentProfile(Map<String, dynamic> data) async {
    return await _dio.put('/talent/profile', data: data);
  }
}
