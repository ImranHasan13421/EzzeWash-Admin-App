// lib/features/order_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool _loadingAdmin = true;
  String _adminRole = 'Manager';
  String? _adminStoreId;
  String _adminStoreName = 'Loading branch...';

  @override
  void initState() {
    super.initState();
    _loadAdminDetails();
  }

  Future<void> _loadAdminDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingAdmin = false);
      return;
    }

    try {
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
    } finally {
      if (mounted) {
        setState(() => _loadingAdmin = false);
      }
    }
  }

  // Stream for real-time updates directly from Supabase with role filter
  Stream<List<Map<String, dynamic>>> _streamOrders() {
    // If Manager and store ID is known, filter the stream by store_id
    if (_adminRole == 'Manager' && _adminStoreId != null) {
      return Supabase.instance.client
          .from(AppConstants.ordersTable)
          .stream(primaryKey: ['id'])
          .eq('store_id', _adminStoreId!)
          .order('created_at', ascending: false);
    }

    // Super Admin receives all stores
    return Supabase.instance.client
        .from(AppConstants.ordersTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // Helper function to format ISO dates cleanly
  String _formatDate(String? isoString) {
    if (isoString == null) return 'Unknown date';
    final d = DateTime.parse(isoString).toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}, ${d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour)}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  // Helper to build lists based on specific status categories
  Widget _buildOrderList(List<Map<String, dynamic>> allOrders, List<String> targetStatuses) {
    final filtered = allOrders.where((o) {
      final status = o['status'] as String? ?? '';
      return targetStatuses.contains(status);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text('No orders in this category', style: GoogleFonts.inter(color: AppColors.subtext, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final order = filtered[i];
        final orderNum = order['order_number'] ?? 'N/A';
        final status = order['status'] ?? 'pending';
        final price = ((order['total_price'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
        final dateStr = _formatDate(order['created_at']);

        // Determine badge color dynamically
        Color statusColor = AppColors.primary;
        if (['pending', 'confirmed'].contains(status)) statusColor = AppColors.warning;
        if (['delivered'].contains(status)) statusColor = AppColors.success;
        if (['cancelled'].contains(status)) statusColor = AppColors.error;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
              ]
          ),
          child: Row(
            children: [
              // Icon Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),

              // Order Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#$orderNum', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: AppColors.subtext)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toString().replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Text('৳$price', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAdmin) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // Branch Information Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Row(
              children: [
                const Icon(Icons.storefront_rounded, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _adminRole == 'Super Admin' ? 'All Stores Overview' : _adminStoreName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // The Swipeable Tab Bar
          Container(
            color: AppColors.surface,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.subtext,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: 'Pending & Due'),
                Tab(text: 'In Process'),
                Tab(text: 'Out for Delivery'),
                Tab(text: 'Delivered'),
              ],
            ),
          ),

          // The Content (StreamBuilder wrapper)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _streamOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final orders = snapshot.data ?? [];

                return TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Tab 1: Pending & Due
                    _buildOrderList(orders, [
                      AppConstants.statusPending,
                      AppConstants.statusConfirmed,
                      'assign_pickup',
                      AppConstants.statusPickedUp
                    ]),

                    // Tab 2: In Process
                    _buildOrderList(orders, [
                      AppConstants.statusReceived,
                      AppConstants.statusInProcess,
                      AppConstants.statusReady
                    ]),

                    // Tab 3: Out for Delivery
                    _buildOrderList(orders, [
                      AppConstants.statusOutForDelivery
                    ]),

                    // Tab 4: Delivered
                    _buildOrderList(orders, [
                      AppConstants.statusDelivered
                    ]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}