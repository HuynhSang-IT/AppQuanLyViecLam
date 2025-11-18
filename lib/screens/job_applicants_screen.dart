// screens/job_applicants_screen.dart - Màn hình Recruiter xem ứng viên

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const JobApplicantsScreen({
    Key? key,
    required this.jobId,
    required this.jobTitle,
  }) : super(key: key);

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  late final String _recruiterId;
  late final Stream<List<Map<String, dynamic>>> _applicantsStream;

  @override
  void initState() {
    super.initState();
    _recruiterId = _authService.currentUser?.uid ?? '';
    
    if (_recruiterId.isNotEmpty) {
      _applicantsStream = _jobService.getApplicantsForJob(widget.jobId);
    } else {
      _applicantsStream = Stream.value([]);
    }
  }

  // ✅ HÀM CẬP NHẬT TRẠNG THÁI ỨNG VIÊN
  Future<void> _updateApplicationStatus(String applicationId, String newStatus, String applicantName) async {
    String actionText = newStatus == 'reviewed' ? 'duyệt' : 'từ chối';
    
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận ${actionText}'),
        content: Text('Bạn có chắc muốn ${actionText} ứng viên "$applicantName" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'reviewed' ? Colors.green : Colors.red,
            ),
            child: Text(
              newStatus == 'reviewed' ? 'Duyệt' : 'Từ chối',
              style: const TextStyle(color: Colors.white),
            ),
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
      bool success = await _jobService.updateApplicationStatus(applicationId, newStatus);
      
      if (mounted) {
        Navigator.pop(context);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã ${actionText} ứng viên thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi ${actionText} ứng viên.'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  // ✅ HÀM MỞ CHAT (CHO RECRUITER)
  void _openChatScreen(BuildContext context, String applicationId, String applicantId, String applicantName) async {
    print("👔 [RECRUITER] Bắt đầu mở chat");

    if (_recruiterId.isEmpty) {
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
      chatRoomId = await _chatService.getOrCreateChatRoom(
        applicationId,
        _recruiterId,
        applicantId,
        widget.jobId,
      );
      print("👔 [RECRUITER] ChatRoomId: $chatRoomId");

    } catch (e) {
      print("👔 [RECRUITER] LỖI: $e");
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
          'receiverName': applicantName,
          'receiverId': applicantId,
          'applicationId': applicationId,
          'isRecruiter': true,
        },
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở cuộc trò chuyện.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recruiterId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Danh sách ứng viên')),
        body: const Center(child: Text('Lỗi: Không tìm thấy thông tin người dùng.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Danh sách ứng viên', style: TextStyle(fontSize: 18)),
            Text(
              widget.jobTitle,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _applicantsStream,
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
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có ứng viên nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final List<Map<String, dynamic>> applicants = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              return _buildApplicantCard(applicants[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicantData) {
    final String applicantId = applicantData['userId'];
    final String applicationId = applicantData['id'];
    final String appStatus = applicantData['status'] ?? 'pending';
    final Timestamp? appliedTimestamp = applicantData['appliedDate'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(applicantId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: const ListTile(
              title: Text('Đang tải thông tin ứng viên...'),
              leading: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.red[50],
            child: ListTile(
              leading: Icon(Icons.warning_amber_rounded, color: Colors.red[300]),
              title: const Text('Người dùng không tồn tại', style: TextStyle(color: Colors.red)),
            ),
          );
        }

        Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final String applicantName = userData['name'] ?? 'Không có tên';
        final String applicantEmail = userData['email'] ?? '';
        final String applicantPhone = userData['phone'] ?? '';

        String appliedDate = 'Không rõ';
        if (appliedTimestamp != null) {
          DateTime date = appliedTimestamp.toDate();
          appliedDate = '${date.day}/${date.month}/${date.year}';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.orange[100],
                      child: Text(
                        applicantName.isNotEmpty ? applicantName[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange[700]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            applicantName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ứng tuyển: $appliedDate',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
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
                
                if (applicantEmail.isNotEmpty)
                  _buildInfoRow(Icons.email_outlined, applicantEmail),
                if (applicantPhone.isNotEmpty)
                  _buildInfoRow(Icons.phone_outlined, applicantPhone),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _openChatScreen(context, applicationId, applicantId, applicantName);
                        },
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

                    if (appStatus == 'pending') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _updateApplicationStatus(applicationId, 'reviewed', applicantName);
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Duyệt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _updateApplicationStatus(applicationId, 'rejected', applicantName);
                          },
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Từ chối'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],

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
                                style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
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
                                style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
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
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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