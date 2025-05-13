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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
SharedPreferences? sharedPrefs;


void main() async {
  print('## mainRun');
  await WidgetsFlutterBinding.ensureInitialized(); //don't touch
  sharedPrefs = await SharedPreferences.getInstance();
  
  // Initialize notification service
  await NotificationService().init();

  await Firebase.initializeApp();//begin firebase


  runApp(
    ResponsiveSizer(
      builder: (context, orientation, deviceType) {
        return GetMaterialApp(
          navigatorKey: navigatorKey,
          title: 'Server Room',
          debugShowCheckedModeBanner: false,
          //home: HomePage(),
          home: MyLogin(),
        );
      }
    ),
  );
}

