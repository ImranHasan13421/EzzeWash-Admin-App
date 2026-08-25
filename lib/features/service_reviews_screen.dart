// lib/features/service_reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';

class ServiceReviewsScreen extends StatefulWidget {
  final String serviceId;
  final String serviceTitle;

  const ServiceReviewsScreen({
    super.key,
    required this.serviceId,
    required this.serviceTitle,
  });

  @override
  State<ServiceReviewsScreen> createState() => _ServiceReviewsScreenState();
}

class _ServiceReviewsScreenState extends State<ServiceReviewsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      // Fetch reviews, joining with profiles for user name and orders for the price/order number
      final response = await Supabase.instance.client
          .from('reviews')
          .select('*, profiles(full_name), orders(order_number, total_price)')
          .eq('service_id', widget.serviceId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(response);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown Date';
    final d = DateTime.parse(isoDate).toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final amPm = d.hour >= 12 ? 'PM' : 'AM';
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final min = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} • $hour:$min $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service Reviews', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(widget.serviceTitle, style: GoogleFonts.inter(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
          ? Center(child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text('Error loading reviews: $_error', style: const TextStyle(color: AppColors.error)),
      ))
          : _reviews.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline_rounded, size: 64, color: AppColors.subtext.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No reviews yet for this service.', style: GoogleFonts.inter(color: AppColors.subtext, fontSize: 15)),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: _reviews.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final rev = _reviews[index];

          // Extract Data
          final rating = (rev['rating'] as num?)?.toDouble() ?? 0.0;
          final comment = rev['comment']?.toString() ?? '';
          final dateStr = _formatDate(rev['created_at']);

          // Handle Joins Safely
          final profile = rev['profiles'] as Map<String, dynamic>?;
          final order = rev['orders'] as Map<String, dynamic>?;

          final userName = profile?['full_name'] ?? 'Unknown User';
          final orderNum = order?['order_number'] ?? 'N/A';
          final price = (order?['total_price'] as num?)?.toDouble() ?? 0.0;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: User & Rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text)),
                          const SizedBox(height: 2),
                          Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: AppColors.subtext)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Comment Section
                if (comment.isNotEmpty) ...[
                  Text('"$comment"', style: GoogleFonts.inter(fontSize: 14, color: AppColors.text, height: 1.4, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                ],

                // Order Reference Bottom Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.subtext),
                      const SizedBox(width: 8),
                      Text('Order #$orderNum', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.subtext)),
                      const Spacer(),
                      Text('৳${price.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}