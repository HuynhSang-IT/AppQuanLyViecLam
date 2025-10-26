//import 'package{packageName}/{projectName}/lib/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
// Bạn cần package_info_plus để lấy version tự động (chạy flutter pub add package_info_plus)
//import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '1.0.0'; // Version mặc định

  @override
  void initState() {
    super.initState();
    // _getAppVersion(); // Bỏ comment nếu dùng package_info_plus
  }

  // Hàm lấy version tự động (cần package_info_plus)
    /* Future<void> _getAppVersion() async {
     PackageInfo packageInfo = await PackageInfo.fromPlatform();
     setState(() {
      _appVersion = packageInfo.version;
     });
   }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giới thiệu ứng dụng'),
        backgroundColor: Colors.orange[700], // Màu cam
        foregroundColor: Colors.white,
      ),
      body: ListView( // Dùng ListView để nội dung dài có thể cuộn
        padding: const EdgeInsets.all(24.0),
        children: <Widget>[
          // 1. Logo App
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Image.asset(
                'assets/logo.png', // Đường dẫn logo
                height: 100, // Kích thước logo
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.work_outline_rounded, // Icon dự phòng
                  size: 100,
                  color: Colors.orange[300],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Tên App và Version
          Center(
            child: Text(
              'Quản Lý Việc Làm',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
            ),
          ),
          Center(
            child: Text(
              'Phiên bản $_appVersion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // 3. Mô tả ứng dụng
          Text(
            'Mô tả',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ứng dụng Quản Lý Việc Làm được xây dựng nhằm mục đích kết nối hiệu quả giữa nhà tuyển dụng và ứng viên tiềm năng. Các tính năng chính bao gồm:\n'
            '• Đăng tin tuyển dụng nhanh chóng.\n'
            '• Tìm kiếm việc làm thông minh.\n'
            '• Quản lý hồ sơ ứng viên và CV.\n'
            '• Lưu trữ và theo dõi các công việc yêu thích/đã ứng tuyển.\n'
            '• Cập nhật thông tin cá nhân và ảnh đại diện.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5, // Giãn dòng
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 24),

          // 4. Thông tin nhà phát triển (Tùy chọn)
          Text(
            'Nhà phát triển',
             style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ứng dụng được phát triển bởi [Tên của bạn hoặc Team].', // <-- Sửa tên bạn vào đây
             style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[800],
                ),
          ),
          // Thêm liên hệ nếu muốn
           InkWell(
            onTap: () { /* Mở link email/website */ },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái
              children: [
                Text( // <-- Text thứ nhất
                  'Liên hệ: tranhuynhsang1204@gmail.com',
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
                 const SizedBox(height: 4), // Thêm khoảng cách nhỏ
                 Text( // <-- Text thứ hai
                  'SĐT: 0944924860',
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ],
           ), 
           ),
          const SizedBox(height: 24),
           

          // 5. Nút xem Licenses
          Center(
            child: TextButton(
              onPressed: () {
                // Mở màn hình Licenses mặc định của Flutter
                showLicensePage(
                  context: context,
                  applicationName: 'Quản Lý Việc Làm',
                  applicationVersion: _appVersion,
                  applicationIcon: Padding( // Icon cho trang Licenses
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset('assets/logo.png', height: 40)
                  ),
                  // applicationLegalese: 'Bản quyền © 2025 [Tên của bạn]', // Thêm nếu muốn
                );
              },
              child: Text(
                  'Xem giấy phép phần mềm',
                   style: TextStyle(color: Colors.orange[800]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}