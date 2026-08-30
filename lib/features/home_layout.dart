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
  String _userRole = 'Manager'; // Default to Manager for safety

  final List<Widget> _pages = [
    const DashboardScreen(),
    const OrderScreen(),
    const ReportScreen(),
    const RidersScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('team_members')
          .select('role')
          .eq('email', user.email!)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _userRole = response['role'] ?? 'Manager';
        });
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

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

  Future<void> _confirmLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Sign Out',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          content: Text(
            'Are you sure want to sign out?',
            style: GoogleFonts.inter(color: AppColors.text, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: AppColors.subtext, fontWeight: FontWeight.bold)
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                  'Sign Out',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Unknown User';

    // Determine the display name based on the fetched role
    final displayName = _userRole == 'Super Admin' ? 'EzeeWash Admin' : 'EzeeWash Manager';

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
              accountName: Text(displayName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              accountEmail: Text(userEmail, style: GoogleFonts.inter()),
              currentAccountPicture: Image.asset(
                'assets/icon/logo.png',
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
              title: Text('Settings', style: GoogleFonts.inter()),
              selected: _currentIndex == 4,
              onTap: () => _onMenuTap(4, 'Settings'),
            ),

            const Spacer(),

            // Custom Rounded Sign Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _confirmLogout,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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