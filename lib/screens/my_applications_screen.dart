// screens/my_applications_screen.dart - Màn hình APPLICANT xem đơn ứng tuyển của mình

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({Key? key}) : super(key: key);

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  late final String _applicantId;
  late final Stream<List<Map<String, dynamic>>> _applicationsStream;

  @override
  void initState() {
    super.initState();
    _applicantId = _authService.currentUser?.uid ?? '';
    
    if (_applicantId.isNotEmpty) {
      _applicationsStream = _jobService.getUserApplications(_applicantId);
    } else {
      _applicationsStream = Stream.value([]);
    }
  }

  // HÀM MỞ CHAT (CHO APPLICANT)
  void _openChatScreen(BuildContext context, String applicationId, String recruiterId, String recruiterName, String jobTitle) async {
    print("💬 [APPLICANT] Bắt đầu mở chat");

    if (_applicantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không xác định được người dùng.'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    String? chatRoomId;
    try {
      // Lấy jobId từ application
      DocumentSnapshot appDoc = await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .get();
      
      String jobId = appDoc.get('jobId') ?? '';

      chatRoomId = await _chatService.getOrCreateChatRoom(
        applicationId,
        recruiterId,   // Recruiter
        _applicantId,  // Ứng viên (mình)
        jobId,
      );
      print("💬 [APPLICANT] ChatRoomId: $chatRoomId");

    } catch (e) {
      print("💬 [APPLICANT] LỖI: $e");
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    if (chatRoomId != null && context.mounted) {
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatRoomId': chatRoomId,
          'receiverName': recruiterName,
          'receiverId': recruiterId,
          'applicationId': applicationId,
          'isRecruiter': false,  // Ứng viên = false
        },
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở cuộc trò chuyện.'), backgroundColor: Colors.red),
      );
    }
  }

  // HÀM RÚT ĐƠN ỨNG TUYỂN
  Future<void> _withdrawApplication(String applicationId, String jobTitle) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận rút đơn'),
        content: Text('Bạn có chắc muốn rút đơn ứng tuyển "$jobTitle" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rút đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .delete();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã rút đơn ứng tuyển thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_applicantId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đơn ứng tuyển của tôi')),
        body: const Center(child: Text('Lỗi: Không tìm thấy thông tin người dùng.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn ứng tuyển của tôi'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _applicationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Lỗi: ${snapshot.error}'),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa ứng tuyển công việc nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final List<Map<String, dynamic>> applications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              return _buildApplicationCard(applications[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> appData) {
    final String applicationId = appData['id'] ?? '';
    final String jobId = appData['jobId'] ?? '';
    final String appStatus = appData['status'] ?? 'pending';
    final Timestamp? appliedTimestamp = appData['appliedDate'];

    // Kiểm tra jobId hợp lệ
    if (jobId.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.red[50],
        child: ListTile(
          leading: Icon(Icons.error_outline, color: Colors.red),
          title: const Text('Lỗi: Không tìm thấy thông tin công việc'),
        ),
      );
    }

    // Format ngày ứng tuyển
    String appliedDate = 'Không rõ';
    if (appliedTimestamp != null) {
      DateTime date = appliedTimestamp.toDate();
      appliedDate = '${date.day}/${date.month}/${date.year}';
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
      builder: (context, jobSnapshot) {
        if (jobSnapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: const ListTile(
              title: Text('Đang tải thông tin công việc...'),
              leading: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (jobSnapshot.hasError || !jobSnapshot.hasData || !jobSnapshot.data!.exists) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.red[50],
            child: ListTile(
              leading: Icon(Icons.warning_amber_rounded, color: Colors.red[300]),
              title: const Text('Công việc không tồn tại', style: TextStyle(color: Colors.red)),
            ),
          );
        }

        Map<String, dynamic> jobData = jobSnapshot.data!.data() as Map<String, dynamic>;
        final String jobTitle = jobData['title'] ?? 'Không có tiêu đề';
        final String company = jobData['company'] ?? '';
        final String location = jobData['location'] ?? '';
        // Hỗ trợ cả postedBy và recruiterId
        final String recruiterId = jobData['postedBy'] ?? jobData['recruiterId'] ?? '';

        // Kiểm tra recruiterId hợp lệ
        if (recruiterId.isEmpty) {
          return _buildJobCard(
            applicationId: applicationId,
            jobTitle: jobTitle,
            company: company,
            location: location,
            appliedDate: appliedDate,
            appStatus: appStatus,
            recruiterId: '',
            recruiterName: 'Nhà tuyển dụng',
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(recruiterId).get(),
          builder: (context, recruiterSnapshot) {
            String recruiterName = 'Nhà tuyển dụng';
            if (recruiterSnapshot.hasData && recruiterSnapshot.data!.exists) {
              Map<String, dynamic>? recruiterData = recruiterSnapshot.data!.data() as Map<String, dynamic>?;
              recruiterName = recruiterData?['name'] ?? 'Nhà tuyển dụng';
            }

            return _buildJobCard(
              applicationId: applicationId,
              jobTitle: jobTitle,
              company: company,
              location: location,
              appliedDate: appliedDate,
              appStatus: appStatus,
              recruiterId: recruiterId,
              recruiterName: recruiterName,
            );
          },
        );
      },
    );
  }

  Widget _buildJobCard({
    required String applicationId,
    required String jobTitle,
    required String company,
    required String location,
    required String appliedDate,
    required String appStatus,
    required String recruiterId,
    required String recruiterName,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Job Title + Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (company.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.business_outlined, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                company,
                                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (location.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    _getStatusText(appStatus),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: _getStatusColor(appStatus),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                ),
              ],
            ),

            const SizedBox(height: 12),
            
            // Ngày ứng tuyển
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Ứng tuyển: $appliedDate',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ACTION BUTTONS
            Row(
              children: [
                // Nút CHAT
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: recruiterId.isNotEmpty ? () {
                      _openChatScreen(context, applicationId, recruiterId, recruiterName, jobTitle);
                    } : null,
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                      side: BorderSide(color: Colors.orange[700]!),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),

                // Nút RÚT ĐƠN (chỉ khi pending)
                if (appStatus == 'pending')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _withdrawApplication(applicationId, jobTitle);
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Rút đơn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        side: BorderSide(color: Colors.red[600]!),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),

                // Hiển thị trạng thái (nếu đã duyệt/từ chối)
                if (appStatus == 'reviewed')
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600], size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Đã duyệt',
                            style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (appStatus == 'rejected')
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, color: Colors.red[600], size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Đã từ chối',
                            style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Đang chờ';
      case 'reviewed': return 'Đã duyệt';
      case 'rejected': return 'Đã từ chối';
      default: return 'Không rõ';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange[600]!;
      case 'reviewed': return Colors.green[600]!;
      case 'rejected': return Colors.red[600]!;
      default: return Colors.grey[500]!;
    }
  }
}