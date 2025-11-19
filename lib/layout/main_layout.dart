import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../core/constants/app_color.dart';
import '../screens/dashboard_screen.dart';
import '../screens/laporan_screen.dart';
import '../screens/setting_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = [
    const DashboardScreen(),
    LaporanScreen(),
    const SettingScreen(),
  ];

  final List<String> _labels = ['Dashboard', 'Laporan', 'Pengaturan'];

  final List<IconData> _icons = [
    Icons.dashboard_rounded,
    Icons.assessment_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Non-swipable
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(isDark),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    return ConvexAppBar(
      style: TabStyle.react,
      backgroundColor: isDark ? AppColor.darkSurface : AppColor.surface,
      activeColor: AppColor.primary,
      color: Colors.grey[600],
      height: 60,
      curveSize: 80,
      top: -20,
      items: [
        TabItem(icon: _icons[0], title: _labels[0]),
        TabItem(icon: _icons[1], title: _labels[1]),
        TabItem(icon: _icons[2], title: _labels[2]),
      ],
      initialActiveIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        _pageController.jumpToPage(index);
      },
    );
  }
}
