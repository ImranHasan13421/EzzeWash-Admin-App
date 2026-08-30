// lib/features/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  // Admin Context Variables
  String _adminRole = 'Manager';
  String? _adminStoreId;
  String _adminStoreName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAdminDetails(); // Fetch role and store first
  }

  Future<void> _loadAdminDetails() async {
    setState(() => _loading = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _loadStats();
      return;
    }

    try {
      // Fetch admin role and assigned store name from the team_members table
      final response = await Supabase.instance.client
          .from('team_members')
          .select('role, store_id, stores(name)')
          .eq('email', user.email!)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _adminRole = response['role'] ?? 'Manager';
          _adminStoreId = response['store_id'];
          _adminStoreName = response['stores']?['name'] ?? 'My Store';
        });
      }
    } catch (e) {
      debugPrint('Error loading admin details: $e');
    }

    // Now fetch the stats with the correct role context applied
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final now = DateTime.now();

      // 1. Start building the query
      var query = Supabase.instance.client
          .from(AppConstants.ordersTable)
          .select('status, total_price, created_at');

      // 2. Apply Security Filter for Managers (Only fetch THEIR branch details)
      if (_adminRole == 'Manager' && _adminStoreId != null) {
        query = query.eq('store_id', _adminStoreId!);
      }

      // 3. Execute query
      final response = await query;
      final orders = List<Map<String, dynamic>>.from(response);

      int total = orders.length;
      int pending = 0;
      int active = 0;
      int delivered = 0;
      double todayRevenue = 0.0;

      for (var o in orders) {
        final status = o['status'] as String? ?? '';

        if (status == AppConstants.statusPending) {
          pending++;
        } else if (status == AppConstants.statusDelivered) {
          delivered++;
        } else if (status != AppConstants.statusCancelled) {
          active++; // Any order not pending, delivered, or cancelled is "In Process"
        }

        // Calculate today's revenue (exclude cancelled)
        if (o['created_at'] != null) {
          final createdAt = DateTime.parse(o['created_at']).toLocal();
          if (createdAt.isAfter(DateTime(now.year, now.month, now.day)) && status != AppConstants.statusCancelled) {
            todayRevenue += (o['total_price'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }

      if (mounted) {
        setState(() {
          _stats = {
            'total': total,
            'pending': pending,
            'active': active,
            'delivered': delivered,
            'todayRevenue': todayRevenue,
          };
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final double todayRevenue = _stats['todayRevenue'] ?? 0.0;
    final int total = _stats['total'] ?? 0;
    final int pending = _stats['pending'] ?? 0;
    final int active = _stats['active'] ?? 0;
    final int delivered = _stats['delivered'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadAdminDetails, // Refresh everything including role
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Overview',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            const SizedBox(height: 4),
            // Dynamically show the assigned branch name in Green
            Text(
              _adminRole == 'Super Admin' ? 'All Stores Overview' : _adminStoreName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green, // Highlighted in green as requested
              ),
            ),
            const SizedBox(height: 16),

            // Highlighted Revenue Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
                  ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today\'s Revenue', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('৳${todayRevenue.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text(
              'Fleet & Logistics',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            const SizedBox(height: 16),

            // 2-Column Mobile Grid for Stats
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard('Total Orders', total.toString(), Icons.receipt_long_rounded, AppColors.primary),
                _buildStatCard('Pending', pending.toString(), Icons.pending_actions_rounded, AppColors.warning),
                _buildStatCard('In Process', active.toString(), Icons.autorenew_rounded, Colors.blue),
                _buildStatCard('Delivered', delivered.toString(), Icons.check_circle_outline_rounded, AppColors.success),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text)),
            ],
          ),
          const Spacer(),
          Text(title, style: GoogleFonts.inter(fontSize: 14, color: AppColors.subtext, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}