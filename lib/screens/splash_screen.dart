import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main_layout.dart';
import 'onboarding_screen.dart';

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Even shorter delay for almost instant loading
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    final userBox = Hive.box('user_box');
    final bool isProfileSetup = userBox.get(
      'is_profile_setup',
      defaultValue: false,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            isProfileSetup ? const MainLayout() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(child: AppLogo(size: 150)),
    );
  }
}
