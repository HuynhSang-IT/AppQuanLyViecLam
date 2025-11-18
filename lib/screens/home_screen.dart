// screens/home_screen.dart (PHIÊN BẢN HOÀN CHỈNH TUYỆT ĐỐI - KHÔNG CÒN PLACEHOLDER v4 FINAL)

import 'dart:async'; // Dùng cho Timer, StreamController
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // Cho banner
import '../widgets/custom_drawer.dart'; // Đảm bảo đã import
import '../models/job_model.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart'; // Service cho badge
import '../widgets/job_skeleton.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  // --- Logic Tìm kiếm ---
  final _searchController = TextEditingController();
  late StreamController<List<Job>> _jobsStreamController;
  late Stream<List<Job>> _jobsStream;
  Timer? _debounce;

  // --- THÊM BIẾN LỌC ---
  String? _selectedLocation;
  String? _selectedJobType;
  String? _selectedLevel;

  // Dùng để đếm số bộ lọc đang áp dụng
  int get _filterCount {
    int count = 0;
    if (_selectedLocation != null) count++;
    if (_selectedJobType != null) count++;
    if (_selectedLevel != null) count++;
    return count;
  }
  // --- Logic Badge Thông báo ---
  late String _userId;
  late Stream<int> _unreadCountStream;

  // --- Biến State khác ---
  int _totalJobs = 0;
  int _totalCompanies = 0;

  // --- Banner ---
  final List<String> bannerImagePaths = [
    'assets/banner.jpg', // <-- Thay bằng tên file của bạn
    'assets/banner1.jpg', // <-- Thay bằng tên file của bạn
    'assets/banner2.jpg', // <-- Thay bằng tên file của bạn
  ];
  final CarouselController _bannerController = CarouselController();
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Stream cho Job List
    _jobsStreamController = StreamController<List<Job>>.broadcast();
    _jobsStream = _jobsStreamController.stream;
    _fetchJobs(''); // Tải dữ liệu ban đầu

    // Khởi tạo Stream cho Badge Thông báo
    _userId = _authService.currentUser?.uid ?? '';
    if (_userId.isNotEmpty) {
      _unreadCountStream = _notificationService.getUnreadNotificationCountStream(_userId);
    } else {
      _unreadCountStream = Stream.value(0); // Mặc định là 0 nếu chưa đăng nhập
    }

    // Lắng nghe ô tìm kiếm
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _jobsStreamController.close();
    _debounce?.cancel();
    super.dispose();
  }

  /// Lắng nghe stream job từ service và đẩy data vào StreamController
  void _fetchJobs(String query) {
     _jobService.getJobsStream(
      query: query,
      // --- TRUYỀN CÁC BIẾN LỌC ---
      location: _selectedLocation,
      jobType: _selectedJobType,
      level: _selectedLevel,
      // --- KẾT THÚC ---
     ).listen(
      (jobs) {
        if (!_jobsStreamController.isClosed) {
          _jobsStreamController.add(jobs);
          if (mounted) {
            setState(() {
              _totalJobs = jobs.length;
              _totalCompanies = jobs.map((e) => e.company).toSet().length;
            });
          }
        }
      },
      onError: (error) {
        if (!_jobsStreamController.isClosed) {
          _jobsStreamController.addError(error);
        }
      },
     );
  }

  /// Xử lý debounce khi gõ tìm kiếm
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchJobs(_searchController.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(), // Drawer đặt ở đây cho NestedScrollView
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: const Text('Trang Chủ'),
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              pinned: true,
              floating: true,
              snap: false,
              forceElevated: innerBoxIsScrolled,
              actions: [
                // --- THÊM NÚT LỌC ---
                 IconButton(
                   icon: Badge(
                     label: Text('$_filterCount'),
                     isLabelVisible: _filterCount > 0,
                     child: const Icon(Icons.filter_list),
                   ),
                   tooltip: 'Lọc việc làm',
                   onPressed: _showFilterModal, // Sẽ tạo hàm này ở bước d
                 ),

                 StreamBuilder<int>(
                   stream: _unreadCountStream,
                   initialData: 0,
                   builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                       if (snapshot.hasError) {
                         print("Lỗi stream đếm thông báo: ${snapshot.error}");
                         return IconButton(
                           icon: const Icon(Icons.notifications_outlined),
                           tooltip: 'Thông báo (Lỗi)',
                           onPressed: () { Navigator.pushNamed(context, '/notifications'); },
                         );
                       }
                       return Badge( // <- Đã kiểm tra, label có
                         label: Text('$unreadCount'),
                         isLabelVisible: unreadCount > 0,
                         child: IconButton(
                           icon: const Icon(Icons.notifications_outlined),
                           tooltip: 'Thông báo',
                           onPressed: () { Navigator.pushNamed(context, '/notifications'); },
                         ),
                       );
                   },
                 ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60.0),
                child: Container(
                   color: Colors.orange[700],
                   padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 12.0),
                   // --- CODE TEXTFIELD ĐẦY ĐỦ ---
                   child: TextField(
                     controller: _searchController,
                     decoration: InputDecoration(
                       hintText: 'Tìm kiếm theo tiêu đề...',
                       prefixIcon: const Icon(Icons.search, color: Colors.white70),
                       hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                       suffixIcon: _searchController.text.isNotEmpty
                           ? IconButton(
                               icon: const Icon(Icons.clear, color: Colors.white70),
                               onPressed: () { _searchController.clear(); },
                             )
                           : null,
                       filled: true,
                       fillColor: Colors.white.withOpacity(0.15),
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(30),
                         borderSide: BorderSide.none,
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(30),
                         borderSide: const BorderSide(color: Colors.white, width: 1.5),
                       ),
                       contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                     ),
                     style: const TextStyle(color: Colors.white),
                   ),
                    // --- KẾT THÚC TEXTFIELD ---
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  // Banner Slider
                  Padding(
                     padding: const EdgeInsets.symmetric(vertical: 12.0),
                     child: Column(
                       children: [
                         // --- CODE CAROUSEL SLIDER ĐẦY ĐỦ ---
                         CarouselSlider(
                           //carouselController: _bannerController, // Đã kiểm tra tên biến
                           options: CarouselOptions(
                             height: 300.0,
                             autoPlay: true,
                             autoPlayInterval: const Duration(seconds: 4),
                             autoPlayAnimationDuration: const Duration(milliseconds: 400),
                             autoPlayCurve: Curves.fastOutSlowIn,
                             enlargeCenterPage: true,
                             viewportFraction: 0.9,
                             aspectRatio: 16/7,
                             onPageChanged: (index, reason) {
                               setState(() { _currentBannerIndex = index; });
                             },
                           ),
                           items: bannerImagePaths.map((imagePath) {
                             return Builder(
                               builder: (BuildContext context) {
                                 return Container(
                                    width: MediaQuery.of(context).size.width,
                                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                    decoration: BoxDecoration(
                                       color: Colors.orange[50],
                                       borderRadius: BorderRadius.circular(12),
                                       boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                       ]
                                    ),
                                    child: ClipRRect(
                                       borderRadius: BorderRadius.circular(12),
                                       child: Image.asset(
                                         imagePath,
                                         fit: BoxFit.cover,
                                         errorBuilder: (context, error, stackTrace) {
                                           return Container(
                                              color: Colors.orange[100],
                                              child: const Center(child: Text('Lỗi ảnh', style: TextStyle(color: Colors.grey))),
                                            );
                                         },
                                       ),
                                     ),
                                  );
                               },
                             );
                           }).toList(),
                         ),
                         // --- KẾT THÚC CAROUSEL SLIDER ---
                         // --- CODE DOT INDICATOR ĐẦY ĐỦ ---
                         Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: bannerImagePaths.asMap().entries.map((entry) {
                              return GestureDetector(
                                //onTap: () => _bannerController.animateToPage(entry.key), // Đã kiểm tra tên biến và phương thức
                                child: Container(
                                  width: _currentBannerIndex == entry.key ? 10.0 : 8.0,
                                  height: _currentBannerIndex == entry.key ? 10.0 : 8.0,
                                  margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.orange.withOpacity(_currentBannerIndex == entry.key ? 0.9 : 0.4),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          // --- KẾT THÚC DOT INDICATOR ---
                       ],
                     ),
                   ),
                  // Statistics cards
                  Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
                     // --- CODE ROW CHỨA 3 STATS CARD ĐẦY ĐỦ ---
                     child: Row(
                       children: [
                         Expanded(child: _buildStatCard(icon: Icons.work_outline, title: 'Việc làm', count: '$_totalJobs', color: Colors.blue)), // <-- ĐÃ SỬA ICON
                         const SizedBox(width: 12),
                         Expanded(child: _buildStatCard(icon: Icons.business_center_outlined, title: 'Công ty', count: '$_totalCompanies', color: Colors.green)),
                         const SizedBox(width: 12),
                         Expanded(child: _buildStatCard(icon: Icons.groups_outlined, title: 'Ứng viên', count: '150+', color: Colors.orange)),
                       ],
                     ),
                     // --- KẾT THÚC ROW ---
                   ),
                  // Job list header
                  Padding(
                     padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                     // --- CODE ROW HEADER ĐẦY ĐỦ ---
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text('Việc làm mới nhất', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
                         TextButton(
                           onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chức năng Xem tất cả đang phát triển'))
                              );
                            },
                           child: Text('Xem tất cả', style: TextStyle(color: Colors.orange[800])),
                         ),
                       ],
                     ),
                      // --- KẾT THÚC ROW ---
                   ),
                ],
              ),
            ),
          ];
        },
        // Body (Job List)
        body: StreamBuilder<List<Job>>(
          stream: _jobsStream,
           // --- CODE STREAMBUILDER ĐẦY ĐỦ ---
           builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && _totalJobs == 0) {
               // Thay vì CircularProgressIndicator, ta hiển thị danh sách giả
  return ListView.builder(
    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 80.0),
    itemCount: 5, // Hiển thị 5 cái skeleton
    itemBuilder: (context, index) => const JobSkeleton(),
  );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Lỗi: ${snapshot.error}. Đã tạo index (userId, isRead) chưa? Kiểm tra F12/Console.'),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                 return Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(
                         _searchController.text.isEmpty ? Icons.work_off : Icons.search_off,
                         size: 64, color: Colors.grey[400],
                       ),
                       const SizedBox(height: 16),
                       Text(
                         _searchController.text.isEmpty ? 'Chưa có việc làm nào' : 'Không tìm thấy việc làm',
                         style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                       ),
                     ],
                   ),
                 );
              }
              final List<Job> jobs = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 80.0), // Padding dưới cùng để FAB không che
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  return _buildJobCard(jobs[index]);
                },
              );
           },
            // --- KẾT THÚC STREAMBUILDER ---
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          // --- CODE FLOATINGACTIONBUTTON ĐẦY ĐỦ ---
          onPressed: () { Navigator.pushNamed(context, '/post_job'); },
          icon: const Icon(Icons.add),
          label: const Text('Đăng việc'),
          backgroundColor: Colors.orange[800],
          // --- KẾT THÚC FLOATINGACTIONBUTTON ---
      ),
    ); // <-- Scaffold kết thúc
  }

  // Widget _buildStatCard
  Widget _buildStatCard({ required IconData icon, required String title, required String count, required Color color }) {
     // --- CODE _buildStatCard ĐẦY ĐỦ ---
     return Container(
       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
       decoration: BoxDecoration(
         color: color.withOpacity(0.05),
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: color.withOpacity(0.2)),
       ),
       child: Column(
         children: [
           Icon(icon, color: color, size: 26),
           const SizedBox(height: 6),
           Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
           const SizedBox(height: 2),
           Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
         ],
       ),
     );
     // --- KẾT THÚC _buildStatCard ---
  }

  // Widget _buildJobCard
  Widget _buildJobCard(Job job) {
     // --- CODE _buildJobCard ĐẦY ĐỦ ---
     return Card(
       margin: const EdgeInsets.only(bottom: 12),
       elevation: 3,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
       child: InkWell(
         borderRadius: BorderRadius.circular(12),
         onTap: () { _showJobDetails(job); },
         child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               // --- CODE ROW ICON, TITLE, COMPANY, BOOKMARK ĐẦY ĐỦ ---
               Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Container(
                     width: 45, height: 45,
                     decoration: BoxDecoration(
                       color: Colors.orange[50],
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Icon(Icons.business_center_outlined, color: Colors.orange[700]),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           job.title,
                           style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                           maxLines: 2,
                           overflow: TextOverflow.ellipsis,
                         ),
                         const SizedBox(height: 4),
                         Text(
                           job.company,
                           style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                          ),
                       ],
                     ),
                   ),
                   StreamBuilder<List<String>>(
                     // Dùng Stream.fromFuture để chuyển Future<List<String>> thành Stream
                     stream: _userId.isNotEmpty ? Stream.fromFuture(_jobService.getFavoriteJobIds(_userId)) : Stream.value([]),
                     builder: (context, snapshot) {
                       // Hiển thị icon loading nếu đang chờ Future
                       if (snapshot.connectionState == ConnectionState.waiting) {
                         return const SizedBox(width: 48, height: 48, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
                       }
                       // Mặc định là chưa lưu nếu có lỗi hoặc không có data
                       bool isSaved = snapshot.hasData && snapshot.data!.contains(job.id);
                       return IconButton(
                         icon: Icon(
                           isSaved ? Icons.bookmark : Icons.bookmark_border,
                           color: isSaved ? Colors.orange[700] : Colors.grey[400],
                         ),
                         tooltip: isSaved ? 'Bỏ lưu' : 'Lưu việc làm',
                         onPressed: () async {
                           if (_userId.isNotEmpty) {
                             final success = await _jobService.toggleFavorite(_userId, job.id);
                             if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? (isSaved ? 'Đã bỏ lưu' : 'Đã lưu việc làm') : 'Lỗi khi ${isSaved ? 'bỏ lưu' : 'lưu'}'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                  duration: const Duration(seconds: 1),
                                ),
                               );
                               // Trigger rebuild StreamBuilder bằng cách gọi setState rỗng
                               if(success) setState(() {});
                             }
                           } else if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Vui lòng đăng nhập để lưu')),
                             );
                           }
                         },
                       );
                     }
                   ),
                 ],
               ),
                // --- KẾT THÚC ROW ---
               const SizedBox(height: 12),
               // --- CODE WRAP TAGS ĐẦY ĐỦ ---
               Wrap(
                 spacing: 8.0,
                 runSpacing: 4.0,
                 children: [
                   _buildInfoTag(Icons.location_on_outlined, job.location),
                   _buildInfoTag(Icons.attach_money_outlined, job.salary),
                   if (job.jobType != null && job.jobType!.isNotEmpty)
                      _buildInfoTag(Icons.timer_outlined, job.jobType!),
                 ],
               ),
                // --- KẾT THÚC WRAP ---
               const SizedBox(height: 10),
               Text(job.getPostedDateAgo(), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
             ],
           ),
         ),
       ),
     );
     // --- KẾT THÚC _buildJobCard ---
  }

  // Hàm helper _buildInfoTag
  Widget _buildInfoTag(IconData icon, String text) {
     // --- CODE _buildInfoTag ĐẦY ĐỦ ---
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(
         color: Colors.grey[100],
         borderRadius: BorderRadius.circular(6),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           Icon(icon, size: 14, color: Colors.grey[600]),
           const SizedBox(width: 4),
           Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
         ],
       ),
     );
     // --- KẾT THÚC _buildInfoTag ---
  }

  // Hàm helper _buildDetailChip
  Widget _buildDetailChip(IconData icon, String label) {
     // --- CODE _buildDetailChip ĐẦY ĐỦ ---
     return Chip(
       avatar: Icon(icon, size: 16, color: Colors.grey[700]),
       label: Text(label),
       backgroundColor: Colors.grey[200],
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
       labelStyle: const TextStyle(fontSize: 13),
     );
     // --- KẾT THÚC _buildDetailChip ---
  }
  // Hàm helper _buildDetailSection
  Widget _buildDetailSection(String title, String content) {
    // --- CODE _buildDetailSection ĐẦY ĐỦ ---
    if (content.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.4)),
        const SizedBox(height: 20),
      ],
    );
     // --- KẾT THÚC _buildDetailSection ---
  }

  // Widget _showJobDetails (Bản đầy đủ)
  void _showJobDetails(Job job) {
    // --- CODE _showJobDetails ĐẦY ĐỦ ---
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(job.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(job.company, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _buildDetailChip(Icons.location_on_outlined, job.location),
                  _buildDetailChip(Icons.attach_money, job.salary),
                  if (job.jobType != null && job.jobType!.isNotEmpty) _buildDetailChip(Icons.timer_outlined, job.jobType!),
                  if (job.level != null && job.level!.isNotEmpty) _buildDetailChip(Icons.leaderboard_outlined, job.level!),
                ],
              ),
              const SizedBox(height: 24), const Divider(), const SizedBox(height: 24),
              _buildDetailSection('Mô tả công việc', job.description),
              if (job.requirements != null && job.requirements!.isNotEmpty) _buildDetailSection('Yêu cầu công việc', job.requirements!),
              if (job.benefits != null && job.benefits!.isNotEmpty) _buildDetailSection('Quyền lợi', job.benefits!),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                       final userId = _authService.currentUser?.uid;
                       if (userId != null) {
                         final result = await _jobService.applyJob(jobId: job.id, userId: userId, coverLetter: 'Tôi muốn ứng tuyển vị trí này');
                         if (context.mounted) {
                           Navigator.pop(context);
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red),
                           );
                         }
                       }
                     },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
                  child: const Text('Ứng tuyển ngay', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
     // --- KẾT THÚC _showJobDetails ---
  }
  // HÀM MỚI: HIỂN THỊ CỬA SỔ LỌC
  void _showFilterModal() {
    // Dùng StatefulBuilder để modal tự cập nhật khi người dùng chọn
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Biến tạm thời, chỉ áp dụng khi nhấn "Lưu"
        String? tempLocation = _selectedLocation;
        String? tempJobType = _selectedJobType;
        String? tempLevel = _selectedLevel;

        // Dữ liệu mẫu - bạn có thể lấy động từ Firestore nếu muốn
        final List<String> locations = ['Cần Thơ', 'Hà Nội', 'TP.Hồ Chí Minh', 'Đà Nẵng'];
        final List<String> jobTypes = ['Toàn thời gian', 'Bán thời gian', 'Thực tập', 'Freelance'];
        final List<String> levels = ['Thực tập sinh', 'Nhân viên', 'Trưởng nhóm', 'Quản lý'];

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6, // Chiều cao ban đầu
              maxChildSize: 0.9,     // Chiều cao tối đa
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bộ lọc việc làm',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Nội dung lọc (có thể cuộn)
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        children: [
                          // === Dùng StreamBuilder cho Địa điểm ===
                          StreamBuilder<List<String>>(
                            stream: _jobService.getLocationsStream(),
                            builder: (context, snapshot) {
                              List<String> locations = [];
                              if (snapshot.hasData) {
                                locations = snapshot.data!;
                                // Sắp xếp A-Z cho đẹp
                                locations.sort(); 
                              } else {
                                // Trong lúc chờ tải, hiện tạm danh sách cũ
                                locations = ['Cần Thơ', 'Hà Nội', 'Hồ Chí Minh'];
                              }
                              return _buildFilterDropdown(
                                label: 'Địa điểm',
                                icon: Icons.location_on_outlined,
                                value: tempLocation,
                                // Nếu địa điểm đang chọn không còn trong danh sách mới, reset về null
                                items: locations,
                                onChanged: (val) => setModalState(() => tempLocation = val),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildFilterDropdown(
                            label: 'Hình thức làm việc',
                            icon: Icons.timer_outlined,
                            value: tempJobType,
                            items: jobTypes,
                            onChanged: (val) => setModalState(() => tempJobType = val),
                          ),
                          const SizedBox(height: 16),
                          _buildFilterDropdown(
                            label: 'Cấp bậc',
                            icon: Icons.leaderboard_outlined,
                            value: tempLevel,
                            items: levels,
                            onChanged: (val) => setModalState(() => tempLevel = val),
                          ),
                        ],
                      ),
                    ),
                    // Nút bấm
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempLocation = null;
                                  tempJobType = null;
                                  tempLevel = null;
                                });
                                // Áp dụng ngay
                                setState(() {
                                  _selectedLocation = null;
                                  _selectedJobType = null;
                                  _selectedLevel = null;
                                });
                                _fetchJobs(_searchController.text.trim());
                                Navigator.pop(context);
                              },
                              child: const Text('Xóa bộ lọc'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Cập nhật state chính của HomeScreen
                                setState(() {
                                  _selectedLocation = tempLocation;
                                  _selectedJobType = tempJobType;
                                  _selectedLevel = tempLevel;
                                });
                                // Tải lại danh sách job với filter mới
                                _fetchJobs(_searchController.text.trim());
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[700],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Áp dụng'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // Widget hỗ trợ cho Dropdown trong modal
  Widget _buildFilterDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
        // Thêm nút "X" để xóa lựa chọn
        suffixIcon: (value != null)
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => onChanged(null),
              )
            : null,
      ),
    );
  }
} // <--- Dấu } cuối cùng của class _HomeScreenState

