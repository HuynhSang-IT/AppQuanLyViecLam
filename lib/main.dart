import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/post_job_screen.dart';
import 'screens/my_jobs_screen.dart';
import 'models/job_model.dart';
import 'screens/saved_jobs_screen.dart';
import 'screens/my_applications_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/about_screen.dart';
import 'screens/help_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/job_applicants_screen.dart'; 
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';

// 1. TẠO BIẾN TOÀN CỤC ĐỂ QUẢN LÝ THEME (Đặt ngay dưới các import)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1. Khởi tạo Firebase trước
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 2. Kích hoạt App Check NGAY SAU ĐÓ (trước khi runApp)
  await FirebaseAppCheck.instance.activate(
    // Cho Android (Máy ảo)
    androidProvider: AndroidProvider.debug,
    
    // Cho iOS
    appleProvider: AppleProvider.appAttest,

    // Cho Web: Tạm thời dùng 'ReCaptchaV3Provider' với key đặc biệt này của Google để test
    // Hoặc tốt nhất là để 'null' nếu bạn chưa cài đặt reCAPTCHA
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'), 
  );
  // === KIỂM TRA TRẠNG THÁI ONBOARDING ===
  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  // 3. Chạy App
  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding; //Nhận biến này từ main
  // MỚI: Cập nhật constructor
  const MyApp({Key? key, required this.seenOnboarding}) : super(key: key);
  //const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 2. BỌC MATERIALAPP TRONG VALUELISTENABLEBUILDER
    // Để nó tự động vẽ lại App mỗi khi themeNotifier thay đổi
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Quản Lý Việc Làm',
          debugShowCheckedModeBanner: false,
      // ========================================================
      // 1. CẤU HÌNH GIAO DIỆN SÁNG (LIGHT THEME)
      // ========================================================
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue, // Màu gốc của Material
        primaryColor: Colors.orange[700], // Màu thương hiệu
        scaffoldBackgroundColor: Colors.grey[50], // Nền hơi xám nhẹ cho dễ nhìn
        
        // Cấu hình AppBar mặc định
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        
        /* Cấu hình Card mặc định
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),*/
        
        // Màu Icon mặc định
        iconTheme: IconThemeData(color: Colors.grey[800]),
      ),

      // ========================================================
      // 2. CẤU HÌNH GIAO DIỆN TỐI (DARK THEME) - MỚI
      // ========================================================
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange[700], // Vẫn giữ màu cam điểm nhấn
        scaffoldBackgroundColor: const Color(0xFF121212), // Màu nền đen "chuẩn" Android
        
        // AppBar trong Dark Mode nên tối đi để đỡ chói
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F), // Xám rất đậm
          foregroundColor: Colors.white, // Chữ vẫn trắng
          elevation: 0,
        ),
        
        /* Card trong Dark Mode phải sáng hơn nền một chút
        cardTheme: CardTheme(
          color: const Color(0xFF2C2C2C), // Xám đậm vừa
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),*/

        // Màu Icon chuyển sang trắng/xám nhạt
        iconTheme: const IconThemeData(color: Colors.white70),
        
        // Màu chữ sẽ tự động chuyển sang trắng nhờ Brightness.dark
      ),
      // 3. SỬ DỤNG BIẾN ĐỘNG THAY VÌ CỐ ĐỊNH
          themeMode: currentMode,
      // ========================================================
      // 3. CHẾ ĐỘ HOẠT ĐỘNG
      // ========================================================
      // ThemeMode.system: Tự động đổi theo cài đặt của điện thoại
      // ThemeMode.light: Luôn sáng
      // ThemeMode.dark: Luôn tối
      //themeMode: ThemeMode.system,
      // Nếu đã xem rồi -> Login. Nếu chưa -> Onboarding
      initialRoute: seenOnboarding ? '/login' : '/onboarding',

      routes: {
        '/onboarding': (context) => const OnboardingScreen(), // Đăng ký route
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        // ✅ ROUTE JOB APPLICANTS (RECRUITER XEM ỨNG VIÊN)
        '/job_applicants': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return JobApplicantsScreen(
            jobId: args['jobId'] as String,
            jobTitle: args['jobTitle'] as String,
          );
        },
        
        '/post_job': (context) {
          final Job? jobToEdit = ModalRoute.of(context)!.settings.arguments as Job?;
          return PostJobScreen(existingJob: jobToEdit);
        },
        
        '/my_jobs': (context) => const MyJobsScreen(),
        '/saved_jobs': (context) => const SavedJobsScreen(),
        '/profile': (context) => const ProfileScreen(),
        
        // ✅ FIX: ĐỔI TỪ ApplicantsScreen THÀNH MyApplicationsScreen
        '/my_applications': (context) => const MyApplicationsScreen(),
        
        '/notifications': (context) => const NotificationsScreen(),
        '/about': (context) => const AboutScreen(),
        '/help': (context) => const HelpScreen(),
        
        // ✅ FIX ROUTE CHAT - THÊM applicationId VÀ isRecruiter
        '/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          
          final String chatRoomId = args['chatRoomId'] as String? ?? '';
          final String receiverName = args['receiverName'] as String? ?? 'Người dùng';
          final String receiverId = args['receiverId'] as String? ?? '';
          final String? applicationId = args['applicationId'] as String?; // ✅ THÊM
          final bool isRecruiter = args['isRecruiter'] as bool? ?? false;  // ✅ THÊM

          if (chatRoomId.isEmpty || receiverId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Lỗi')),
              body: const Center(
                child: Text('Thông tin chat không hợp lệ.'),
              ),
            );
          }

          return ChatScreen(
            chatRoomId: chatRoomId,
            receiverName: receiverName,
            receiverId: receiverId,
            applicationId: applicationId,  // ✅ TRUYỀN VÀO
            isRecruiter: isRecruiter,      // ✅ TRUYỀN VÀO
              );
            },
          },
        );
      },
    );
  }
}