import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:server_room_new/auth/login.dart';
import 'package:server_room_new/home_page/home_page.dart';
import 'package:server_room_new/auth/register.dart';
import 'package:server_room_new/home_page/home_page_ctr.dart';
import 'package:server_room_new/models/user.dart';
import 'package:server_room_new/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
SharedPreferences? sharedPrefs;

// Call this after successful login
Future<void> setKeepSignedIn(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('keepSignedIn', value);
}

// Call this in your main() or splash screen
Future<bool> isSignedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('keepSignedIn') ?? false;
}

void main() async {
  print('## mainRun');
  await WidgetsFlutterBinding.ensureInitialized(); //don't touch
  sharedPrefs = await SharedPreferences.getInstance();
  
  // Initialize notification service
  await NotificationService().init();

  await Firebase.initializeApp();//begin firebase

  // Determine start screen
  Widget startScreen;
  bool keepSignedIn = await isSignedIn();
  var user = FirebaseAuth.instance.currentUser;
  if (keepSignedIn && user != null) {
    // Load user info from Firestore before showing HomePage
    await getUserInfoByEmail(user.email);
    startScreen = HomePage();
  } else {
    startScreen = MyLogin();
  }

  runApp(
    ResponsiveSizer(
      builder: (context, orientation, deviceType) {
        return GetMaterialApp(
          navigatorKey: navigatorKey,
          title: 'Server Room',
          debugShowCheckedModeBanner: false,
          home: startScreen,
        );
      }
    ),  
  );
}

