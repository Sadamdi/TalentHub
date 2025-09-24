import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/application_provider.dart';
import '../../utils/app_colors.dart';
import '../applications/chat_screen.dart';

class CompanyChatScreen extends StatefulWidget {
  const CompanyChatScreen({super.key});

  @override
  State<CompanyChatScreen> createState() => _CompanyChatScreenState();
}

class _CompanyChatScreenState extends State<CompanyChatScreen> {
  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() {
    final applicationProvider =
        Provider.of<ApplicationProvider>(context, listen: false);
    applicationProvider.getCompanyApplications().catchError((error) {
      print('Error loading chat applications: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat dengan Pelamar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ApplicationProvider>(
        builder: (context, applicationProvider, child) {
          if (applicationProvider.isLoading &&
              applicationProvider.companyApplications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (applicationProvider.error != null &&
              applicationProvider.companyApplications.isEmpty) {
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

          if (applicationProvider.companyApplications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada pelamar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pelamar akan muncul di sini setelah melamar pekerjaan',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Group applications by status
          final pendingApps = applicationProvider.companyApplications
              .where((app) => app.status == 'pending')
              .toList();
          final acceptedApps = applicationProvider.companyApplications
              .where((app) => app.status == 'hired')
              .toList();
          final otherApps = applicationProvider.companyApplications
              .where((app) => !['pending', 'hired'].contains(app.status))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pendingApps.isNotEmpty) ...[
                const Text(
                  'Menunggu Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...pendingApps.map((app) => _buildChatItem(app)),
                const SizedBox(height: 24),
              ],
              if (acceptedApps.isNotEmpty) ...[
                const Text(
                  'Diterima',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...acceptedApps.map((app) => _buildChatItem(app)),
                const SizedBox(height: 24),
              ],
              if (otherApps.isNotEmpty) ...[
                const Text(
                  'Lainnya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...otherApps.map((app) => _buildChatItem(app)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatItem(app) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            app.applicantName?.substring(0, 1).toUpperCase() ?? 'U',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          app.applicantName ?? 'Unknown Applicant',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.jobTitle ?? 'Job Title',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              app.applicantEmail ?? 'No Email',
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
            color: _getStatusColor(app.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(app.status),
            style: TextStyle(
              fontSize: 10,
              color: _getStatusColor(app.status),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () {
          // Navigate to chat screen for this application
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(applicationId: app.id),
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
      default:
        return AppColors.textLight;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'hired':
        return 'Hired';
      case 'rejected':
        return 'Rejected';
      case 'interview':
        return 'Interview';
      default:
        return status;
    }
  }
}
