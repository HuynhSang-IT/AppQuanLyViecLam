// screens/post_job_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Đã thêm import
import '../models/job_model.dart';
import '../services/job_service.dart';

class PostJobScreen extends StatefulWidget {
  final Job? existingJob;
  const PostJobScreen({Key? key, this.existingJob}) : super(key: key);

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final JobService _jobService = JobService();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();

  String _selectedJobType = 'Toàn thời gian';
  String _selectedLevel = 'Nhân viên';
  bool _isLoading = false;

  bool _isEditing = false;
  Job? _existingJob;

  final List<String> _jobTypes = [
    'Toàn thời gian', 'Bán thời gian', 'Thực tập', 'Freelance',
  ];
  final List<String> _levels = [
    'Thực tập sinh', 'Nhân viên', 'Trưởng nhóm', 'Quản lý', 'Giám đốc',
  ];

  @override
  void initState() {
    super.initState();
    _existingJob = widget.existingJob;
    if (_existingJob != null) {
      _isEditing = true;
      _titleController.text = _existingJob!.title;
      _companyController.text = _existingJob!.company;
      _locationController.text = _existingJob!.location;
      _salaryController.text = _existingJob!.salary;
      _descriptionController.text = _existingJob!.description;
      _requirementsController.text = _existingJob!.requirements ?? '';
      _benefitsController.text = _existingJob!.benefits ?? '';
      _selectedJobType = _existingJob!.jobType ?? 'Toàn thời gian';
      _selectedLevel = _existingJob!.level ?? 'Nhân viên';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  void _handlePostJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không được xác thực. Vui lòng đăng nhập lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    Map<String, dynamic> jobData = {
      'title': _titleController.text,
      'company': _companyController.text,
      'location': _locationController.text,
      'salary': _salaryController.text,
      'description': _descriptionController.text,
      'requirements': _requirementsController.text,
      'benefits': _benefitsController.text.isNotEmpty ? _benefitsController.text : 'Không có',
      'jobType': _selectedJobType,
      'level': _selectedLevel,
      'postedBy': user.uid,
    };

    try {
      Map<String, dynamic> response;
      if (_isEditing) {
        jobData['updatedAt'] = FieldValue.serverTimestamp();
        response = await _jobService.updateJob(_existingJob!.id, jobData);
      } else {
        response = await _jobService.addJob(
          title: jobData['title'],
          company: jobData['company'],
          location: jobData['location'],
          salary: jobData['salary'],
          description: jobData['description'],
          requirements: jobData['requirements'],
          benefits: jobData['benefits'],
          jobType: jobData['jobType'],
          level: jobData['level'],
          userId: jobData['postedBy'],
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] as String),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
        if (response['success']) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa Việc Làm' : 'Đăng Việc Làm'),
        // --- THÊM MÀU CAM ---
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 1, // Thêm shadow nhẹ
        // --- KẾT THÚC THÊM ---
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[300]!],
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditing ? 'Chỉnh sửa tin tuyển dụng' : 'Đăng tin tuyển dụng mới',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Điền thông tin chi tiết để thu hút ứng viên',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Thông tin cơ bản'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Tiêu đề công việc',
                      icon: Icons.title,
                      hint: 'VD: Lập trình viên Flutter Senior',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tiêu đề';
                        }
                        return null;
                      },
                      
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _companyController,
                      label: 'Tên công ty',
                      icon: Icons.business,
                      hint: 'VD: Công ty TNHH ABC',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên công ty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Hình thức',
                            value: _selectedJobType,
                            items: _jobTypes,
                            onChanged: (value) {
                              setState(() {
                                _selectedJobType = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Cấp bậc',
                            value: _selectedLevel,
                            items: _levels,
                            onChanged: (value) {
                              setState(() {
                                _selectedLevel = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _locationController,
                      label: 'Địa điểm',
                      icon: Icons.location_on,
                      hint: 'VD: Hà Nội, Việt Nam',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập địa điểm';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _salaryController,
                      label: 'Mức lương',
                      icon: Icons.attach_money,
                      hint: 'VD: 15-25 triệu',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mức lương';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Mô tả công việc'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Mô tả chi tiết',
                      icon: Icons.description,
                      hint: 'Mô tả chi tiết về công việc...',
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mô tả';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _requirementsController,
                      label: 'Yêu cầu ứng viên',
                      icon: Icons.checklist,
                      hint: 'Liệt kê các yêu cầu...',
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập yêu cầu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _benefitsController,
                      label: 'Quyền lợi',
                      icon: Icons.card_giftcard,
                      hint: 'Các quyền lợi cho ứng viên...',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 32),

                    // Submit button (ĐỔI MÀU)
                    SizedBox(
                      width: double.infinity,
                      height: 55, // To hơn
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handlePostJob,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700], // <-- MÀU CAM
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row( // <-- Đã xóa CONST ở đây
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_isEditing ? Icons.save : Icons.publish), // <-- Dùng biến, không 'const'
                                  const SizedBox(width: 8),
                                  Text(
                                    _isEditing ? 'Lưu Thay Đổi' : 'Đăng Việc Làm', // <-- Dùng biến, không 'const'
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {Navigator.pop(context);},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600], // Màu chữ xám
                          side: BorderSide(color: Colors.grey[300]!), // Viền xám nhạt
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Hủy',style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration( // <-- Đã xóa CONST (nếu có)
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration( // <-- Đã xóa CONST (nếu có)
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}