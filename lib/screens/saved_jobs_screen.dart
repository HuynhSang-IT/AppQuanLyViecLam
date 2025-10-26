// screens/saved_jobs_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({Key? key}) : super(key: key);

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  late final String _userId;
  late Future<List<Job>> _savedJobsFuture;

  @override
  void initState() {
    super.initState();
    final User? user = _authService.currentUser;
    if (user != null) {
      _userId = user.uid;
      _savedJobsFuture = _jobService.getFavoriteJobs(_userId);
    } else {
      _userId = '';
      _savedJobsFuture = Future.value([]); // Future rỗng
    }
  }

  // Hàm này dùng để refresh lại danh sách khi người dùng "bỏ lưu"
  void _refreshSavedJobs() {
    setState(() {
      _savedJobsFuture = _jobService.getFavoriteJobs(_userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Việc làm đã lưu')),
        body: const Center(
          child: Text('Không tìm thấy thông tin người dùng.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Việc làm đã lưu'),
        // --- MÀU CAM ---
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 1,
        // --- KẾT THÚC THÊM ---
      ),
      body: FutureBuilder<List<Job>>(
        future: _savedJobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_remove_outlined, size: 64, color: Colors.orange[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa lưu việc làm nào',
                    style: TextStyle(fontSize: 16, color: Colors.orange[600]),
                  ),
                ],
              ),
            );
          }

          final List<Job> jobs = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(jobs[index]);
            },
          );
        },
      ),
    );
  }

  // Đây là Job Card được copy từ home_screen,
  // nhưng sửa lại nút bookmark thành "Bỏ lưu"
  Widget _buildJobCard(Job job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.business, color: Colors.orange[700]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.company,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Nút Bỏ lưu
                IconButton(
                  icon: const Icon(Icons.bookmark, color: Colors.orange), // Icon bookmark (đầy)
                  onPressed: () async {
                    await _jobService.toggleFavorite(_userId, job.id);
                    // Tải lại danh sách
                    _refreshSavedJobs(); 
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã bỏ lưu việc làm')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(job.location, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(job.salary, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}