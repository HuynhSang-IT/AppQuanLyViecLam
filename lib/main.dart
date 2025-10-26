import 'package:app_quanlyvieclam/screens/job_applicants_screen.dart';
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

void main() async {
  // Khởi tạo Flutter engine
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Việc Làm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/job_applicants': (context) {
          final Job job = ModalRoute.of(context)!.settings.arguments as Job;
          // SỬA CHỮ 'j' thành 'J' ở dòng dưới
          return JobApplicantsScreen(jobId: job.id, jobTitle: job.title); 
        },
        '/post_job': (context) {
          // Lấy Job object được truyền qua (nếu có)
          final Job? jobToEdit =
              ModalRoute.of(context)!.settings.arguments as Job?;
          return PostJobScreen(existingJob: jobToEdit);
        },
        '/my_jobs': (context) => const MyJobsScreen(),
        '/saved_jobs': (context) => const SavedJobsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/my_applications': (context) => const MyApplicationsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/about': (context) => const AboutScreen(),
        '/help': (context) => const HelpScreen(),
      },
    );
  }
}