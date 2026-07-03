// main.dart — Customer-only (admin parts removed)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'models/app_models.dart';
import 'services/notification_service.dart';

// User screens
import 'screens/user/login_screen.dart' as user;
import 'screens/user/auctions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().init();

  runApp(const BiddingApp());
}

class BiddingApp extends StatelessWidget {
  const BiddingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BidForge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const RoleGateway(),
    );
  }
}

// ── RoleGateway — checks active Firebase session on launch ──────────
class RoleGateway extends StatelessWidget {
  const RoleGateway({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snapshot.data == null) {
          // No user → go to login screen directly
          return const _UserApp(home: user.UserLoginScreen());
        }
        // User already logged in → go to auctions
        return const _UserApp(home: AuctionsScreen());
      },
    );
  }
}

// ── User app wrapper (no admin) ──────────────────────────────────────
class _UserApp extends StatelessWidget {
  final Widget home;
  const _UserApp({required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      home: home,
    );
  }
}

// ── Splash ───────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gavel_rounded, color: Color(0xFF3B82F6), size: 48),
            SizedBox(height: 16),
            CircularProgressIndicator(
              color: Color(0xFF3B82F6),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}