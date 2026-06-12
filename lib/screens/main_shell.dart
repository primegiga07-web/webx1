import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth_theme.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Pages corresponding to bottom navigation tabs
  final List<Widget> _pages = [
    const HomeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF8FAFC), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                iconPath: 'assets/vectors/home.svg',
                fallbackIcon: Icons.home_filled,
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                iconPath: 'assets/vectors/manage_page_icon.svg',
                fallbackIcon: Icons.grid_view_rounded,
                label: 'Manage',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String iconPath,
    required IconData fallbackIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final activeColor = AuthTheme.textDark;
    final inactiveColor = AuthTheme.textGrey;
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24.0,
              height: 24.0,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              placeholderBuilder: (context) => Icon(
                fallbackIcon,
                size: 24.0,
                color: color,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              label,
              style: TextStyle(
                fontFamily: AuthTheme.fontFamily,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12.0,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
