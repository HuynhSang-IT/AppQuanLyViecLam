import 'package:flutter/material.dart';
import '../services/auth_service.dart';
//import 'package{packageName}/{projectName}/lib/widgets/custom_drawer.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Drawer(
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[700]!, Colors.orange[300]!],
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.orange,
              ),
            ),
            accountName: Text(
              user?.displayName ?? 'Người dùng',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? ''),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.home_outlined,
                  title: 'Trang chủ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.work_outline,
                  title: 'Việc làm của tôi',
                  onTap: () {
                    Navigator.pop(context); // Đóng Drawer
                    Navigator.pushNamed(context, '/my_jobs'); // Mở màn hình mới
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.add_circle_outline,
                  title: 'Đăng việc làm',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/post_job');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.bookmark_border,
                  title: 'Việc làm đã lưu',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/saved_jobs');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people_outline,
                  title: 'Ứng Tuyển',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/my_applications');
                  },
                ),
                const Divider(),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Cài đặt',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Trợ giúp',
                  onTap: () {
                    // === THAY ĐỔI Ở ĐÂY ===
                    Navigator.pop(context); // Đóng drawer
                    Navigator.pushNamed(context, '/help'); // Mở màn hình mới
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'Giới thiệu',
                  onTap: () {
                    // === THAY ĐỔI Ở ĐÂY ===
                    Navigator.pop(context); // Đóng drawer
                    Navigator.pushNamed(context, '/about'); // Mở màn hình mới
                  },
                ),
              ],
            ),
          ),

          // Logout button
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                _showLogoutDialog(context, authService);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authService.signOut();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Quản Lý Việc Làm',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.work, size: 50, color: Colors.blue),
      children: [
        const Text(
          'Ứng dụng quản lý việc làm giúp kết nối nhà tuyển dụng và người tìm việc.',
        ),
      ],
    );
  }
}