// lib/features/riders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';

class RidersScreen extends StatefulWidget {
  const RidersScreen({super.key});

  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  Stream<List<Map<String, dynamic>>> _streamRiders() {
    return Supabase.instance.client
        .from(AppConstants.ridersTable)
        .stream(primaryKey: ['id']);
  }

  // ==========================================
  // ACTION: TOGGLE ACTIVE STATUS
  // ==========================================
  Future<void> _toggleActive(String id, bool currentStatus) async {
    try {
      await Supabase.instance.client
          .from(AppConstants.ridersTable)
          .update({'is_active': !currentStatus})
          .eq('id', id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ==========================================
  // ACTION: COLLECT CASH DIALOG
  // ==========================================
  void _showCollectCashDialog(String riderId, String riderName, double totalDue) {
    final TextEditingController amountCtrl = TextEditingController(text: totalDue.toStringAsFixed(0));
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.attach_money, color: AppColors.success, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text('Collect Cash', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close, color: AppColors.subtext), onPressed: () => Navigator.pop(context))
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Collecting from $riderName', style: GoogleFonts.inter(color: AppColors.subtext, fontSize: 14)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: [
                                Text('Total Due', style: GoogleFonts.inter(color: AppColors.subtext, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('৳${totalDue.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: AppColors.error, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Amount to Collect (৳)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.money, color: AppColors.subtext),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : () async {
                          final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                          if (amount <= 0) return;

                          setDialogState(() => isSubmitting = true);

                          try {
                            final user = Supabase.instance.client.auth.currentUser;
                            if (user == null) throw Exception("Admin not logged in");

                            await Supabase.instance.client.from('rider_cash_submissions').insert({
                              'rider_id': riderId,
                              'amount': amount,
                              'collected_by': user.id,
                            });

                            final newTotal = (totalDue - amount).clamp(0.0, double.infinity);
                            await Supabase.instance.client.from('riders').update({'cash_in_hand': newTotal}).eq('id', riderId);

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('৳$amount collected successfully!'), backgroundColor: AppColors.success));
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Confirm Collection', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  // ==========================================
  // ACTION: ORDER HISTORY SHEET
  // ==========================================
  void _showOrderHistory(String riderId, String riderName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order History', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                          Text(riderName, style: GoogleFonts.inter(fontSize: 12, color: AppColors.subtext)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: AppColors.subtext), onPressed: () => Navigator.pop(context))
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: Supabase.instance.client
                      .from('orders')
                      .select('order_number, total_price, created_at, status')
                      .or('rider_id.eq.$riderId,pickup_rider_id.eq.$riderId,delivery_rider_id.eq.$riderId')
                      .order('created_at', ascending: false)
                      .limit(50), // Limit to recent 50 for mobile performance
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    final orders = snapshot.data ?? [];
                    if (orders.isEmpty) return Center(child: Text('No orders found.', style: GoogleFonts.inter(color: AppColors.subtext)));

                    return ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final amount = (order['total_price'] as num?)?.toDouble() ?? 0.0;

                        String dateStr = 'Unknown Date';
                        if (order['created_at'] != null) {
                          final d = DateTime.parse(order['created_at']).toLocal();
                          dateStr = '${d.day} ${_getMonth(d.month)} ${d.year}';
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('#${order['order_number'] ?? 'N/A'}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.text)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                        child: Text('TRIP', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: AppColors.subtext)),
                                    ],
                                  )
                                ],
                              ),
                              Text('৳${amount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ACTION: CASH LOGS SHEET
  // ==========================================
  void _showCashLogs(String riderId, String riderName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cash Logs', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                          Text(riderName, style: GoogleFonts.inter(fontSize: 12, color: AppColors.subtext)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: AppColors.subtext), onPressed: () => Navigator.pop(context))
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('rider_cash_submissions')
                      .stream(primaryKey: ['id'])
                      .eq('rider_id', riderId)
                      .order('submitted_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    final logs = snapshot.data ?? [];
                    if (logs.isEmpty) return Center(child: Text('No cash logs found.', style: GoogleFonts.inter(color: AppColors.subtext)));

                    return ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final amount = (log['amount'] as num?)?.toDouble() ?? 0.0;
                        String dateStr = 'Unknown Date';
                        if (log['submitted_at'] != null) {
                          final d = DateTime.parse(log['submitted_at']).toLocal();
                          dateStr = '${d.day} ${_getMonth(d.month)} ${d.year} • ${d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour)}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.arrow_downward, color: AppColors.success, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Cash Collected', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.text)),
                                    Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: AppColors.subtext)),
                                  ],
                                ),
                              ),
                              Text('৳${amount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  // Helper for dates
  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  // ==========================================
  // MAIN UI BUILD
  // ==========================================
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by name, phone...',
              hintStyle: GoogleFonts.inter(color: AppColors.subtext),
              prefixIcon: const Icon(Icons.search, color: AppColors.subtext),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),

        // Stream Content
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _streamRiders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              if (snapshot.hasError) return Center(child: Text('Database Error', style: const TextStyle(color: AppColors.error)));

              final allRiders = snapshot.data ?? [];
              final riders = allRiders.where((r) {
                final name = (r['full_name'] ?? '').toString().toLowerCase();
                final phone = (r['phone'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || phone.contains(_searchQuery);
              }).toList();

              final int total = allRiders.length;
              final int online = allRiders.where((r) => r['is_online'] == true).length;
              final int activeAccounts = allRiders.where((r) => r['is_active'] == true).length;
              final int offline = total - online;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        children: [
                          _buildStatBox('Total Riders', total.toString(), Icons.people_alt_outlined, AppColors.primary),
                          _buildStatBox('Online Now', online.toString(), Icons.wifi, AppColors.success),
                          _buildStatBox('Active Accounts', activeAccounts.toString(), Icons.verified_user_outlined, AppColors.accent),
                          _buildStatBox('Offline', offline.toString(), Icons.wifi_off, AppColors.subtext),
                        ],
                      ),
                    ),
                  ),

                  if (riders.isEmpty) SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('No riders found.', style: GoogleFonts.inter(color: AppColors.subtext)))),

                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _buildRiderCard(riders[index]),
                      ),
                      childCount: riders.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text, height: 1.1)),
                Text(title, style: GoogleFonts.inter(fontSize: 11, color: AppColors.subtext), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRiderCard(Map<String, dynamic> rider) {
    final id = rider['id'];
    final name = rider['full_name'] ?? 'Unknown Rider';
    final phone = rider['phone'] ?? 'N/A';
    final vehicle = rider['vehicle_type'] ?? 'motorcycle';
    final rating = (rider['rating'] ?? 5.0).toString();
    final trips = (rider['total_trips'] ?? 0).toString();
    final isOnline = rider['is_online'] == true;
    final isActive = rider['is_active'] == true;
    final double cashInHand = (rider['cash_in_hand'] as num?)?.toDouble() ?? 0.0;

    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 24, backgroundColor: AppColors.primary.withOpacity(0.1), backgroundImage: rider['avatar_url'] != null ? NetworkImage(rider['avatar_url']) : null, child: rider['avatar_url'] == null ? const Icon(Icons.person, color: AppColors.primary) : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text(isOnline ? 'ONLINE' : 'OFFLINE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isOnline ? AppColors.success : AppColors.subtext)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(phone, style: GoogleFonts.inter(fontSize: 13, color: AppColors.subtext)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 4,
                        children: [
                          _buildTag(Icons.pedal_bike, vehicle.toString().toLowerCase(), Colors.blue),
                          _buildTag(Icons.star, rating, Colors.amber),
                          _buildTag(Icons.map_outlined, '$trips trips', AppColors.success),
                        ],
                      )
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text('Active', style: GoogleFonts.inter(fontSize: 10, color: AppColors.subtext)),
                    Switch(value: isActive, onChanged: (val) => _toggleActive(id, isActive), activeColor: AppColors.primary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.account_balance_wallet, color: AppColors.success, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Due', style: GoogleFonts.inter(fontSize: 11, color: AppColors.subtext)),
                      Text('৳${cashInHand.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: cashInHand > 0 ? AppColors.error : AppColors.text)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: cashInHand > 0 ? () => _showCollectCashDialog(id, name, cashInHand) : null,
                  style: ElevatedButton.styleFrom(backgroundColor: cashInHand > 0 ? AppColors.success : AppColors.border, foregroundColor: cashInHand > 0 ? Colors.white : AppColors.subtext, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), minimumSize: Size.zero),
                  child: Text('Collect', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildActionButton(Icons.history, 'Order History', () => _showOrderHistory(id, name)),
                  const SizedBox(width: 8),
                  _buildActionButton(Icons.receipt_long, 'Cash Logs', () => _showCashLogs(id, name)),
                  const SizedBox(width: 8),
                  _buildActionButton(Icons.calculate_outlined, 'Calculate Payout', () => _showEarningsCalculator(id, name)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color))]);
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: AppColors.accent),
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.accent.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero),
    );
  }
}