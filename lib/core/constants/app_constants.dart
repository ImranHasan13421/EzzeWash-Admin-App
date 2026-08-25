import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // Securely fetch keys
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Database Tables
  static const ordersTable = 'orders';
  static const profilesTable = 'profiles';
  static const ridersTable = 'riders';
  static const servicesTable = 'services';
  static const storesTable = 'stores';

  // Order Statuses
  static const statusPending = 'pending';
  static const statusConfirmed = 'confirmed';
  static const statusPickedUp = 'picked_up';
  static const statusReceived = 'received';
  static const statusInProcess = 'in_process';
  static const statusReady = 'ready';
  static const statusOutForDelivery = 'out_for_delivery';
  static const statusDelivered = 'delivered';
  static const statusCancelled = 'cancelled';
}