// lib/core/constants/app_constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // Read securely from the hidden .env file
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Tables
  static const ordersTable         = 'orders';
  static const profilesTable       = 'profiles';
  static const ridersTable         = 'riders';
  static const servicesTable       = 'services';
  static const storesTable         = 'stores';
  static const orderTimelinesTable = 'order_timelines';

  // Admin role
  static const adminRole = 'admin';

  // Order statuses
  static const statusPending         = 'pending';
  static const statusConfirmed       = 'confirmed';
  static const statusPickedUp        = 'picked_up';
  static const statusInProcess       = 'in_process';
  static const statusReady           = 'ready';
  static const statusOutForDelivery  = 'out_for_delivery';
  static const statusDelivered       = 'delivered';
  static const statusCancelled       = 'cancelled';
}