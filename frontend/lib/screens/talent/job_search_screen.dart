import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/job_card.dart';
import 'job_detail_screen.dart';

class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({super.key});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _selectedLocation = '';
  String _selectedSort = 'newest';

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadJobs() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.getJobs(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      category: _selectedCategory != 'all' ? _selectedCategory : null,
      location: _selectedLocation.isNotEmpty ? _selectedLocation : null,
      sort: _selectedSort,
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Lowongan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari pekerjaan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadJobs();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _loadJobs(),
                ),

                const SizedBox(height: 16),

                // Filter buttons
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Semua')),
                          DropdownMenuItem(value: 'designer', child: Text('Designer')),
                          DropdownMenuItem(value: 'writer', child: Text('Writer')),
                          DropdownMenuItem(value: 'finance', child: Text('Finance')),
                          DropdownMenuItem(value: 'developer', child: Text('Developer')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                          _loadJobs();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSort,
                        decoration: InputDecoration(
                          labelText: 'Urutkan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'newest', child: Text('Terbaru')),
                          DropdownMenuItem(value: 'oldest', child: Text('Terlama')),
                          DropdownMenuItem(value: 'salary_high', child: Text('Gaji Tertinggi')),
                          DropdownMenuItem(value: 'salary_low', child: Text('Gaji Terendah')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSort = value!;
                          });
                          _loadJobs();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: Consumer<JobProvider>(
              builder: (context, jobProvider, child) {
                if (jobProvider.isLoading && jobProvider.jobs.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (jobProvider.error != null && jobProvider.jobs.isEmpty) {
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
                          jobProvider.error!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadJobs,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (jobProvider.jobs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada lowongan ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobProvider.jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobProvider.jobs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: JobCard(
                        job: job,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => JobDetailScreen(jobId: job.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

