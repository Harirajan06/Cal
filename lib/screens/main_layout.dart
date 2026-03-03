import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import 'dashboard_screen.dart';
import 'camera_screen.dart';
import 'history_screen.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  final List<Widget> _screens = const [
    DashboardScreen(),
    CameraScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _screens[navProvider.currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildPulsingFAB(() {
        navProvider.setIndex(1); // Switch to Camera
      }),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          currentIndex: navProvider.currentIndex,
          selectedItemColor: const Color(0xFFCCFF00),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            navProvider.setIndex(index);
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Status',
            ),
            BottomNavigationBarItem(
              icon: Container(), // Dummy for FAB space
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingFAB(VoidCallback onPressed) {
    return _PulsingFAB(onPressed: onPressed);
  }
}

class _PulsingFAB extends StatefulWidget {
  final VoidCallback onPressed;
  const _PulsingFAB({required this.onPressed});

  @override
  State<_PulsingFAB> createState() => _PulsingFABState();
}

class _PulsingFABState extends State<_PulsingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFCCFF00,
                ).withOpacity(0.2 * (1 - _pulseController.value)),
                blurRadius: 20 * _pulseController.value,
                spreadRadius: 10 * _pulseController.value,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: widget.onPressed,
            backgroundColor: const Color(0xFFCCFF00),
            shape: const CircleBorder(),
            child: const Icon(Icons.camera_alt, color: Colors.black),
          ),
        );
      },
    );
  }
}
