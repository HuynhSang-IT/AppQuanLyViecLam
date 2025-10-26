// screens/my_applications_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Quan trọng: Import trực tiếp
import '../models/job_model.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({Key? key}) : super(key: key);

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  late final String _userId;
  late final Stream<List<Map<String, dynamic>>> _applicationsStream;

  @override
  void initState() {
    super.initState();
    final User? user = _authService.currentUser;
    if (user != null) {
      _userId = user.uid;
      // Lấy stream các đơn ứng tuyển của user
      _applicationsStream = _jobService.getUserApplications(_userId);
    } else {
      _userId = '';
      _applicationsStream = Stream.value([]); // Stream rỗng
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      //Kiem tra user ID
      return Scaffold(
        appBar: AppBar(title: const Text('Việc đã ứng tuyển')),
        body: const Center(
          child: Text('Không tìm thấy thông tin người dùng.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Việc đã ứng tuyển'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _applicationsStream,
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
                  Icon(Icons.file_copy_outlined, size: 64, color: Colors.orange[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa ứng tuyển việc làm nào',
                    style: TextStyle(fontSize: 16, color: Colors.orange[600]),
                  ),
                ],
              ),
            );
          }

          // Đã có danh sách đơn ứng tuyển
          final List<Map<String, dynamic>> applications = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              // Với mỗi đơn, build 1 card
              return _buildApplicationCard(applications[index]);
            },
          );
        },
      ),
    );
  }

  /// Widget này sẽ nhận data của 1 đơn ứng tuyển
  /// và dùng FutureBuilder để tải chi tiết Job
  Widget _buildApplicationCard(Map<String, dynamic> applicationData) {
    final String jobId = applicationData['jobId'];
    final String appStatus = applicationData['status'] ?? 'pending';

    return FutureBuilder<DocumentSnapshot>(
      // Tải chi tiết job từ Firestore bằng jobId
      future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
      builder: (context, jobSnapshot) {
        
        // Trạng thái đang tải Job
        if (jobSnapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const ListTile(
              title: Text('Đang tải thông tin việc làm...'),
              subtitle: LinearProgressIndicator(),
            ),
          );
        }

        // Nếu Job bị lỗi hoặc đã bị xóa
        if (jobSnapshot.hasError || !jobSnapshot.hasData || !jobSnapshot.data!.exists) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red[50],
            child: ListTile(
              title: const Text('Việc làm này không còn tồn tại', style: TextStyle(color: Colors.red)),
              subtitle: Text('ID: $jobId'),
            ),
          );
        }

        // Đã có data job, chuyển nó thành Job Object
        Map<String, dynamic> jobData = jobSnapshot.data!.data() as Map<String, dynamic>;
        jobData['id'] = jobSnapshot.data!.id;
        if (jobData['postedDate'] is Timestamp) {
          jobData['postedDate'] = (jobData['postedDate'] as Timestamp).toDate();
        } else {
          jobData['postedDate'] = DateTime.now();
        }
        final Job job = Job.fromFirestore(jobData);

        // Hiển thị card đầy đủ
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.orange[100],
              child: Icon(Icons.business, color: Colors.orange[700]),
            ),
            title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(job.company),
            trailing: Chip(
              label: Text(
                _getStatusText(appStatus),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: _getStatusColor(appStatus),
            ),
          ),
        );
      },
    );
  }

  // Helper để hiển thị text trạng thái
  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Đang chờ';
      case 'reviewed': return 'Đã xem';
      case 'rejected': return 'Bị từ chối';
      default: return 'Không rõ';
    }
  }

  // Helper để hiển thị màu trạng thái
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'reviewed': return Colors.blue;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }
}