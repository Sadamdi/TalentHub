import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../applications/chat_screen.dart' as ApplicationChatScreen;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() {
    final applicationProvider =
        Provider.of<ApplicationProvider>(context, listen: false);
    applicationProvider.getApplications().catchError((error) {
      print('Error loading applications: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chat'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: Consumer<ApplicationProvider>(
            builder: (context, applicationProvider, child) {
              if (applicationProvider.isLoading &&
                  applicationProvider.applications.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (applicationProvider.error != null &&
                  applicationProvider.applications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        applicationProvider.error!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadApplications,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }

              // Filter applications that have chat available
              final applicationsWithChat = applicationProvider.applications
                  .where((app) => app.status != 'cancelled')
                  .toList();

              if (applicationsWithChat.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada chat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chat akan muncul otomatis ketika ada lamaran',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'HRD perusahaan akan menghubungi Anda melalui sini',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: applicationsWithChat.length,
                itemBuilder: (context, index) {
                  final application = applicationsWithChat[index];
                  return _buildChatItem(application);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildChatItem(application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(
            Icons.business,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          application.jobTitle ?? 'Job Title',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${_getStatusText(application.status)}',
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(application.status),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Dilamar: ${_formatDate(application.createdAt)}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(application.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(application.status),
            style: TextStyle(
              fontSize: 10,
              color: _getStatusColor(application.status),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () {
          // Navigate to chat screen for this application
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ApplicationChatScreen.ChatScreen(
                  applicationId: application.id),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'hired':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'interview':
        return AppColors.info;
      case 'reviewed':
        return AppColors.primary;
      default:
        return AppColors.textLight;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'hired':
        return 'Diterima';
      case 'rejected':
        return 'Ditolak';
      case 'interview':
        return 'Interview';
      case 'reviewed':
        return 'Direview';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
