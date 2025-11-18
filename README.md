    Career Chase - Nền Tảng Kết Nối Việc Làm Thông Minh 🚀
Career Chase là một ứng dụng di động toàn diện được xây dựng bằng Flutter, giúp kết nối liền mạch giữa Nhà tuyển dụng và Ứng viên. Ứng dụng cung cấp trải nghiệm thời gian thực (Real-time), quản lý hồ sơ chuyên nghiệp và quy trình tuyển dụng khép kín từ nộp đơn đến phỏng vấn.

Trang Chủ (Home),Bộ Lọc (Filter),Chi Tiết Việc Làm
,,
Dashboard việc làm & Thống kê,"Lọc theo Địa điểm, Cấp bậc",Thông tin & Nộp đơn.
Quản Lý Ứng Viên,Chat Real-time,Hồ Sơ Cá Nhân
,,
Duyệt/Từ chối ứng viên,Trao đổi trực tiếp,Upload CV & Avatar

✨ Tính Năng Nổi Bật (Key Features)
Dự án được thiết kế với luồng logic chặt chẽ phân quyền cho 2 đối tượng người dùng:

👨‍💻 Dành cho Ứng Viên (Job Seeker)
Tìm kiếm thông minh: Tìm việc theo từ khóa (Debounce search) và Bộ lọc nâng cao (Địa điểm, Mức lương, Hình thức làm việc).
Tự động cập nhật dữ liệu: Hệ thống gợi ý địa điểm tự động cập nhật khi có dữ liệu mới.
Nộp hồ sơ (Apply): Ứng tuyển nhanh chóng, tải lên CV (PDF/Doc) và viết thư giới thiệu.
Theo dõi trạng thái: Xem lịch sử ứng tuyển và nhận thông báo ngay lập tức khi hồ sơ được "Duyệt" hoặc "Từ chối".
Lưu việc làm: Đánh dấu các công việc yêu thích (Bookmark).

🏢 Dành cho Nhà Tuyển Dụng (Recruiter)
Đăng tin tuyển dụng: Soạn thảo, chỉnh sửa và quản lý trạng thái tin đăng (Ẩn/Hiện).
Quản lý ứng viên: Xem danh sách người nộp đơn cho từng bài đăng.
Quy trình xét duyệt: Thao tác Duyệt hoặc Từ chối hồ sơ. Hệ thống tự động gửi thông báo cho ứng viên.
Dashboard: Thống kê số lượng đơn nộp và lượt xem.

🔥 Tính năng Chung & Kỹ Thuật (Core Tech)
Chat Real-time: Hệ thống nhắn tin trực tiếp giữa Nhà tuyển dụng và Ứng viên (xây dựng trên Firestore).
Thông báo (Notifications): Badge đếm số thông báo chưa đọc theo thời gian thực.
Quản lý Tài khoản: Đăng nhập/Đăng ký, Upload Avatar & CV lên Firebase Storage.
Bảo mật: Tích hợp Firebase App Check để bảo vệ API và Database.

🛠 Công Nghệ Sử Dụng (Tech Stack)
Frontend: Flutter (Dart).
Backend: Firebase (BaaS).
Authentication: Quản lý đăng nhập (Email/Password).
Cloud Firestore: Cơ sở dữ liệu NoSQL thời gian thực (Indexing tối ưu cho bộ lọc phức tạp).
Firebase Storage: Lưu trữ hình ảnh và file CV.
App Check: Bảo mật ứng dụng chống giả mạo.
Các thư viện chính (Packages):
provider / stream_builder: Quản lý trạng thái.
firebase_core, cloud_firestore, firebase_auth: Kết nối Firebase.
image_picker, file_picker: Xử lý đa phương tiện.
carousel_slider: Banner quảng cáo động.
shimmer: Hiệu ứng loading mượt mà.
url_launcher: Mở liên kết ngoài/gọi điện.

🚀 Hướng Dẫn Cài Đặt (Installation)
Để chạy dự án này trên máy của bạn:
1. Clone dự án: git clone https://github.com/username/career-chase.git
cd career-chase.
2. Cài đặt thư viện: flutter pub get
3. Cấu hình Firebase:
Tạo project trên Firebase Console.
Tải file google-services.json và đặt vào thư mục android/app/.
(Tùy chọn iOS) Tải GoogleService-Info.plist vào thư mục ios/Runner/.
4. Cấu hình App Check (Nếu chạy trên Máy ảo/Emulator):
Lấy Debug Token từ console khi chạy app lần đầu.
Thêm Token vào Firebase Console -> App Check -> Manage Debug Tokens.
5. Chạy ứng dụng: flutter run.
📂 Cấu Trúc Thư Mục (Project Structure)
lib/
├── models/            # Data models (Job, User, Notification, Chat)
├── screens/           # Các màn hình UI (Home, Profile, JobDetails...)
├── services/          # Logic xử lý Firebase (AuthService, JobService...)
├── widgets/           # Các widget tái sử dụng (JobCard, CustomDrawer...)
└── main.dart          # Entry point

🗺 Lộ Trình Phát Triển (Roadmap)
[x] Hoàn thiện luồng Tuyển dụng cơ bản.
[x] Tích hợp Chat & Thông báo Real-time.
[x] Bộ lọc tìm kiếm nâng cao (Indexing).
[ ] Tích hợp Google Maps để xem vị trí công ty.
[ ] Gợi ý việc làm bằng AI dựa trên hồ sơ.
[x] Dark Mode (Giao diện tối).

👤 Tác Giả (Author)
Trần Huỳnh Sang
Email: sang123567tqs@gmail.com
GitHub: github.com/HuynhSang-IT
FB: HUỳnh Sang
Zalo: 0944924860
