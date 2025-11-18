// screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../main.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _imageFile;
  Uint8List? _webImageData;
  String? _currentAvatarUrl;

  File? _cvFile;
  String? _currentCvFileName;
  bool _isUploadingCv = false;
  bool _isRemovingCv = false;
  bool _isLoading = false;

  late final String _userId;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _userId = _authService.currentUser?.uid ?? '';
  }

  // TẢI LẠI DỮ LIỆU MỖI KHI VÀO TRANG
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_userId.isEmpty) return;
    final data = await _authService.getUserData(_userId);
    if (mounted) {
      setState(() {
        _userData = data;
        _nameController.text = data?['name'] ?? '';
        _phoneController.text = data?['phone'] ?? '';
        _currentAvatarUrl = data?['avatarUrl'];
        _currentCvFileName = data?['cvFileName'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _webImageData = bytes;
        _imageFile = null;
      });
    } else {
      setState(() {
        _imageFile = File(picked.path);
        _webImageData = null;
      });
    }
  }

  Future<void> _pickCvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result?.files.single.path == null) return;

    setState(() {
      _cvFile = File(result!.files.single.path!);
      _currentCvFileName = null;
    });
  }

  Future<void> _removeCvFile() async {
    if (_userId.isEmpty) return;
    setState(() => _isRemovingCv = true);

    final success = await _authService.updateUserData(
      uid: _userId,
      cvUrl: "",
      cvFileName: "",
    );

    if (success) await _loadUserData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Đã xóa CV!' : 'Xóa thất bại'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
    setState(() => _isRemovingCv = false);
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate() || _userId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _isUploadingCv = _cvFile != null;
    });

    String? finalAvatarUrl = _currentAvatarUrl;
    String? finalCvUrl = _userData?['cvUrl'];
    String? finalCvFileName = _currentCvFileName;

    if (_imageFile != null || _webImageData != null) {
      final newAvatarUrl = await _storageService.uploadAvatar(
        file: _imageFile,
        webImage: _webImageData,
        userId: _userId,
        oldAvatarUrl: _currentAvatarUrl,
      );

      if (newAvatarUrl == null) {
        _showError('Upload ảnh thất bại');
        return;
      }
      finalAvatarUrl = newAvatarUrl;
    }

    if (_cvFile != null) {
      final result = await _storageService.uploadCvFile(_cvFile!, _userId);
      if (result == null) {
        _showError('Upload CV thất bại');
        return;
      }
      finalCvUrl = result['url'];
      finalCvFileName = result['fileName'];
    }

    final success = await _authService.updateUserData(
      uid: _userId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      avatarUrl: finalAvatarUrl,
      cvUrl: finalCvUrl,
      cvFileName: finalCvFileName,
    );

    if (success) {
      _imageFile = null;
      _webImageData = null;
      _cvFile = null;
      await _loadUserData();
      _showSuccess('Cập nhật thành công!');
    } else {
      _showError('Cập nhật thất bại');
    }

    setState(() {
      _isLoading = false;
      _isUploadingCv = false;
    });
  }

  void _showSuccess(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
        _isUploadingCv = false;
      });
    }
  }

  ImageProvider? _getImageProvider() {
    if (kIsWeb && _webImageData != null) return MemoryImage(_webImageData!);
    if (!kIsWeb && _imageFile != null) return FileImage(_imageFile!);
    if (_currentAvatarUrl?.isNotEmpty == true) return NetworkImage(_currentAvatarUrl!);
    return null;
  }

  Future<void> _viewCv() async {
    final url = _userData?['cvUrl'];
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
    }

    final displayCvName = _cvFile?.path.split('/').last ?? _currentCvFileName;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[700],
        title: const Text('Hồ sơ', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        // AVATAR
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 70,
                backgroundColor: Colors.orange[100],
                backgroundImage: _getImageProvider(),
                child: _getImageProvider() == null
                    ? Icon(Icons.person_outline, size: 70, color: Colors.orange[300])
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[600],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // FORM
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin cá nhân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 20),
                  _textField(_nameController, 'Họ và tên', Icons.person_outline, (v) => v!.trim().isEmpty ? 'Nhập tên' : null),
                  const SizedBox(height: 16),
                  _textField(TextEditingController(text: _userData?['email']), 'Email', Icons.email_outlined, null, readOnly: true),
                  const SizedBox(height: 16),
                  _textField(_phoneController, 'Số điện thoại', Icons.phone_outlined, (v) => v!.trim().isEmpty ? 'Nhập SĐT' : null),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // CV
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quản lý CV', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.description_outlined, color: Colors.orange[700]),
                  title: Text(
                    displayCvName?.isNotEmpty == true ? displayCvName! : 'Chưa có CV',
                    style: TextStyle(color: displayCvName?.isNotEmpty == true ? Colors.black87 : Colors.grey[600]),
                  ),
                  trailing: (_userData?['cvUrl']?.isNotEmpty == true)
                      ? IconButton(icon: const Icon(Icons.open_in_new), onPressed: _viewCv)
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (displayCvName?.isNotEmpty == true || _cvFile != null)
                      TextButton.icon(
                        onPressed: _isRemovingCv ? null : _removeCvFile,
                        icon: _isRemovingCv
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.delete_outline, color: Colors.red),
                        label: Text(_cvFile != null ? 'Hủy' : 'Xóa', style: const TextStyle(color: Colors.red)),
                      ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isUploadingCv ? null : _pickCvFile,
                      icon: _isUploadingCv
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(displayCvName?.isNotEmpty == true ? Icons.sync_alt : Icons.upload_file),
                      label: Text(displayCvName?.isNotEmpty == true ? 'Thay CV' : 'Chọn CV'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600], foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        // === NÚT CHUYỂN ĐỔI GIAO DIỆN (MỚI) ===
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        // Kiểm tra xem hiện tại có đang tối không
        bool isDark = mode == ThemeMode.dark || 
            (mode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

        return SwitchListTile(
          title: const Text('Chế độ tối (Dark Mode)', style: TextStyle(fontWeight: FontWeight.bold)),
          secondary: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: isDark ? Colors.yellow : Colors.orange,
          ),
          value: isDark,
          onChanged: (val) {
            // Đổi giá trị của biến toàn cục -> App tự cập nhật
            themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
          },
        );
      },
    ),
  ),
),
// =======================================
const SizedBox(height: 20),

        // LƯU
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleUpdateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Lưu thay đổi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _textField(TextEditingController controller, String label, IconData icon, String? Function(String?)? validator, {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange[400]),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.orange[400]!, width: 1.5)),
      ),
      validator: validator,
    );
  }
}