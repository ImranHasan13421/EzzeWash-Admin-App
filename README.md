# 🧼 EzeeWash Admin Mobile App

A powerful, cross-platform mobile administrative dashboard built with **Flutter** and powered by **Supabase** and **OneSignal**. Designed to manage operations on the go, providing managers and admins with real-time order tracking, fleet coordination, analytics reporting, and instant push notifications.

---

## 🚀 Key Features

* **📊 Real-time Dashboard & Analytics**

    * Live KPI indicators (total revenue, order counts, pending pick-ups, deliveries).
    * Interactive service breakdown and order distribution charts using `Syncfusion Flutter Charts`.
    * PDF export functionality to generate and share monthly performance reports on the fly.

* **📦 End-to-End Order Management**

    * Live order lifecycle tracking with step-by-step progress updating.
    * Rider assignment and dynamic status management (e.g., Pending, Picked Up, Processing, Out for Delivery, Delivered).
    * Customer feedback and rating timeline linked directly to specific service orders.

* **🛵 Rider Fleet & Settlement Hub**

    * Live rider status monitoring (Online / Offline / On Delivery).
    * Real-time cash collection logging, settlement dialogs, and earnings breakdowns.

* **⚙️ Complete Business Configuration**

    * Multi-store status and availability toggles.
    * Laundry service catalogue management (pricing, categories, durations, and tags).
    * Customer directory and historical order lookup.
    * Promotional campaigns creator with usage limits, discounts, and banner uploads.
    * Team member invitation and role management.

* **🔔 Instant Real-Time Push Notifications**

    * Automated order alerts powered by **OneSignal** and **Supabase Database Triggers (`pg_net`)**.
    * Instantly notifies off-desk managers the second a new order is placed.

---

## 🛠️ Tech Stack & Dependencies

* **Framework:** [Flutter](https://flutter.dev/) (Material 3)
* **Backend & Database:** [Supabase](https://supabase.com/) (PostgreSQL, Auth, Storage, Realtime, `pg_net`)
* **Push Notifications:** [OneSignal](https://onesignal.com/) (`onesignal_flutter`)
* **State Management & UI:**

    * `google_fonts` — Modern typography (Inter & Outfit)
    * `syncfusion_flutter_charts` — Interactive mobile charts
    * `image_picker` — Banner & profile image handling
    * `pdf` & `printing` — Automated PDF document creation & sharing
    * `flutter_dotenv` — Secure environment configuration

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── constants/       # App table references and static string keys
│   └── theme/           # AppColors and global styling definition
├── features/
│   ├── admin_login_screen.dart     # Admin authentication & credentials
│   ├── dashboard_screen.dart       # KPI metrics & real-time analytics
│   ├── home_layout.dart            # Root drawer & bottom navigation
│   ├── order_screen.dart           # Active order management & status workflows
│   ├── profile_screen.dart         # Extended administration & business settings hub
│   ├── report_screen.dart           # Monthly summaries & PDF generation
│   ├── riders_screen.dart           # Rider fleet tracking & cash settlements
│   ├── service_reviews_screen.dart # Customer review logs for services
│   └── splash_screen.dart           # Animated startup branding & session routing
└── main.dart                       # Entry point & SDK initialization
```

---

## ⚙️ Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.11+ recommended)
* [Dart SDK](https://dart.dev/get-dart)
* Android Studio / VS Code with Flutter extensions
* A physical Android/iOS device or configured emulator

### Installation & Setup

1. **Clone the Repository**

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**

4. **Generate App Launcher Icons**

   ```bash
   dart run flutter_launcher_icons
   ```

5. **Run the Application**

   ```bash
   flutter run
   ```

---

## 📱 Build Release APK

To create an optimized release build for Android:

```bash
flutter build apk --release
```

The output file will be generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📄 License

This repository is proprietary software developed for the **EzeeWash** management ecosystem. All rights reserved to **MD. Imran Hasan**.
