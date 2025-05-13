import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:server_room_new/my_ui.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page/home_page_ctr.dart';

// Notification service class for handling notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool isAlertActive = false;
  bool isDialogShowing = false;
  Timer? alertTimer;
  
  // Audio player for alarm sound
  AudioPlayer? _audioPlayer;
  bool isAlarmSoundPlaying = false;
  
  // Remember original volume
  double _originalVolume = 0.5;
  
  // Alert volume (0.0 to 1.0)
  double alertVolume = 0.1; // Default to 70%
  
  // Dialog callback
  Function(String title, String message)? onShowAlertDialog;

  // Initialize notification settings
  Future<void> init() async {
    // Request notification permissions (for iOS and newer Android versions)
    await _requestPermissions();

    // Initialize Android notification settings with the new builder approach
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Initialize iOS notification settings - using DarwinInitializationSettings for iOS and macOS
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Initialize Linux settings
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    
    // Initialize settings for all platforms
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );
    
    // Initialize notifications plugin with the new callback structure
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    
    // Check if vibration is supported
    bool? hasVibrator = await Vibration.hasVibrator();
    print('Device has vibrator: $hasVibrator');
    
    // Initialize audio player
    _initAudioPlayer();
    
    // Initialize volume controller - hide system UI
    VolumeController.instance.showSystemUI = false;
    
    // Save current volume
    VolumeController.instance.getVolume().then((volume) {
      _originalVolume = volume;
    });
    
    // Load saved alert volume
    await loadAlertVolume();
    
    // Check if there's an active alert when starting the app
    await checkAndShowAlertDialogIfNeeded();
  }
  
  // Load saved alert volume from preferences
  Future<void> loadAlertVolume() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    alertVolume = prefs.getDouble('alertVolume') ?? 0.7;
    print("Loaded alert volume: $alertVolume");
  }
  
  // Save alert volume to preferences
  Future<void> saveAlertVolume(double volume) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('alertVolume', volume);
    alertVolume = volume;
    
    // If alarm is playing, update its volume
    if (isAlarmSoundPlaying && _audioPlayer != null) {
      await _audioPlayer!.setVolume(alertVolume);
    }
    
    print("Saved alert volume: $alertVolume");
  }
  
  // Check for active alerts when starting the app
  Future<void> checkAndShowAlertDialogIfNeeded() async {
    // Check saved flag for active alert
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool wasAlertActive = prefs.getBool('isAlertActive') ?? false;
    String alertTitle = prefs.getString('alertTitle') ?? 'Alert';
    String alertMessage = prefs.getString('alertMessage') ?? 'An alert is active';
    
    if (wasAlertActive) {
      isAlertActive = true;
      
      // Show dialog to allow stopping the alert
      if (Get.context != null && !isDialogShowing) {
        print("Showing alert dialog for active alert found on startup");
        isDialogShowing = true;
        showAlertDialog(title: alertTitle, message: alertMessage);
      }
    }
  }
  
  // Save alert state
  Future<void> saveAlertState(bool active, [String? title, String? message]) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAlertActive', active);
    
    if (active && title != null && message != null) {
      await prefs.setString('alertTitle', title);
      await prefs.setString('alertMessage', message);
    }
  }

  // Initialize audio player
  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    
    // Pre-load the alarm sound to minimize delay when needed
    try {
      await _audioPlayer!.setAsset('assets/sounds/alarm.wav');
      print("Alarm sound asset loaded successfully");
    } catch (e) {
      print("Error pre-loading alarm sound: $e");
    }
  }

  // Background notification tap handler - required for new version
  static void notificationTapBackground(NotificationResponse notificationResponse) {
    // Handle notification taps in the background
    print('Notification tapped in background: ${notificationResponse.payload}');
  }

  // Foreground notification tap handler
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    // Request permissions for Android 13+ (Tiramisu and above)
    if (Platform.isAndroid) {
      await Permission.notification.request();
      
      // Request notification permission through the plugin for Android
      // Note: The exact method name may vary by version, so try to keep it simple
      try {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          // The requestNotificationsPermission method is available in newer versions
          await androidImplementation.requestNotificationsPermission();
        }
      } catch (e) {
        print("Error requesting Android notification permissions: $e");
      }
    }
  }

  // Show notification with specified title and message
  Future<void> showNotification({
    required String title, 
    required String message, 
    String channelId = 'alerts', 
    String channelName = 'Alerts', 
    String channelDescription = 'Server Room Alerts'
  }) async {
    // Android notification details
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );
    
    // iOS notification details
    DarwinNotificationDetails darwinPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    // Linux notification details
    LinuxNotificationDetails linuxPlatformChannelSpecifics =
        LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.critical,
      timeout: LinuxNotificationTimeout.fromDuration(Duration(seconds: 10)),
    );
    
    // General notification details
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
      macOS: darwinPlatformChannelSpecifics,
      linux: linuxPlatformChannelSpecifics,
    );
    
    // Show notification with a unique ID
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // Unique ID based on current time
      title,
      message,
      platformChannelSpecifics,
    );
  }

  // Start vibration alert
  Future<void> startVibrationAlert() async {
    if (!isAlertActive) {
      // Check if device has vibrator
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != null && hasVibrator) {
        try {
          // Start repeated vibration pattern - continuous until stopped
          Vibration.vibrate(
            pattern: [500, 1000, 500, 1000, 500, 1000],
            intensities: [128, 255, 128, 255, 128, 255],
            repeat: -1, // Loop indefinitely
          );
        } catch (e) {
          print("Error activating vibration: $e");
        }
      }
    }
  }

  // Stop vibration alert
  Future<void> stopVibrationAlert() async {
    await Vibration.cancel();
    alertTimer?.cancel();
    alertTimer = null;
  }
  
  // Set volume to half max for alarm
  Future<void> raiseVolume() async {
    try {
      // Save current volume first if not already saved
      if (_originalVolume == 0) {
        final volume = await VolumeController.instance.getVolume();
        _originalVolume = volume;
      }
      
      // Set volume to 0.5 (50%)
      await VolumeController.instance.setVolume(0.5);
      print("Device volume raised to 50%");
    } catch (e) {
      print("Error adjusting volume: $e");
    }
  }
  
  // Restore original volume
  Future<void> restoreVolume() async {
    try {
      if (_originalVolume > 0) {
        await VolumeController.instance.setVolume(_originalVolume);
        print("Device volume restored to $_originalVolume");
      }
    } catch (e) {
      print("Error restoring volume: $e");
    }
  }
  
  // Start alarm sound
  Future<void> startAlarmSound() async {
    // Simple, direct approach to playing alarm
    try {
      // Ensure we have a fresh audio player
      if (_audioPlayer != null) {
        _audioPlayer!.dispose();
      }
      
      _audioPlayer = AudioPlayer();
      
      // Set volume
      await _audioPlayer!.setVolume(0.8);
      
      // Set asset
      await _audioPlayer!.setAsset('assets/sounds/alarm.wav');
      
      // Loop the sound
      await _audioPlayer!.setLoopMode(LoopMode.all);
      
      // Play
      await _audioPlayer!.play();
      isAlarmSoundPlaying = true;
      print("Alarm sound playing");
    } catch (e) {
      print("Error playing alarm sound: $e");
    }
  }
  
  // Stop alarm sound
  Future<void> stopAlarmSound() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        isAlarmSoundPlaying = false;
      }
    } catch (e) {
      print("Error stopping alarm sound: $e");
    }
  }
  
  // Start full alert with notification, vibration, and sound
  Future<void> startFullAlert({
    required String sensorType, 
    required String value,
    bool showDialog = true
  }) async {
    // Only proceed if no alert is currently active
    if (isAlertActive) {
      print("Alert already active, not triggering another one");
      return;
    }
    
    isAlertActive = true;
    isDialogShowing = false; // Reset dialog flag to ensure it will show
    
    String title = '$sensorType Alert';
    String message = '$sensorType value out of expected range: $value';
    
    // Save alert state
    await saveAlertState(true, title, message);
    
    // Raise volume
    await raiseVolume();
    
    // Show notification
    await showNotification(
      title: title,
      message: message,
      channelId: 'sensor_alerts',
      channelName: 'Sensor Alerts',
      channelDescription: 'Alerts for sensor values exceeding thresholds',
    );
    
    // Start vibration
    await startVibrationAlert();
    
    // Start alarm sound
    await startAlarmSound();
    
    // Show alert dialog directly using Material showDialog only if requested
    // This won't show for critical alerts since they have their own dialog
    if (showDialog && Get.context != null) {
      // Reset dialog flag to allow showing
      isDialogShowing = true;
      
      // Using custom dialog implementation
      showAlertDialog(title: title, message: message);
      
      // Also call callback if available for redundancy
      if (onShowAlertDialog != null) {
        onShowAlertDialog!(title, message);
      }
    }
  }
  
  // Show alert dialog with stop button - default implementation
  void showAlertDialog({required String title, required String message}) {
    if (Get.context != null && !isDialogShowing) {
      isDialogShowing = true;
      AwesomeDialog(
        context: Get.context!,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        dismissOnTouchOutside: false,
        dismissOnBackKeyPress: false,
        title: title,
        desc: message,
        btnCancelText: 'STOP ALARM',
        btnCancelColor: Colors.red,
        btnCancelOnPress: () {
          stopAllAlerts();
          isDialogShowing = false;
        },
        headerAnimationLoop: false,
        onDismissCallback: (type) {
          isDialogShowing = false;
        },
      ).show();
    }
  }
  
  // Stop all alerts
  Future<void> stopAllAlerts() async {
    // Simple direct approach to stopping alerts
    try {
      // Stop vibration
      await Vibration.cancel();
      
      // Stop audio
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        isAlarmSoundPlaying = false;
      }
      
      // Reset flags
      isAlertActive = false;
      isDialogShowing = false;
      
      print("All alerts stopped");
    } catch (e) {
      print("Error stopping alerts: $e");
    }
  }

  // Clear any existing dialogs to ensure new critical alerts are visible
  void clearExistingDialogs() {
    // Clear any existing Get.dialog instances
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
    
    // Reset dialog flags
    isDialogShowing = false;
  }

  // Show notification and start vibration for sensor alerts (legacy method)
  Future<void> showSensorAlert({required String sensorType, required String value}) async {
    // Check if this will be a critical alert
    bool isCritical = false;
    
    // Check if value is in critical range
    if (sensorType == 'Temperature' && double.parse(value) > 27) {
      isCritical = true;
    } else if (sensorType == 'Gas' && double.parse(value) >= 500) {
      isCritical = true;
    } else if (sensorType == 'Noise' && double.parse(value) >= 4000) {
      isCritical = true;
    }
    
    // Start the full alert - always show dialog
    await startFullAlert(
      sensorType: sensorType, 
      value: value,
      showDialog: true
    );
    
    // Clear any existing dialogs to ensure this one is visible
    clearExistingDialogs();
    
    // If critical, show the critical dialog version
    if (isCritical) {
      // Set the appropriate message
      String message = '';
      if (sensorType == 'Temperature') {
        message = 'Temperature has reached critical level: $value°C';
      } else if (sensorType == 'Gas') {
        message = 'Gas level has reached critical level: $value';
      } else if (sensorType == 'Noise') {
        message = 'Noise level has reached critical level: $value';
      }
      
      // Add a small delay to ensure dialog shows after alarm starts
      await Future.delayed(Duration(milliseconds: 500));
      
      if (Get.context != null) {
        // Clear any existing dialogs to ensure this one is visible
        clearExistingDialogs();
        
        AwesomeDialog(
          context: Get.context!,
          dialogType: DialogType.warning,
          animType: AnimType.scale,
          dismissOnTouchOutside: false,
          dismissOnBackKeyPress: false,
          title: '$sensorType CRITICAL ALERT',
          titleTextStyle: TextStyle(
            color: Colors.red,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          desc: message,
          descTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          btnOkText: 'STOP ALARM',
          btnOkIcon: Icons.stop,
          btnOkColor: Colors.red,
          buttonsBorderRadius: BorderRadius.circular(8),
          buttonsTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          width: 400, // Make dialog wider
          padding: EdgeInsets.all(20),
          btnOkOnPress: () {
            stopAllAlerts();
          },
          headerAnimationLoop: true, // Keep animating the header for attention
          dialogBackgroundColor: Colors.white,
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ).show();
      }
    }
  }
}

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  bool isAlarmActive = false;
  double _alertVolume = 0.7; // Default alert volume

  @override
  void initState() {
    super.initState();
    // Set up notification service listener
    _setupNotificationServiceListener();
    
    // Load saved alert volume
    _loadAlertVolume();
  }
  
  // Load alert volume
  void _loadAlertVolume() async {
    // Get the current alert volume from notification service
    _alertVolume = _notificationService.alertVolume;
    setState(() {});
  }
  
  void _setupNotificationServiceListener() {
    // Set callback for showing alert dialog
    _notificationService.onShowAlertDialog = (String title, String message) {
      if (!_notificationService.isDialogShowing) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          dismissOnTouchOutside: false,
          dismissOnBackKeyPress: false,
          title: title,
          desc: message,
          btnCancelText: 'STOP ALARM',
          btnCancelColor: Colors.red,
          btnCancelOnPress: () {
            _notificationService.stopAllAlerts();
            setState(() => isAlarmActive = false);
          },
          headerAnimationLoop: false,
          onDismissCallback: (type) {
            _notificationService.isDialogShowing = false;
          },
        ).show();
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryCol,
        title: Text('Notifications'),
      ),
      body: GetBuilder<HomePageCtr>(
        builder: (gc) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Alerts',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                buildSwitch('Gas', gc.isGasActive, (value) {
                  gc.isGasActive = value;
                  gc.update();
                  print('## isGasActive : ${gc.isGasActive}');
                }),
                Text(
                  'Alert when gas level exceeds 500',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 20),
                buildSwitch('Temperature', gc.isTemperatureActive, (value) {
                  gc.isTemperatureActive = value;
                  gc.update();
                  print('## isTemperatureActive : ${gc.isTemperatureActive}');
                }),
                Text(
                  'Alert when temperature exceeds 24°',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 20),
                buildSwitch('Noise', gc.isNoiseActive, (value) {
                  gc.isNoiseActive = value;
                  gc.update();
                  print('## isNoiseActive : ${gc.isNoiseActive}');
                }),
                Text(
                  'Alert when noise level exceeds 4000',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 20),
                
                // Alert volume control
                Text(
                  'Alert Volume',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: _alertVolume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        activeColor: primaryCol,
                        onChanged: (newValue) {
                          setState(() {
                            _alertVolume = newValue;
                          });
                          _notificationService.saveAlertVolume(newValue);
                        },
                      ),
                    ),
                    Icon(Icons.volume_up),
                  ],
                ),
                Text(
                  'Alarm volume: ${(_alertVolume * 100).toInt()}%',
                  style: TextStyle(color: Colors.grey),
                ),
                
                SizedBox(height: 40),
                if (isAlarmActive || _notificationService.isAlertActive)
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Stop all alerts
                        _notificationService.stopAllAlerts();
                        setState(() => isAlarmActive = false);
                      },
                      child: Text('STOP ALARM', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildSwitch(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 18)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
      ],
    );
  }
}
