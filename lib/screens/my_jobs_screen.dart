// screens/my_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_model.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({Key? key}) : super(key: key);

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  late final String _userId;
  late final Stream<List<Job>> _jobsStream;

  @override
  void initState() {
    super.initState();
    // Lấy ID của user hiện tại
    final User? user = _authService.currentUser;
    if (user != null) {
      _userId = user.uid;
      _jobsStream = _jobService.getJobsByUser(_userId);
    } else {
      // Xử lý trường hợp không có user (hiếm khi xảy ra ở màn này)
      _userId = '';
      _jobsStream = Stream.value([]); // Stream rỗng
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      //Kiem tra user ID
      return Scaffold(
        appBar: AppBar(title: const Text('Việc làm của tôi')),
        body: const Center(
          child: Text('Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Việc làm của tôi'),
        // --- THÊM MÀU CAM ---
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 1,
        // --- KẾT THÚC THÊM ---
      ),
      body: StreamBuilder<List<Job>>(
        stream: _jobsStream,
        builder: (context, snapshot) {
          /*final List<Job> jobs = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              return _buildMyJobCard(jobs[index]);
            },
          );*/
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
                  Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa đăng việc làm nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Đăng việc ngay'),
                    onPressed: () {
                      Navigator.pushNamed(context, '/post_job');
                    },
                  )
                ],
              ),
            );
          }

          final List<Job> jobs = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              return _buildMyJobCard(jobs[index]);
            },
          );
        },
      ),
      // Thêm FAB để tiện đăng việc mới từ màn hình này
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () { Navigator.pushNamed(context, '/post_job'); },
          icon: const Icon(Icons.add),
          label: const Text('Đăng việc mới'),
          backgroundColor: Colors.orange[800],
      ),
    );
  }

  // Widget này được tùy chỉnh từ home_screen
  // Thêm các nút quản lý (Sửa, Xóa, Ẩn/Hiện)
  Widget _buildMyJobCard(Job job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
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
                  child: Icon(Icons.business, color: Colors.blue[700]),
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
              ],
            ),
            const SizedBox(height: 12),
            // Chip trạng thái (ĐỔI MÀU)
            Chip(
              label: Text(
                job.status == 'active' ? 'Đang hiển thị' : 'Đã ẩn',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            // Hiển thị trạng thái (active/inactive)
            /*Chip(
              label: Text(
                job.status == 'active' ? 'Đang hiển thị' : 'Đã ẩn',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),*/
              backgroundColor: job.status == 'active' ? Colors.green[600] : Colors.grey[500],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
            const Divider(height: 24),
            // Các nút hành động
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.people_outline, size: 18, color: Colors.blue),
                  label: const Text('Ứng viên', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/job_applicants',
                      arguments: {
                        'jobId': job.id,      // ✅ TRUYỀN MAP
                        'jobTitle': job.title, // ✅ TRUYỀN MAP
                      },
                    );
                  },
                ),  
                const Spacer(), // Đẩy các nút khác ra xa
                TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.orange),
                label: const Text('Sửa', style: TextStyle(color: Colors.orange)),
                onPressed: () {
                  // Gọi màn hình PostJob và truyền Job object qua
                  Navigator.pushNamed(context, '/post_job', arguments: job);
                },
              ),
                TextButton.icon(
                  icon: Icon(
                    job.status == 'active' ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: job.status == 'active' ? Colors.orange : Colors.green,
                  ),
                  label: Text(
                    job.status == 'active' ? 'Ẩn tin' : 'Hiện tin',
                    style: TextStyle(
                      color: job.status == 'active' ? Colors.orange : Colors.green,
                    ),
                  ),
                  onPressed: () => _toggleJobStatus(job),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.orange),
                  label: const Text('Xóa', style: TextStyle(color: Colors.orange)),
                  onPressed: () => _deleteJob(job.id),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Hàm xử lý Ẩn/Hiện tin
  void _toggleJobStatus(Job job) async {
    final String newStatus = job.status == 'active' ? 'inactive' : 'active';
    final bool success = await _jobService.updateJobStatus(job.id, newStatus);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Đã cập nhật trạng thái'
              : 'Cập nhật thất bại'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // Hàm xử lý Xóa
  void _deleteJob(String jobId) async {
    // Hiển thị dialog xác nhận
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa việc làm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final bool success = await _jobService.deleteJob(jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã xóa việc làm' : 'Xóa thất bại'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}