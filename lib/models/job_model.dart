class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final String description;
  final DateTime postedDate;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.description,
    required this.postedDate,
  });

  int getDaysAgo() {
    final difference = DateTime.now().difference(postedDate);
    return difference.inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'salary': salary,
      'description': description,
      'postedDate': postedDate.toIso8601String(),
    };
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      title: json['title'],
      company: json['company'],
      location: json['location'],
      salary: json['salary'],
      description: json['description'],
      postedDate: DateTime.parse(json['postedDate']),
    );
  }
}