// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:my_new_app/core/components/feedback/jivan_loader.dart'; // Your loader

// // Layouts
// import 'package:my_new_app/screens/main_layout.dart'; // Patient
// import 'package:my_new_app/screens/admin/admin_layout.dart'; // Clinic Admin (Existing)
// import 'package:my_new_app/screens/super_admin/super_admin_layout.dart'; // Super Admin (New)
// import 'package:my_new_app/screens/auth/login_screen.dart'; // Auth

// class RootDispatcher extends StatefulWidget {
//   const RootDispatcher({super.key});

//   @override
//   State<RootDispatcher> createState() => _RootDispatcherState();
// }

// class _RootDispatcherState extends State<RootDispatcher> {
//   final _storage = const FlutterSecureStorage();

//   // States: 0=Loading, 1=Patient, 2=Admin, 3=SuperAdmin, 4=Auth
//   int _navigationState = 0;

//   @override
//   void initState() {
//     super.initState();
//     _checkSession();
//   }

//   Future<void> _checkSession() async {
//     // 1. Check for specific tokens
//     final patientToken = await _storage.read(key: 'auth_token');
//     final adminToken = await _storage.read(key: 'admin_token');
//     final role = await _storage.read(
//       key: 'admin_role',
//     ); // 'staff', 'doctor', 'super_admin'

//     setState(() {
//       if (adminToken != null && role == 'super_admin') {
//         _navigationState = 3; // Super Admin
//       } else if (adminToken != null) {
//         _navigationState = 2; // Normal Admin/Doctor
//       } else if (patientToken != null) {
//         _navigationState = 1; // Patient
//       } else {
//         _navigationState = 4; // Not Logged In
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     switch (_navigationState) {
//       case 0:
//         return const Scaffold(body: Center(child: JivanLoader()));
//       case 1:
//         return const MainLayout();
//       case 2:
//         // Ensure you create/rename your existing admin screen to AdminLayout
//         return const AdminLayout();
//       case 3:
//         return const SuperAdminLayout();
//       case 4:
//       default:
//         return const LoginScreen();
//     }
//   }
// }
