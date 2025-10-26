class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final String description;
  final DateTime postedDate;
  final String? requirements;
  final String? benefits;
  final String? jobType;
  final String? level;
  final String? postedBy;
  final String? status;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.description,
    required this.postedDate,
    this.requirements,
    this.benefits,
    this.jobType,
    this.level,
    this.postedBy,
    this.status,
  });

  String getPostedDateAgo() {
    final difference = DateTime.now().difference(postedDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  // Tạo Job từ Firestore
  factory Job.fromFirestore(Map<String, dynamic> data) {
    return Job(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      location: data['location'] ?? '',
      salary: data['salary'] ?? '',
      description: data['description'] ?? '',
      postedDate: data['postedDate'] ?? DateTime.now(),
      requirements: data['requirements'],
      benefits: data['benefits'],
      jobType: data['jobType'],
      level: data['level'],
      postedBy: data['postedBy'],
      status: data['status'] ?? 'active',
    );
  }

  // Chuyển Job thành Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'location': location,
      'salary': salary,
      'description': description,
      'postedDate': postedDate,
      'requirements': requirements,
      'benefits': benefits,
      'jobType': jobType,
      'level': level,
      'postedBy': postedBy,
      'status': status,
    };
  }
}