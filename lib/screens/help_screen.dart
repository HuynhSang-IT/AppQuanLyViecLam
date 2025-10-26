import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Nếu cần mở link

Future<void> launchURL(String urlString, BuildContext context) async {
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
     // Only show SnackBar if the widget is still mounted
     if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Không thể mở liên kết: $urlString'), backgroundColor: Colors.red),
       );
     }
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ giúp & Hỗ trợ'),
        backgroundColor: Colors.orange[700], // Màu cam
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          _buildSectionTitle(context, 'Câu hỏi thường gặp (FAQ)'),
          const SizedBox(height: 16),
          _buildExpansionTile(
            context,
            title: 'Làm thế nào để đăng tin tuyển dụng?',
            content:
                '1. Từ menu chính (Drawer), chọn "Đăng việc làm".\n'
                '2. Điền đầy đủ thông tin chi tiết về công việc (Tiêu đề, Công ty, Mô tả, Yêu cầu...). Bắt buộc điền các trường có dấu *.\n'
                '3. Nhấn nút "Đăng Việc Làm" ở cuối trang.\n'
                'Tin đăng của bạn sẽ xuất hiện trên trang chủ.',
          ),
          _buildExpansionTile(
            context,
            title: 'Làm thế nào để ứng tuyển một công việc?',
            content:
                '1. Tại trang chủ hoặc trang chi tiết công việc, tìm đến công việc bạn muốn ứng tuyển.\n'
                '2. Nhấn vào thẻ công việc để xem chi tiết (nếu ở trang chủ) hoặc cuộn xuống dưới.\n'
                '3. Nhấn nút "Ứng tuyển ngay".\n'
                '4. (Tương lai) Có thể yêu cầu bạn nhập thêm thư giới thiệu hoặc xác nhận CV.\n'
                'Nhà tuyển dụng sẽ nhận được thông báo về đơn ứng tuyển của bạn.',
          ),
          _buildExpansionTile(
            context,
            title: 'Làm sao để cập nhật hồ sơ cá nhân/CV?',
            content:
                '1. Mở menu chính (Drawer), chọn "Cài đặt".\n'
                '2. Tại màn hình "Cài đặt Hồ sơ", bạn có thể:\n'
                '   - Nhấn vào ảnh đại diện hoặc icon camera để thay đổi ảnh.\n'
                '   - Sửa lại "Họ và tên", "Số điện thoại".\n'
                '   - Trong mục "Quản lý CV", nhấn "Chọn CV" hoặc "Thay thế CV" để tải lên file mới (PDF, DOC, DOCX).\n'
                '   - Nhấn "Xóa CV" nếu muốn gỡ bỏ CV hiện tại.\n'
                '3. Nhấn nút "Lưu thay đổi" để cập nhật thông tin.',
          ),
          // Thêm các câu hỏi FAQ khác nếu cần
          // _buildExpansionTile(context, title: '...', content: '...'),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Liên hệ hỗ trợ'),
          const SizedBox(height: 16),

         _buildContactItem(
            context,
            icon: Icons.email_outlined,
            text: 'tranhuynhsang1204@gmail.com',
            onTap: () {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'tranhuynhsang1204@gmail.com',
                query: 'subject=[Hỗ trợ App Việc Làm] Tiêu đề yêu cầu',
              );
              // --- 3. GỌI HÀM ĐÃ SỬA TÊN ---
              launchURL(emailLaunchUri.toString(), context);
            },
          ),
          _buildContactItem(
            context,
            icon: Icons.phone_outlined,
            text: '0944924860',
            onTap: () {
               final Uri phoneLaunchUri = Uri(scheme: 'tel', path: '0944924860');
               // --- 3. GỌI HÀM ĐÃ SỬA TÊN ---
               launchURL(phoneLaunchUri.toString(), context);
            },
          ),
            // --- 2. THÊM ZALO VÀ FACEBOOK ---
          _buildContactItem(
            context,
            icon: Icons.message_outlined, // Zalo Icon
            text: 'Zalo: 0944924860', // Sửa SĐT Zalo
            onTap: () {
              // --- 3. GỌI HÀM ĐÃ SỬA TÊN ---
              launchURL('https://zalo.me/0944924860', context); // Sửa link Zalo
            },
          ),
          _buildContactItem(
            context,
            icon: Icons.facebook, // Facebook Icon
            text: 'Facebook: Huỳnh Sang', // Sửa tên FB
            onTap: () {
              // --- 3. GỌI HÀM ĐÃ SỬA TÊN ---
              launchURL('https://www.facebook.com/share/1BbadeFLSc/?mibextid=wwXIfr', context); // Sửa link FB
            },
          ),
          // Thêm kênh liên hệ khác nếu muốn (Website, Facebook...)
        ],
      ),
    );
  }

  // Widget helper cho tiêu đề mục
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.orange[800],
          ),
    );
  }

  // Widget helper cho câu hỏi FAQ (có thể xổ ra/đóng vào)
  Widget _buildExpansionTile(BuildContext context, {required String title, required String content}) {
    return Card( // Bọc trong Card cho đẹp hơn
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
        expandedCrossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái nội dung
        children: <Widget>[
          Text(content, style: TextStyle(color: Colors.grey[700], height: 1.4)),
        ],
      ),
    );
  }

  // Widget helper cho thông tin liên hệ
  Widget _buildContactItem(BuildContext context, {required IconData icon, required String text, VoidCallback? onTap}) {
     return ListTile(
       leading: Icon(icon, color: Colors.orange[700]),
       title: Text(text),
       onTap: onTap,
       contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
       dense: true, // Giảm chiều cao ListTile
     );
  }
}