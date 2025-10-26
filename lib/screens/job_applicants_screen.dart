// screens/job_applicants_screen.dart (ĐÃ THÊM HIỂN THỊ VÀ XEM CV)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- 1. IMPORT URL LAUNCHER
import '../services/job_service.dart';
import '../services/auth_service.dart';

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
  late Stream<List<Map<String, dynamic>>> _applicantsStream;

  @override
  void initState() {
    super.initState();
    _applicantsStream = _jobService.getApplicantsForJob(widget.jobId);
  }

  // --- 4. HÀM MỞ URL CV ---
  Future<void> _launchCvUrl(String? cvUrl, BuildContext context) async {
    if (cvUrl == null || cvUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ứng viên này chưa tải lên CV.'), backgroundColor: Colors.orange),
      );
      return;
    }
    final uri = Uri.parse(cvUrl);
    if (await canLaunchUrl(uri)) {
      // Mở bằng trình duyệt hoặc ứng dụng phù hợp bên ngoài app
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) { // Thêm kiểm tra mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở liên kết CV: $cvUrl'), backgroundColor: Colors.red),
        );
      }
    }
  }
  // --- KẾT THÚC HÀM MỞ URL ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ứng viên: ${widget.jobTitle}'),
        backgroundColor: Colors.orange[700], // Thêm màu cam cho AppBar
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
             return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Lỗi: ${snapshot.error}. Đã tạo index (jobId, appliedDate) chưa?')));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // --- CODE HIỂN THỊ KHÔNG CÓ ỨNG VIÊN ĐẦY ĐỦ ---
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search_outlined, size: 64, color: Colors.grey[400]), // Icon tìm kiếm
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có ứng viên nào cho vị trí này',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center, // Căn giữa nếu text dài
                  ),
                ],
              ),
            );
            // --- KẾT THÚC ---
          }

          final List<Map<String, dynamic>> applicants = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // Thêm padding dọc
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              // --- SỬA LẠI CARD ---
              return _buildApplicantCard(applicants[index], context); // Truyền context vào
            },
          );
        },
      ),
    );
  }

  // --- 2. SỬA LẠI WIDGET CARD ---
  Widget _buildApplicantCard(Map<String, dynamic> applicationData, BuildContext scaffoldContext) {
    final String userId = applicationData['userId'];
    // final String appStatus = applicationData['status'] ?? 'pending'; // Có thể dùng sau

    return FutureBuilder<Map<String, dynamic>?>(
      future: _authService.getUserData(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Card( // Thêm Card để đẹp hơn khi loading
             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             child: const ListTile(title: Text('Đang tải thông tin...'), leading: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
          return Card( // Thêm Card cho lỗi
             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             color: Colors.red[50],
             child: const ListTile(leading: Icon(Icons.error_outline, color: Colors.red), title: Text('Lỗi tải ứng viên')),
           );
        }

        final userData = userSnapshot.data!;
        final String avatarUrl = userData['avatarUrl'] ?? '';
        // --- 2.1 LẤY THÔNG TIN CV ---
        final String? cvFileName = userData['cvFileName'];
        final String? cvUrl = userData['cvUrl'];
        // --- KẾT THÚC LẤY CV ---

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3, // Tăng shadow
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            leading: CircleAvatar(
              radius: 28, // To hơn chút
              backgroundImage: (avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
              backgroundColor: Colors.orange[50], // Nền cam nhạt
              child: (avatarUrl.isEmpty) ? Icon(Icons.person_outline, color: Colors.orange[600]) : null,
            ),
            title: Text(userData['name'] ?? 'Chưa cập nhật tên', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column( // Dùng Column để hiển thị email và CV
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  const SizedBox(height: 4),
                  Text(userData['email'] ?? 'Không có email'),
                  // --- 2.2 HIỂN THỊ TÊN FILE CV (NẾU CÓ) ---
                  if (cvFileName != null && cvFileName.isNotEmpty)
                     Padding(
                       padding: const EdgeInsets.only(top: 6.0),
                       child: Row(
                         mainAxisSize: MainAxisSize.min, // Chỉ chiếm đủ chỗ
                         children: [
                           Icon(Icons.description_outlined, size: 16, color: Colors.grey[600]),
                           const SizedBox(width: 4),
                           Flexible( // Cho phép xuống dòng nếu tên file quá dài
                             child: Text(
                               cvFileName,
                               style: TextStyle(fontSize: 13, color: Colors.blue[700], fontStyle: FontStyle.italic),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                         ],
                       ),
                     ),
                  // --- KẾT THÚC HIỂN THỊ CV ---
               ],
            ),
            // --- 2.3 THÊM NÚT XEM CV ---
            trailing: (cvUrl != null && cvUrl.isNotEmpty) // Chỉ hiện nút nếu có URL CV
               ? TextButton.icon(
                   icon: Icon(Icons.visibility_outlined, size: 18, color: Colors.orange[800]),
                   label: Text('Xem CV', style: TextStyle(color: Colors.orange[800])),
                   onPressed: () => _launchCvUrl(cvUrl, scaffoldContext), // Gọi hàm mở URL
                   style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      // Có thể thêm viền hoặc nền nếu muốn
                       side: BorderSide(color: Colors.orange.shade200),
                   ),
                 )
               : null, // Không hiện gì nếu chưa có CV
             // Bỏ onTap ở ListTile để tránh xung đột với nút Xem CV
             // onTap: () { /* ... */ },
          ),
        );
      },
    );
  }
   // --- KẾT THÚC SỬA CARD ---

} // <--- Class State kết thúc