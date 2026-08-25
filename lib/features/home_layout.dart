// lib/features/home_layout.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';

// We will build these 5 screens next!
import 'dashboard_screen.dart';
import 'order_screen.dart';
import 'report_screen.dart';
import 'riders_screen.dart';
import 'profile_screen.dart';
import 'admin_login_screen.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _currentIndex = 0;
  String _appBarTitle = 'Dashboard';

  final List<Widget> _pages = [
    const DashboardScreen(),
    const OrderScreen(),
    const ReportScreen(),
    const RidersScreen(),
    const ProfileScreen(),
  ];

  void _onMenuTap(int index, String title) {
    setState(() {
      _currentIndex = index;
      _appBarTitle = title;
    });
    Navigator.pop(context); // Close the drawer after tapping
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Manager';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _appBarTitle,
          style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              accountName: Text('EzeeWash Admin', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              accountEmail: Text(userEmail, style: GoogleFonts.inter()),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.local_laundry_service, color: AppColors.primary),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text('Dashboard', style: GoogleFonts.inter()),
              selected: _currentIndex == 0,
              onTap: () => _onMenuTap(0, 'Dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: Text('Orders', style: GoogleFonts.inter()),
              selected: _currentIndex == 1,
              onTap: () => _onMenuTap(1, 'Orders'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: Text('Reports', style: GoogleFonts.inter()),
              selected: _currentIndex == 2,
              onTap: () => _onMenuTap(2, 'Reports'),
            ),
            ListTile(
              leading: const Icon(Icons.delivery_dining_outlined),
              title: Text('Riders', style: GoogleFonts.inter()),
              selected: _currentIndex == 3,
              onTap: () => _onMenuTap(3, 'Riders'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text('Profile', style: GoogleFonts.inter()),
              selected: _currentIndex == 4,
              onTap: () => _onMenuTap(4, 'Profile'),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text('Log Out', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.bold)),
              onTap: _logout,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
    );
  }
}