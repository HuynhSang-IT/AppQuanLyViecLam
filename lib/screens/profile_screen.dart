// screens/profile_screen.dart (ĐÃ THÊM QUẢN LÝ CV)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // <-- 1. IMPORT FILE PICKER
import '../services/auth_service.dart';
import '../services/storage_service.dart';
//Optional: Import url_launcher để mở CV sau này
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Để kiểm tra nền tảng web
import 'dart:typed_data'; // Để dùng Uint8List cho ảnh web

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

  File? _imageFile; // Dùng cho mobile
  Uint8List? _webImageData; // dung cho web
  String? _currentAvatarUrl;

  // Hàm helper để lấy ImageProvider phù hợp
ImageProvider? _getImageProvider() {
  // Ưu tiên 1: Ảnh mới chọn trên web
  if (kIsWeb && _webImageData != null) {
    return MemoryImage(_webImageData!);
  }
  // Ưu tiên 2: Ảnh mới chọn trên mobile
  else if (!kIsWeb && _imageFile != null) {
    return FileImage(_imageFile!);
  }
  // Ưu tiên 3: Ảnh cũ từ URL
  else if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
    return NetworkImage(_currentAvatarUrl!);
  }
  // Mặc định: Không có ảnh
  else {
    return null;
  }
}

  // --- 2. THÊM BIẾN STATE CHO CV ---
  File? _cvFile; // File CV mới chọn (nếu có)
  String? _currentCvFileName; // Tên file CV hiện tại lấy từ Firebase
  bool _isUploadingCv = false; // Trạng thái đang upload CV
  bool _isRemovingCv = false; // Trạng thái đang xử lý xóa CV
  // --- KẾT THÚC THÊM BIẾN ---

  bool _isLoading = false; // Trạng thái loading chung (lưu profile)
  late final String _userId;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _userId = _authService.currentUser?.uid ?? '';
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_userId.isNotEmpty) {
      _userData = await _authService.getUserData(_userId);
      if (_userData != null) {
        _nameController.text = _userData!['name'] ?? '';
        _phoneController.text = _userData!['phone'] ?? '';
        _currentAvatarUrl = _userData!['avatarUrl'];
        // --- 3. LẤY TÊN FILE CV HIỆN TẠI ---
        _currentCvFileName = _userData!['cvFileName'];
        // --- KẾT THÚC LẤY TÊN FILE ---
        if (mounted) { setState(() {}); }
      }
    }
  }

  Future<void> _pickImage() async {
  print("--- Bắt đầu chọn ảnh ---");
  final ImagePicker picker = ImagePicker();
  try {
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      print("--- Đã chọn file: ${pickedFile.name} ---"); // Dùng .name cho web/mobile

      if (kIsWeb) {
        // --- XỬ LÝ CHO WEB ---
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageData = bytes; // Lưu dữ liệu ảnh web
          _imageFile = null;     // Reset file mobile (nếu có)
        });
        print("--- Đã đọc ${bytes.lengthInBytes} bytes cho web ---");
        // --- KẾT THÚC XỬ LÝ WEB ---
      } else {
        // --- XỬ LÝ CHO MOBILE ---
        setState(() {
          _imageFile = File(pickedFile.path); // Lưu file mobile
          _webImageData = null;    // Reset data web (nếu có)
        });
        print("--- Đã lưu file mobile: ${pickedFile.path} ---");
        // --- KẾT THÚC XỬ LÝ MOBILE ---
      }
    } else {
      print("--- Người dùng đã hủy chọn ảnh ---");
    }
  } catch (e) {
    print("--- Lỗi khi chọn ảnh: $e ---");
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Không thể truy cập thư viện ảnh: $e'), backgroundColor: Colors.red),
       );
     }
  }
}

  // --- 4. HÀM CHỌN FILE CV ---
  Future<void> _pickCvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'], // Chỉ cho chọn các loại file này
      );

      if (result != null) {
        setState(() {
          _cvFile = File(result.files.single.path!); // Lưu file đã chọn
          _currentCvFileName = null; // Reset tên file cũ khi chọn file mới
        });
        print('Đã chọn CV: ${result.files.single.name}');
      } else {
        // User canceled the picker
        print('Hủy chọn file CV');
      }
    } catch (e) {
       print('Lỗi khi chọn file CV: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Không thể chọn file. Vui lòng thử lại.'), backgroundColor: Colors.red),
         );
       }
    }
  }
  // --- KẾT THÚC HÀM CHỌN CV ---

  // --- 5. HÀM XỬ LÝ XÓA CV ---
  Future<void> _removeCvFile() async {
     if (_userId.isEmpty) return;
     // Chỉ xóa khi đang có CV cũ hoặc đã chọn CV mới (để hủy chọn)
     if ((_currentCvFileName != null && _currentCvFileName!.isNotEmpty) || _cvFile != null) {
        setState(() { _isRemovingCv = true; });

        // Gọi AuthService để cập nhật cvUrl và cvFileName thành rỗng
        final bool success = await _authService.updateUserData(
          uid: _userId,
          cvUrl: "",      // Gửi chuỗi rỗng để báo hiệu xóa
          cvFileName: "", // Gửi chuỗi rỗng để báo hiệu xóa
        );

         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(success ? 'Đã xóa CV thành công!' : 'Xóa CV thất bại.'),
               backgroundColor: success ? Colors.green : Colors.red,
             ),
           );
           if(success) {
              setState(() {
                 _cvFile = null; // Reset file đã chọn (nếu có)
                 _currentCvFileName = null; // Reset tên file hiển thị
                 _userData?['cvUrl'] = ""; // Cập nhật cache local
                 _userData?['cvFileName'] = "";
              });
           }
         }
         setState(() { _isRemovingCv = false; });
     }
  }
   // --- KẾT THÚC HÀM XÓA CV ---


  // --- 6. SỬA HÀM LƯU PROFILE ---
  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) { return; }
    if (_userId.isEmpty) return;

    setState(() { _isLoading = true; _isUploadingCv = (_cvFile != null); }); // Bật loading cả 2 nếu cần

    String? finalAvatarUrl = _currentAvatarUrl;
    String? finalCvUrl = _userData?['cvUrl']; // Lấy URL CV hiện tại
    String? finalCvFileName = _currentCvFileName ?? _userData?['cvFileName']; // Lấy tên file CV hiện tại

    bool cvUploadSuccess = true; // Giả định upload CV thành công (nếu không có CV mới)

    // --- Xử lý upload ảnh (giữ nguyên) ---
    if (_imageFile != null) {
      final String destination = 'avatars/$_userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      finalAvatarUrl = await _storageService.uploadFile(_imageFile!, destination);
      if (finalAvatarUrl == null) {
        // Xử lý lỗi upload ảnh
        setState(() { _isLoading = false; _isUploadingCv = false; });
        if (mounted) { /* ... Show SnackBar lỗi ảnh ... */ }
        return;
      }
    }

    // --- Xử lý upload CV (nếu có file mới) ---
    if (_cvFile != null) {
      final uploadResult = await _storageService.uploadCvFile(_cvFile!, _userId);
      if (uploadResult != null) {
         finalCvUrl = uploadResult['url'];
         finalCvFileName = uploadResult['fileName'];
         cvUploadSuccess = true;
      } else {
         // Xử lý lỗi upload CV
         cvUploadSuccess = false;
         setState(() { _isLoading = false; _isUploadingCv = false; });
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Upload CV thất bại. Vui lòng thử lại.'), backgroundColor: Colors.red),
            );
         }
         return; // Dừng nếu upload CV lỗi
      }
    }

    // --- Cập nhật Firestore ---
    final bool profileUpdateSuccess = await _authService.updateUserData(
      uid: _userId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      avatarUrl: finalAvatarUrl,
      cvUrl: finalCvUrl,           // Truyền URL CV mới (hoặc cũ)
      cvFileName: finalCvFileName, // Truyền tên file CV mới (hoặc cũ)
    );

    // Cập nhật display name trong Auth (nếu tên đổi)
    if (profileUpdateSuccess && _nameController.text.trim() != (_userData?['name'] ?? '')) {
       await _authService.currentUser?.updateDisplayName(_nameController.text.trim());
    }

    // --- Hiển thị kết quả ---
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileUpdateSuccess ? 'Cập nhật hồ sơ thành công!' : 'Cập nhật hồ sơ thất bại.'),
          backgroundColor: profileUpdateSuccess ? Colors.green : Colors.red,
        ),
      );
      // Cập nhật state sau khi thành công
      if (profileUpdateSuccess) {
         if (_imageFile != null) _currentAvatarUrl = finalAvatarUrl;
         if (_cvFile != null) _currentCvFileName = finalCvFileName; // Cập nhật tên CV mới
         _imageFile = null; // Reset file ảnh
         _cvFile = null;    // Reset file CV
         // Cập nhật cache local
         _userData?['name'] = _nameController.text.trim();
         _userData?['phone'] = _phoneController.text.trim();
         _userData?['avatarUrl'] = finalAvatarUrl;
         _userData?['cvUrl'] = finalCvUrl;
         _userData?['cvFileName'] = finalCvFileName;
      }
    }

    setState(() { _isLoading = false; _isUploadingCv = false; });
  }
  // --- KẾT THÚC SỬA HÀM LƯU ---

  @override
  Widget build(BuildContext context) {
    // Xác định tên file CV để hiển thị (ưu tiên file mới chọn)
    final String? displayCvFileName = _cvFile?.path.split('/').last ?? _currentCvFileName;

    return Scaffold(
      appBar: AppBar( /* ... AppBar màu cam ... */ ),
      body: _userData == null && _userId.isNotEmpty
           ? const Center(child: CircularProgressIndicator(color: Colors.orange))
           : _userId.isEmpty
              ? const Center(child: Text('Không thể tải dữ liệu người dùng.'))
              : ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // --- PHẦN AVATAR ĐÃ ĐƯỢC KHÔI PHỤC ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.orange[100],
                    // --- SỬA LOGIC HIỂN THỊ ẢNH ---
                    backgroundImage: _getImageProvider(), // Gọi hàm helper mới
                    // --- KẾT THÚC SỬA ---
                    child: (_getImageProvider() == null) // Chỉ hiện icon nếu không có ảnh nào
                    ? Icon(Icons.person_outline, size: 70, color: Colors.orange[300])
                    : null,
                    /*backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) as ImageProvider
                        : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty)
                            ? NetworkImage(_currentAvatarUrl!)
                            : null,
                    child: (_imageFile == null && (_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty))
                        ? Icon(Icons.person_outline, size: 70, color: Colors.orange[300])
                        : null,*/
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[600],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.1),
                               blurRadius: 5,
                               offset: const Offset(1, 1),
                             )
                          ]
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                      ),
                    ),
                  )
                ],
              ),
            ),
            // --- KẾT THÚC PHẦN AVATAR ---
            const SizedBox(height: 32),

            // Form Thông tin cá nhân (Giữ nguyên)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Thông tin cá nhân'),
                      const SizedBox(height: 20),
                      TextFormField(controller: _nameController, decoration: _buildInputDecoration(label: 'Họ và tên', icon: Icons.person_outline), validator: (v) => v!.isEmpty ? 'Vui lòng nhập họ tên' : null),
                      const SizedBox(height: 16),
                      TextFormField(initialValue: _userData?['email'] ?? '', readOnly: true, style: TextStyle(color: Colors.grey[600]), decoration: _buildInputDecoration(label: 'Email', icon: Icons.email_outlined).copyWith(fillColor: Colors.grey[200])),
                      const SizedBox(height: 16),
                      TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _buildInputDecoration(label: 'Số điện thoại', icon: Icons.phone_outlined), validator: (v) => v!.isEmpty ? 'Vui lòng nhập số điện thoại' : null),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24), // Giảm khoảng cách

            // --- 7. THÊM PHẦN QUẢN LÝ CV ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     _buildSectionTitle('Quản lý CV'),
                     const SizedBox(height: 16),
                     // Hiển thị tên file CV hiện tại hoặc thông báo chưa có
                     ListTile(
                        leading: Icon(Icons.description_outlined, color: Colors.orange[700]),
                        title: Text(
                           (displayCvFileName != null && displayCvFileName.isNotEmpty)
                             ? displayCvFileName // Hiển thị tên file
                             : 'Chưa có CV nào được tải lên', // Thông báo
                           style: TextStyle(
                              color: (displayCvFileName != null && displayCvFileName.isNotEmpty) ? Colors.black87 : Colors.grey[600],
                              fontStyle: (displayCvFileName != null && displayCvFileName.isNotEmpty) ? FontStyle.normal : FontStyle.italic,
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                        ),
                        // Nút xem CV (nếu có URL) - Tùy chọn nâng cao
                        trailing: (_userData?['cvUrl'] != null && _userData!['cvUrl']!.isNotEmpty)
                            ? IconButton(icon: Icon(Icons.open_in_new), onPressed: _viewCv)
                            : null,
                     ),
                     const SizedBox(height: 16),
                     // Hàng chứa các nút hành động
                     Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                           // Nút Xóa CV
                           if ((displayCvFileName != null && displayCvFileName.isNotEmpty) || _cvFile != null) // Hiện nút Xóa/Hủy nếu có CV
                             TextButton.icon(
                               icon: _isRemovingCv
                                   ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                   : Icon(Icons.delete_outline, color: Colors.red[400]),
                               label: Text(
                                  _cvFile != null ? 'Hủy chọn' : 'Xóa CV', // Đổi chữ nếu đang chọn file mới
                                  style: TextStyle(color: Colors.red[400]),
                               ),
                               onPressed: _isRemovingCv ? null : _removeCvFile, // Vô hiệu hóa khi đang xử lý
                             ),

                           const Spacer(), // Đẩy nút Chọn/Thay thế ra xa

                           // Nút Chọn/Thay thế CV
                           ElevatedButton.icon(
                             icon: _isUploadingCv // Hiển thị loading nếu đang upload
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Icon((displayCvFileName != null && displayCvFileName.isNotEmpty) || _cvFile != null ? Icons.sync_alt : Icons.upload_file), // Đổi icon
                             label: Text((displayCvFileName != null && displayCvFileName.isNotEmpty) || _cvFile != null ? 'Thay thế CV' : 'Chọn CV'), // Đổi chữ
                             onPressed: _isUploadingCv ? null : _pickCvFile, // Vô hiệu hóa khi đang upload
                             style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                           ),
                        ],
                     )
                  ],
                ),
              ),
            ),
             // --- KẾT THÚC PHẦN CV ---

            const SizedBox(height: 32),
            // Nút Lưu thay đổi chung (Giữ nguyên)
            SizedBox(
              width: double.infinity, height: 55,
              // --- CODE NÚT LƯU ĐẦY ĐỦ ---
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Lưu thay đổi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
               // --- KẾT THÚC NÚT LƯU ---
            ),
            const SizedBox(height: 20),
          ],
        ),
    );
  }

  // Hàm _buildInputDecoration
  InputDecoration _buildInputDecoration({required String label, required IconData icon}) {
     // --- CODE _buildInputDecoration ĐẦY ĐỦ ---
     return InputDecoration(
       labelText: label, labelStyle: TextStyle(color: Colors.grey[600]),
       prefixIcon: Icon(icon, color: Colors.orange[400]),
       filled: true, fillColor: Colors.grey[100],
       border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[300]!)),
       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.orange[400]!, width: 1.5)),
       contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
     );
      // --- KẾT THÚC ---
  }
  // Hàm _buildSectionTitle (Giữ nguyên)
  Widget _buildSectionTitle(String title) {
     // --- CODE _buildSectionTitle ĐẦY ĐỦ ---
     return Text(
       title,
       style: TextStyle(
         fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[800],
       ),
     );
      // --- KẾT THÚC ---
   }

   // (Tùy chọn) Hàm xem CV nếu bạn muốn thêm nút xem
    Future<void> _viewCv() async {
      final cvUrl = _userData?['cvUrl'];
       if (cvUrl != null && cvUrl.isNotEmpty) {
         final uri = Uri.parse(cvUrl);
         if (await canLaunchUrl(uri)) {
           await launchUrl(uri, mode: LaunchMode.externalApplication); // Mở bằng trình duyệt/app khác
         } else {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không thể mở liên kết CV: $cvUrl'), backgroundColor: Colors.red),
           );
         }
       }
    }

} // <-- Class State kết thúc