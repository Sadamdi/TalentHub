import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

class BackendServer {
  late HttpServer _server;
  static const int port = 5000;

  Future<void> start() async {
    final router = Router();

    // CORS middleware
    final handler = Pipeline()
        .addMiddleware(corsHeaders())
        .addMiddleware(logRequests())
        .addHandler(router);

    // Auth routes
    router.post('/api/auth/login', _handleLogin);
    router.post('/api/auth/register', _handleRegister);
    router.get('/api/auth/me', _handleGetProfile);

    // Profile routes
    router.get('/api/profile', _handleGetProfile);
    router.put('/api/profile', _handleUpdateProfile);

    // Job routes
    router.get('/api/jobs', _handleGetJobs);
    router.get('/api/jobs/<id>', _handleGetJob);
    router.post('/api/jobs', _handleCreateJob);

    // Application routes
    router.get('/api/applications', _handleGetApplications);
    router.post('/api/applications', _handleCreateApplication);
    router.put('/api/applications/<id>', _handleUpdateApplication);

    try {
      _server = await serve(handler, 'localhost', port);
      print('🚀 Backend server running on localhost:$port');
    } catch (e) {
      print('❌ Error starting server: $e');
    }
  }

  Future<void> stop() async {
    await _server.close();
    print('🛑 Backend server stopped');
  }

  // Auth handlers
  Future<Response> _handleLogin(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final email = data['email'] as String?;
      final password = data['password'] as String?;

      if (email == null || password == null) {
        return Response(
          400,
          body: jsonEncode(
              {'success': false, 'message': 'Email dan password harus diisi'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Simulate user validation (replace with actual logic)
      if (email == 'test@example.com' && password == 'password') {
        final token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';

        // Store token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_email', email);

        return Response(
          200,
          body: jsonEncode({
            'success': true,
            'message': 'Login berhasil',
            'data': {
              'token': token,
              'user': {'email': email, 'name': 'Test User', 'role': 'talent'}
            }
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response(
          401,
          body: jsonEncode(
              {'success': false, 'message': 'Email atau password salah'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      return Response(
        500,
        body: jsonEncode(
            {'success': false, 'message': 'Terjadi kesalahan pada server'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _handleRegister(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final email = data['email'] as String?;
      final password = data['password'] as String?;
      final name = data['name'] as String?;
      final role = data['role'] as String?;

      if (email == null || password == null || name == null || role == null) {
        return Response(
          400,
          body: jsonEncode(
              {'success': false, 'message': 'Semua field harus diisi'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Simulate user creation
      final token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';

      // Store user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', name);
      await prefs.setString('user_role', role);

      return Response(
        200,
        body: jsonEncode({
          'success': true,
          'message': 'Registrasi berhasil',
          'data': {
            'token': token,
            'user': {'email': email, 'name': name, 'role': role}
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode(
            {'success': false, 'message': 'Terjadi kesalahan pada server'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _handleGetProfile(Request request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return Response(
          401,
          body: jsonEncode({'success': false, 'message': 'Token tidak valid'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final email = prefs.getString('user_email') ?? '';
      final name = prefs.getString('user_name') ?? '';
      final role = prefs.getString('user_role') ?? '';

      return Response(
        200,
        body: jsonEncode({
          'success': true,
          'data': {'email': email, 'name': name, 'role': role}
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode(
            {'success': false, 'message': 'Terjadi kesalahan pada server'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _handleUpdateProfile(Request request) async {
    // Implement profile update logic
    return Response(
      200,
      body: jsonEncode(
          {'success': true, 'message': 'Profile updated successfully'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleGetJobs(Request request) async {
    // Mock jobs data
    final jobs = [
      {
        'id': '1',
        'title': 'Flutter Developer',
        'company': 'Tech Corp',
        'location': 'Jakarta',
        'salary': 'Rp 8-12 juta',
        'type': 'Full-time',
        'description': 'Looking for experienced Flutter developer...'
      },
      {
        'id': '2',
        'title': 'UI/UX Designer',
        'company': 'Design Studio',
        'location': 'Bandung',
        'salary': 'Rp 6-10 juta',
        'type': 'Contract',
        'description': 'Creative UI/UX designer needed...'
      }
    ];

    return Response(
      200,
      body: jsonEncode({'success': true, 'data': jobs}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleGetJob(Request request) async {
    final jobId = request.params['id'];

    // Mock job detail
    final job = {
      'id': jobId,
      'title': 'Flutter Developer',
      'company': 'Tech Corp',
      'location': 'Jakarta',
      'salary': 'Rp 8-12 juta',
      'type': 'Full-time',
      'description':
          'Looking for experienced Flutter developer with 2+ years experience...',
      'requirements': [
        '2+ years Flutter experience',
        'Knowledge of Dart programming',
        'Experience with REST APIs'
      ]
    };

    return Response(
      200,
      body: jsonEncode({'success': true, 'data': job}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleCreateJob(Request request) async {
    // Implement job creation logic
    return Response(
      200,
      body:
          jsonEncode({'success': true, 'message': 'Job created successfully'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleGetApplications(Request request) async {
    // Mock applications data
    final applications = [
      {
        'id': '1',
        'jobTitle': 'Flutter Developer',
        'company': 'Tech Corp',
        'status': 'pending',
        'appliedDate': '2024-01-15'
      }
    ];

    return Response(
      200,
      body: jsonEncode({'success': true, 'data': applications}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleCreateApplication(Request request) async {
    // Implement application creation logic
    return Response(
      200,
      body: jsonEncode(
          {'success': true, 'message': 'Application submitted successfully'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleUpdateApplication(Request request) async {
    // Implement application update logic
    return Response(
      200,
      body: jsonEncode(
          {'success': true, 'message': 'Application updated successfully'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
