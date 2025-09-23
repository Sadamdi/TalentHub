import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../utils/app_colors.dart';

class CompanyCreateJobScreen extends StatefulWidget {
  const CompanyCreateJobScreen({super.key});

  @override
  State<CompanyCreateJobScreen> createState() => _CompanyCreateJobScreenState();
}

class _CompanyCreateJobScreenState extends State<CompanyCreateJobScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _responsibilitiesController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _skillsController = TextEditingController();
  final _benefitsController = TextEditingController();

  // Form variables
  String _selectedJobType = 'full_time';
  String _selectedCategory = 'developer';
  String _selectedExperienceLevel = '1-2_years';
  bool _isLoading = false;

  final List<String> _jobTypes = [
    'full_time',
    'part_time',
    'contract',
    'internship',
    'freelance'
  ];

  final List<String> _categories = [
    'developer',
    'technology',
    'marketing',
    'sales',
    'finance',
    'hr',
    'operations',
    'design',
    'other'
  ];

  final List<String> _experienceLevels = [
    'fresh_graduate',
    '1-2_years',
    '3-5_years',
    '5+_years'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _responsibilitiesController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _skillsController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);

      // Prepare job data
      final jobData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'requirements': _requirementsController.text
            .trim()
            .split('\n')
            .where((s) => s.isNotEmpty)
            .toList(),
        'responsibilities': _responsibilitiesController.text
            .trim()
            .split('\n')
            .where((s) => s.isNotEmpty)
            .toList(),
        'location': _locationController.text.trim(),
        'salary': {
          'amount': int.tryParse(
                  _salaryController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
              0,
          'currency': 'IDR',
          'period': 'monthly',
        },
        'jobType': _selectedJobType,
        'category': _selectedCategory,
        'experienceLevel': _selectedExperienceLevel,
        'skills': _skillsController.text
            .trim()
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'benefits': _benefitsController.text
            .trim()
            .split('\n')
            .where((s) => s.isNotEmpty)
            .toList(),
      };

      print('Creating job with data: $jobData');

      final success = await jobProvider.createJob(jobData);

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        print('Job creation successful');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(); // Go back to jobs screen
      } else {
        print('Job creation failed: ${jobProvider.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jobProvider.error ?? 'Failed to create job'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      print('Error creating job: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Job'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createJob,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Post Job',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _titleController,
                label: 'Job Title *',
                hint: 'e.g. Software Engineer',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Job title is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _descriptionController,
                label: 'Job Description *',
                hint: 'Describe the role and responsibilities...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Job description is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _requirementsController,
                label: 'Requirements',
                hint: 'Enter each requirement on a new line...',
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _responsibilitiesController,
                label: 'Responsibilities',
                hint: 'Enter each responsibility on a new line...',
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Job Details
              const Text(
                'Job Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Job Type',
                value: _selectedJobType,
                items: _jobTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_formatJobType(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedJobType = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Category',
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_formatCategory(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Experience Level',
                value: _selectedExperienceLevel,
                items: _experienceLevels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(_formatExperienceLevel(level)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExperienceLevel = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _locationController,
                label: 'Location *',
                hint: 'e.g. Jakarta, Remote, etc.',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _salaryController,
                label: 'Salary (Monthly)',
                hint: 'e.g. Rp 5,000,000',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _skillsController,
                label: 'Required Skills',
                hint: 'e.g. JavaScript, React, Node.js (comma separated)',
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _benefitsController,
                label: 'Benefits & Perks',
                hint: 'Enter each benefit on a new line...',
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Job Posting',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: items,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  String _formatJobType(String type) {
    switch (type) {
      case 'full_time':
        return 'Full Time';
      case 'part_time':
        return 'Part Time';
      case 'contract':
        return 'Contract';
      case 'internship':
        return 'Internship';
      case 'freelance':
        return 'Freelance';
      default:
        return type;
    }
  }

  String _formatCategory(String category) {
    switch (category) {
      case 'technology':
        return 'Technology';
      case 'marketing':
        return 'Marketing';
      case 'sales':
        return 'Sales';
      case 'finance':
        return 'Finance';
      case 'hr':
        return 'Human Resources';
      case 'operations':
        return 'Operations';
      case 'design':
        return 'Design';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  String _formatExperienceLevel(String level) {
    switch (level) {
      case 'fresh_graduate':
        return 'Fresh Graduate';
      case '1-2_years':
        return '1-2 Years';
      case '3-5_years':
        return '3-5 Years';
      case '5+_years':
        return '5+ Years';
      default:
        return level;
    }
  }
}
