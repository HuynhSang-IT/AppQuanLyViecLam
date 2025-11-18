import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. ĐĂNG VIỆC LÀM MỚI
  Future<Map<String, dynamic>> addJob({
    required String title,
    required String company,
    required String location,
    required String salary,
    required String description,
    required String requirements,
    required String benefits,
    required String jobType,
    required String level,
    required String userId,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('jobs').add({
        'title': title,
        'title_lowercase': title.toLowerCase(),
        'company': company,
        'location': location,
        'salary': salary,
        'description': description,
        'requirements': requirements,
        'benefits': benefits,
        'jobType': jobType,
        'level': level,
        'postedBy': userId,
        'postedDate': FieldValue.serverTimestamp(),
        'status': 'active',
        'viewCount': 0,
        'applicationCount': 0,
      });

      // === ĐOẠN MỚI THÊM VÀO: TỰ ĐỘNG CẬP NHẬT DANH SÁCH ĐỊA ĐIỂM ===
      // arrayUnion giúp chỉ thêm nếu chưa có (tránh trùng lặp)
      await _firestore.collection('attributes').doc('locations').set({
        'values': FieldValue.arrayUnion([location])
      }, SetOptions(merge: true));
      // === KẾT THÚC ĐOẠN MỚI ===
      
      return {
        'success': true,
        'message': 'Đăng việc làm thành công!',
        'jobId': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  // 2. LẤY TẤT CẢ VIỆC LÀM
  Stream<List<Job>> getAllJobs() {
    return _firestore
        .collection('jobs')
        .orderBy('postedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        
        // Xử lý Timestamp
        if (data['postedDate'] is Timestamp) {
          data['postedDate'] = (data['postedDate'] as Timestamp).toDate();
        } else {
          data['postedDate'] = DateTime.now();
        }
        
        // Lọc chỉ lấy active jobs
        if (data['status'] == 'active' || data['status'] == null) {
          return Job.fromFirestore(data);
        }
        return null;
      }).whereType<Job>().toList();
    });
  }

  // 3. LẤY VIỆC LÀM CỦA USER
  Stream<List<Job>> getJobsByUser(String userId) {
    return _firestore
        .collection('jobs')
        .where('postedBy', isEqualTo: userId)
        .orderBy('postedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        
        if (data['postedDate'] is Timestamp) {
          data['postedDate'] = (data['postedDate'] as Timestamp).toDate();
        } else {
          data['postedDate'] = DateTime.now();
        }
        
        return Job.fromFirestore(data);
      }).toList();
    });
  }

  // 4. LẤY VIỆC LÀM (CÓ TÌM KIẾM + BỘ LỌC)
  Stream<List<Job>> getJobsStream({
    String query = '',
    String? location,
    String? jobType,
    String? level,
  }) {
    // Bắt đầu với một truy vấn cơ bản
    Query jobsQuery = _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'active'); // <-- Luôn lọc 'status' trước

    // --- LOGIC LỌC MỚI ---  
    // Thêm các bộ lọc nếu chúng được cung cấp
    if (location != null && location.isNotEmpty) {
      jobsQuery = jobsQuery.where('location', isEqualTo: location);
    }
    if (jobType != null && jobType.isNotEmpty) {
      jobsQuery = jobsQuery.where('jobType', isEqualTo: jobType);
    }
    if (level != null && level.isNotEmpty) {
      jobsQuery = jobsQuery.where('level', isEqualTo: level);
    }
    // --- KẾT THÚC LOGIC LỌC ---

    if (query.isNotEmpty) {
      String queryLower = query.toLowerCase();
      // NẾU CÓ TÌM KIẾM:
      jobsQuery = jobsQuery
          .orderBy('title_lowercase')
          .where('title_lowercase', isGreaterThanOrEqualTo: queryLower)
          .where('title_lowercase', isLessThanOrEqualTo: '$queryLower\uf8ff')
          .orderBy('postedDate', descending: true); // Sắp xếp phụ
    } else {
      // NẾU KHÔNG TÌM KIẾM:
      jobsQuery = jobsQuery.orderBy('postedDate', descending: true);
    }

    // Phần .map() còn lại giữ nguyên
    return jobsQuery.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        if (data['postedDate'] is Timestamp) {
          data['postedDate'] = (data['postedDate'] as Timestamp).toDate();
        } else {
          data['postedDate'] = DateTime.now();
        }
        
        return Job.fromFirestore(data);
      }).toList();
    });
  }

  // 5. XÓA VIỆC LÀM
  Future<bool> deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // 6. CẬP NHẬT TRẠNG THÁI VIỆC LÀM
  Future<bool> updateJobStatus(String jobId, String status) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': status,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // 7. TĂNG SỐ LƯỢT XEM
  Future<void> incrementViewCount(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Ignore error
    }
  }

  // 8. LƯU VIỆC YÊU THÍCH
  Future<bool> toggleFavorite(String userId, String jobId) async {
    try {
      DocumentReference favRef = _firestore.collection('favorites').doc(userId);
      DocumentSnapshot favDoc = await favRef.get();

      if (favDoc.exists) {
        Map<String, dynamic> data = favDoc.data() as Map<String, dynamic>;
        List<dynamic> jobs = data['jobIds'] ?? [];

        if (jobs.contains(jobId)) {
          jobs.remove(jobId);
        } else {
          jobs.add(jobId);
        }

        await favRef.update({'jobIds': jobs});
      } else {
        await favRef.set({
          'jobIds': [jobId],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // 9. LẤY DANH SÁCH YÊU THÍCH
  Future<List<String>> getFavoriteJobIds(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('favorites').doc(userId).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> jobs = data['jobIds'] ?? [];
        return jobs.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 10. ỨNG TUYỂN VIỆC LÀM
  Future<Map<String, dynamic>> applyJob({
    required String jobId,
    required String userId,
    required String coverLetter,
  }) async {
    try {
      // Kiểm tra đã ứng tuyển chưa
      QuerySnapshot existingApp = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('userId', isEqualTo: userId)
          .get();

      if (existingApp.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Bạn đã ứng tuyển việc làm này rồi!',
        };
      }

      // Tạo đơn ứng tuyển mới
      await _firestore.collection('applications').add({
        'jobId': jobId,
        'userId': userId,
        'coverLetter': coverLetter,
        'appliedDate': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Tăng số lượng ứng tuyển
      await _firestore.collection('jobs').doc(jobId).update({
        'applicationCount': FieldValue.increment(1),
      });

      return {
        'success': true,
        'message': 'Ứng tuyển thành công!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  // 11. LẤY DANH SÁCH ỨNG TUYỂN CỦA USER
  Stream<List<Map<String, dynamic>>> getUserApplications(String userId) {
    return _firestore
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .orderBy('appliedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // 12. CẬP NHẬT VIỆC LÀM
  Future<Map<String, dynamic>> updateJob(String jobId, Map<String, dynamic> data) async {
    try {
      // Thêm trường lowercase vào data trước khi update
      if (data.containsKey('title')) {
        data['title_lowercase'] = (data['title'] as String).toLowerCase();
      }

      await _firestore.collection('jobs').doc(jobId).update(data);
      return {
        'success': true,
        'message': 'Cập nhật việc làm thành công!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: $e',
      };
    }
  }

  // 12. CẬP NHẬT TRẠNG THÁI ỨNG TUYỂN
  Future<bool> updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      await _firestore
          .collection('applications')
          .doc(applicationId)
          .update({'status': newStatus});
      return true;
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái ứng tuyển: $e');
      return false;
    }
  }

  // 13. LẤY CHI TIẾT CÁC VIỆC LÀM ĐÃ LƯU
  Future<List<Job>> getFavoriteJobs(String userId) async {
    try {
      // 1. Lấy danh sách các ID job đã lưu
      final List<String> jobIds = await getFavoriteJobIds(userId);

      if (jobIds.isEmpty) {
        return []; // Trả về danh sách rỗng nếu chưa lưu gì
      }

      // 2. Lấy thông tin chi tiết của các job
      // Dùng truy vấn 'whereIn' để lấy tất cả job có ID nằm trong danh sách
      final QuerySnapshot jobSnapshot = await _firestore
          .collection('jobs')
          .where(FieldPath.documentId, whereIn: jobIds)
          .get();

      // 3. Chuyển đổi data sang Job models
      return jobSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        if (data['postedDate'] is Timestamp) {
          data['postedDate'] = (data['postedDate'] as Timestamp).toDate();
        } else {
          data['postedDate'] = DateTime.now();
        }
        
        return Job.fromFirestore(data);
      }).toList();

    } catch (e) {
      print('Lỗi khi lấy việc làm đã lưu: $e');
      return [];
    }
  }

  // 14. LẤY DANH SÁCH ỨNG VIÊN CỦA 1 JOB
  Stream<List<Map<String, dynamic>>> getApplicantsForJob(String jobId) {
    return _firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .orderBy('appliedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  //15. Stream lấy danh sách đơn ứng tuyển CỦA APPLICANT
Stream<List<Map<String, dynamic>>> getMyApplications(String userId) {
  return _firestore
      .collection('applications')
      .where('userId', isEqualTo: userId)
      .orderBy('appliedDate', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  });
}

// --- 16 THÊM HÀM NÀY ĐỂ LẤY DANH SÁCH ĐỊA ĐIỂM ---
  Stream<List<String>> getLocationsStream() {
    return _firestore
        .collection('attributes') // Tạo một collection riêng tên là attributes
        .doc('locations')         // Một document tên là locations
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // Lấy mảng 'values' ra và chuyển thành List<String>
        return List<String>.from(snapshot.data()!['values'] ?? []);
      }
      return ['Cần Thơ', 'Hà Nội', 'Hồ Chí Minh']; // Dữ liệu mặc định nếu chưa có gì
    });
  }
}
