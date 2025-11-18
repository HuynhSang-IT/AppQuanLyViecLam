import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Hàm xử lý khi người dùng hoàn thành giới thiệu
  void _onIntroEnd(context) async {
    // 1. Lưu trạng thái "đã xem" vào bộ nhớ máy
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    // 2. Chuyển sang màn hình Đăng nhập
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Định nghĩa style chung cho hình ảnh
    Widget _buildImage(String assetName, [double width = 250]) {
      // Nếu bạn có ảnh thật thì dùng Image.asset, ở đây mình dùng Icon minh họa cho nhanh
      return Container(
        width: width,
        height: width,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          shape: BoxShape.circle,
        ),
        child: Icon(
          assetName == 'job' ? Icons.work_outline :
          assetName == 'connect' ? Icons.people_alt_outlined :
          Icons.chat_bubble_outline,
          size: 100,
          color: Colors.orange[700],
        ),
      );
    }

    // Style cho chữ
    const bodyStyle = TextStyle(fontSize: 19.0);
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700, color: Colors.orange),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: Colors.white,
      allowImplicitScrolling: true,
      
      // --- DANH SÁCH CÁC TRANG GIỚI THIỆU ---
      pages: [
        PageViewModel(
          title: "Tìm Việc Dễ Dàng",
          body: "Hàng ngàn công việc hấp dẫn đang chờ đợi bạn. Tìm kiếm và lọc theo nhu cầu chỉ trong tích tắc.",
          image: _buildImage('job'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Kết Nối Nhà Tuyển Dụng",
          body: "Tạo hồ sơ chuyên nghiệp và gây ấn tượng trực tiếp với các nhà tuyển dụng hàng đầu.",
          image: _buildImage('connect'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Trao Đổi Trực Tiếp",
          body: "Chat và nhận thông báo phỏng vấn ngay trên ứng dụng. Không bỏ lỡ bất kỳ cơ hội nào.",
          image: _buildImage('chat'),
          decoration: pageDecoration,
        ),
      ],

      // --- CÁC NÚT ĐIỀU HƯỚNG ---
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // Bấm 'Bỏ qua' cũng coi như xong
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      
      // Giao diện nút
      skip: const Text('Bỏ qua', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
      next: const Icon(Icons.arrow_forward, color: Colors.orange),
      done: const Text('Bắt đầu', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
      
      // Style cho các chấm tròn (dots)
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
        activeColor: Colors.orange,
      ),
    );
  }
}