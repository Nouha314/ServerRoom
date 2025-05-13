import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:volume_controller/volume_controller.dart';

import '../my_voids.dart';
import '../notifications.dart';

class HomePageCtr extends GetxController {
   StreamSubscription<DatabaseEvent>? streamData;
   final NotificationService _notificationService = NotificationService();

   String newestChartValue ='0';
   bool isGasActive = true;
   bool isTemperatureActive = true;
   bool isNoiseActive = true;


   Color chartColTem = Colors.green;
   bool shouldSnoozeTem = true;
   bool isInDangerTem = false;
   checkDangerTemState() async {
     if(double.parse(tem_data) <= 24 ){
       chartColTem = Colors.green;
       isInDangerTem = false;
       shouldSnoozeTem = true; // Reset snooze when value returns to normal
     } else {
       // Temperature exceeds threshold
       if(double.parse(tem_data) > 27){
         chartColTem = Colors.red;
       } else {
         chartColTem = Colors.orange;
       }
       
       isInDangerTem = true;
       
       if(shouldSnoozeTem && isTemperatureActive){
         shouldSnoozeTem = false;
         
         // Play sound at maximum volume
         playAlarmAtMaxVolume();
         
         // Send notification
         _notificationService.showNotification(
           title: 'Temperature Alert',
           message: 'Temperature value is out of range: $tem_data°C',
         );
         
         // Show dialog
         AwesomeDialog(
           context: Get.context!,
           dialogType: DialogType.error,
           animType: AnimType.scale,
           dismissOnTouchOutside: false,
           dismissOnBackKeyPress: false,
           title: 'Temperature Alert',
           desc: 'Temperature value is out of range: $tem_data°C',
           btnCancelText: 'STOP ALARM',
           btnCancelColor: Colors.red,
           btnCancelOnPress: () {
             stopAllAlarms();
           },
           headerAnimationLoop: true,
         ).show();
       }
     }
   }


   Color chartColGas = Colors.green;
   bool shouldSnoozeGas = true;
   bool isInDangerGas = false;
   checkDangerGasState() async {
     if(double.parse(gas_data) < 500 ){
       chartColGas = Colors.green;
       isInDangerGas = false;
       shouldSnoozeGas = true; // Reset snooze when value returns to normal
     } else {
       // Gas exceeds threshold
       chartColGas = Colors.red;
       isInDangerGas = true;
       
       if(shouldSnoozeGas && isGasActive){
         shouldSnoozeGas = false;
         
         // Play sound at maximum volume
         playAlarmAtMaxVolume();
         
         // Send notification
         _notificationService.showNotification(
           title: 'Gas Alert',
           message: 'Gas level is out of range: $gas_data',
         );
         
         // Show dialog
         AwesomeDialog(
           context: Get.context!,
           dialogType: DialogType.error,
           animType: AnimType.scale,
           dismissOnTouchOutside: false,
           dismissOnBackKeyPress: false,
           title: 'Gas Alert',
           desc: 'Gas level is out of range: $gas_data',
           btnCancelText: 'STOP ALARM',
           btnCancelColor: Colors.red,
           btnCancelOnPress: () {
             stopAllAlarms();
           },
           headerAnimationLoop: true,
         ).show();
       }
     }
   }

   Color chartColNoise = Colors.green;
   bool shouldSnoozeNoise = true;
   bool isInDangerNoise = false;
   checkDangerNoiseState() async {
     if(double.parse(noise_data) < 4000 ){
       chartColNoise = Colors.green;
       isInDangerNoise = false;
       shouldSnoozeNoise = true; // Reset snooze when value returns to normal
     } else {
       // Noise exceeds threshold
       chartColNoise = Colors.red;
       isInDangerNoise = true;
       
       if(shouldSnoozeNoise && isNoiseActive){
         shouldSnoozeNoise = false;
         
         // Play sound at maximum volume
         playAlarmAtMaxVolume();
         
         // Send notification
         _notificationService.showNotification(
           title: 'Noise Alert',
           message: 'Noise level is out of range: $noise_data',
         );
         
         // Show dialog
         AwesomeDialog(
           context: Get.context!,
           dialogType: DialogType.error,
           animType: AnimType.scale,
           dismissOnTouchOutside: false,
           dismissOnBackKeyPress: false,
           title: 'Noise Alert',
           desc: 'Noise level is out of range: $noise_data',
           btnCancelText: 'STOP ALARM',
           btnCancelColor: Colors.red,
           btnCancelOnPress: () {
             stopAllAlarms();
           },
           headerAnimationLoop: true,
         ).show();
       }
     }
   }

   // Play alarm using user's volume setting
   void playAlarmAtMaxVolume() {
     try {
       // Stop any existing sounds first
       _notificationService.stopAllAlerts();
       
       // Save current device volume before changing it
       VolumeController.instance.getVolume().then((currentVolume) {
         _originalVolume = currentVolume;
         print("📱 Saved original volume: $_originalVolume");
         
         // Set device volume to 80%
         VolumeController.instance.setVolume(0.8);
         print("📱 Device volume set to 80%");
       });
       
       // Make sure we get a totally fresh player each time
       AudioPlayer player = AudioPlayer();
       
       // Set player volume to max since we're controlling device volume
       player.setVolume(1.0);
       
       // Load and play sound with loop
       player.setAsset('assets/sounds/alarm.wav');
       player.setLoopMode(LoopMode.all);
       player.play();
       
       // We keep our own reference to the player to stop it later
       if (_alarmPlayer != null) {
         _alarmPlayer!.dispose();
       }
       _alarmPlayer = player;
       
       // Also start vibration
       startVibration();
       
       print("🔊 Playing alarm with device volume at 80%");
     } catch (e) {
       print("⚠️ Error playing alarm: $e");
     }
   }
   
   // Store original volume to restore later
   double _originalVolume = 0.0;
   
   // Start device vibration
   void startVibration() {
     try {
       Vibration.hasVibrator().then((hasVibrator) {
         if (hasVibrator != null && hasVibrator) {
           Vibration.vibrate(
             pattern: [500, 1000, 500, 1000, 500, 1000],
             intensities: [128, 255, 128, 255, 128, 255],
             repeat: -1,
           );
           print("📳 Vibration started");
         }
       });
     } catch (e) {
       print("⚠️ Error starting vibration: $e");
     }
   }
   
   // Local reference to alarm player
   AudioPlayer? _alarmPlayer;

  int periodicUpdateData = 1000;
  //String gas_tapped_val = '00.00';
  String gas_data = '0';
  String noise_data = '0';
  String tem_data = '0';
  String? selectedServer ;
  bool showTime = true;
  int serversNumber = 0 ;
  List<String> servers = [];
  int tickPeriod = 5;
  String bottomTitleTime = '';
  List<double> tempDataPts = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ]; // initial data points
  List<double> noiseDataPts = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ]; // initial data points
  List<double> gasDataPts = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ]; // initial data points
  int xIndexsGas = 0;
  int xIndexsTem = 0;
  int xIndexsNoise = 0;
  DateTime startDateTime = DateTime.now();

  // Variables for history rate limiting
  Map<String, DateTime> lastHistorySaveTime = {};
  Map<String, String> lastHistorySaveValue = {}; // Track last saved value
  int historyRateLimitSeconds = 10; // Save history once per 10 seconds

  @override
  void onInit() {
    super.onInit();
    startDateTime = startDateTime.subtract(Duration(seconds:gasDataPts.length -1));
    
    // Reset snooze flags to ensure alerts will show on startup
    shouldSnoozeGas = true;
    shouldSnoozeTem = true;
    shouldSnoozeNoise = true;

    // Set up notification service's dialog callback
    _setupNotificationService();
    
    // Check and clear old history data
    clearOldHistoryData();
    
    // Schedule periodic history cleaning
    setupPeriodicHistoryCleaning();

    Future.delayed(const Duration(milliseconds: 0), () async {//time to start readin data
      periodicFunction();

        await getChildrenLength().then((value) {
          serversNumber=value;
        if(servers.isNotEmpty){

          print('## servers.isNotEmpty');
          changeServer(servers[0]);
          
          // Check if servers have history data
          checkAndInitializeHistoryForAllServers();
          
          //realTimeListen();// start streamData
          // update(['chart']);
          // update(['chart0']);
          // update(['chart1']);
          // update(['appBar']);
        }else{
          print('## servers = Empty');

          selectedServer='';
        }
      }); //1

    });
  }

  // Set up the notification service to show dialogs
  void _setupNotificationService() {
    // Just ensure the notification service is properly initialized
    _notificationService.onShowAlertDialog = (title, message) {
      // If a dialog is shown through the notification service, also stop our local alarm
      stopLocalAlarm();
    };
  }

  // Check and initialize history for all existing servers
  checkAndInitializeHistoryForAllServers() async {
    for (String server in servers) {
      // Check if history data exists for this server
      bool hasGasHistory = await hasHistoryData('Vasr/$server/gas');
      bool hasSoundHistory = await hasHistoryData('Vasr/$server/sound');
      bool hasTemperatureHistory = await hasHistoryData('Vasr/$server/temperature');
      
      if (!hasGasHistory || !hasSoundHistory || !hasTemperatureHistory) {
        print('## Initializing missing history data for server: $server');
        
        // Get current values
        DatabaseReference serverRef = database!.ref('Vasr/$server');
        final snapshot = await serverRef.get();
        
        if (snapshot.exists) {
          String gasValue = snapshot.child('gas_once').value.toString();
          String soundValue = snapshot.child('sound_once').value.toString();
          String tempValue = snapshot.child('temperature_once').value.toString();
          
          // Create history entries if they don't exist
          if (!hasGasHistory) saveToHistory(server, 'gas', gasValue);
          if (!hasSoundHistory) saveToHistory(server, 'sound', soundValue);
          if (!hasTemperatureHistory) saveToHistory(server, 'temperature', tempValue);
        }
      }
    }
  }
  
  // Check if history data exists for a path
  Future<bool> hasHistoryData(String path) async {
    DatabaseReference ref = database!.ref(path);
    final snapshot = await ref.get();
    return snapshot.exists && snapshot.children.isNotEmpty;
  }

  changeServer(server) async {
    selectedServer = server;
    print('## change server to server => ${selectedServer}');

    if(streamData != null) await streamData!.cancel();

    realTimeListen(server);
    
    // Fetch initial data and check thresholds
    await performInitialThresholdCheck(server);

    // update(['appBar']);
    // update(['chart']);
  }

  // Performs an initial check for threshold violations when selecting a server
  Future<void> performInitialThresholdCheck(String server) async {
    try {
      DatabaseReference serverRef = database!.ref('Vasr/$server');
      final snapshot = await serverRef.get();
      
      if (snapshot.exists) {
        // Get current values
        gas_data = snapshot.child('gas_once').value.toString();
        noise_data = snapshot.child('sound_once').value.toString();
        tem_data = snapshot.child('temperature_once').value.toString();
        
        print('## Initial threshold check: <gas: $gas_data /tem: $tem_data /noise: $noise_data >');
        
        // Reset snooze flags to ensure alerts show on startup if thresholds are exceeded
        shouldSnoozeGas = true;
        shouldSnoozeTem = true;
        shouldSnoozeNoise = true;
        
        // Check all thresholds
        checkDangerGasState();
        checkDangerTemState();
        checkDangerNoiseState();
      }
    } catch (e) {
      print('## Error during initial threshold check: $e');
    }
  }

Future<int> getChildrenLength() async {
    String userID = currentUser.id!;
    int serverNumbers = 0;
  DatabaseReference serverData = database!.ref('Vasr');
    //servers = sharedPrefs!.getStringList('servers') ?? ['server1'];

    final snapshot = await serverData.get();

  if (snapshot.exists) {
    serverNumbers = snapshot.children.length;
     snapshot.children.forEach((element) {
      //print('## ele ${element.key}');
      servers.add(element.key.toString());
    });
    print('## <$userID> exists with [${serverNumbers}]servers:<$servers> server');
  } else {
    print('## <$userID> DONT exists');
  }

    //update(['chart']);
  return serverNumbers;
}



/// ADD-SERVER ////////////////:
   Future<String?> getServerNameDialog(BuildContext context) {
      TextEditingController _textEditingController = TextEditingController();
      final _serverFormKey = GlobalKey<FormState>();


      return showDialog<String>(
       context: context,
       builder: (BuildContext context) {
         return AlertDialog(
           title: Text('Server Name'),
           content: Form(
             key: _serverFormKey,
             child: TextFormField(
               controller: _textEditingController,
               decoration: InputDecoration(
                 labelText: 'Enter Server Name',
               ),
               validator: (value) {
                 if (value!.isEmpty) {
                   return 'Server name cannot be empty';
                 }
                 if(servers.contains(value)){
                   return 'Server name already exist';

                 }
                 return null;
               },
             ),
           ),

           actions: [
             ElevatedButton(
               onPressed: () {
                String sName = _textEditingController.text;
                 //if(sName.isNotEmpty && servers.contains(sName))
                if(_serverFormKey.currentState!.validate()){
                  Navigator.of(context).pop(sName);
                }
               },
               child: Text('Save'),
             ),
           ],
         );
       },
     );
   }
   addServer(context) async {
    //String serverName = 'server${serversNumber + 1}';

    String serverName = await getServerNameDialog(context)??'null';
    print('## serverName<written>: $serverName');
    if(serverName=='null') return;



    serverAdded() async {
      print('## <$serverName> ADDED!');
      //servers.insert(0, serverName);
      //sharedPrefs!.setStringList('servers', servers);
      servers.clear();
      serversNumber = await getChildrenLength();
      changeServer(serverName);
      
      // Initialize history data for the new server
      initializeHistoryForServer(serverName);
      
      print('## +saved servers: <$serversNumber>:<$servers>');
    }

    DatabaseReference serverData = database!.ref('Vasr');
    await serverData.update({
      "$serverName": {
        "gas_once": 0.0,
        "sound_once": 0,
        "temperature_once": 0.0,
      }
    }).then((value) async {
      await serverAdded();
    });



    //update(['chart']);

  }
  
  // Initialize history data for a new server
  initializeHistoryForServer(String server) {
    // Create initial history entries
    saveToHistory(server, 'gas', '0.0');
    saveToHistory(server, 'sound', '0');
    saveToHistory(server, 'temperature', '0.0');
  }
   removeServer(serverName) async {
     await database!.ref('Vasr/$serverName').remove().then((value) async {
       print('##  < $serverName > removed!');
     });
     servers.remove(serverName);
     update(['appBar']);
   }
   /// /////////////////////



  List<FlSpot> generateSpotsGas(dataPts) {
    //print('## generate spots...');
    List<FlSpot> spots = [];
    for (int i = 0 + xIndexsGas; i < dataPts.length + xIndexsGas; i++) {
      //bool isLast = i % spots.length == 0;
      spots.add(
          FlSpot(
              //isLast? bottomTitleTime :i.toDouble(),//X
              i.toDouble(),//X
              dataPts[i - xIndexsGas]
          )//Y
      );
    }
    xIndexsGas++;
    return spots;
  }

  List<FlSpot> generateSpotsTem(dataPts) {
    //print('## generate spots...');
    List<FlSpot> spots = [];
    for (int i = 0 + xIndexsTem; i < dataPts.length + xIndexsTem; i++) {
      //bool isLast = i % spots.length == 0;
      spots.add(
          FlSpot(
              //isLast? bottomTitleTime :i.toDouble(),//X
              i.toDouble(),//X
              dataPts[i - xIndexsTem]
          )//Y
      );
    }
    xIndexsTem++;
    return spots;
  }

  List<FlSpot> generateSpotsNoise(dataPts) {
    //print('## generate spots...');
    List<FlSpot> spots = [];
    for (int i = 0 + xIndexsNoise; i < dataPts.length + xIndexsNoise; i++) {
      //bool isLast = i % spots.length == 0;
      spots.add(
          FlSpot(
              //isLast? bottomTitleTime :i.toDouble(),//X
              i.toDouble(),//X
              dataPts[i - xIndexsNoise]
          )//Y
      );
    }
    xIndexsNoise++;
    return spots;
  }


  /// UPDATE-DATA-PTS //////
   updateGasDataPoints(newData) {
    double getNewDataPoint= double.parse(newData); // your code to retrieve new data point here
    // update data points and rebuild chart
    gasDataPts.removeAt(0); // remove oldest data point
    gasDataPts.add(getNewDataPoint); // add new data point
  }
   updateTempDataPoints(newData) {
    double getNewDataPoint= double.parse(newData); // your code to retrieve new data point here
    // update data points and rebuild chart
    tempDataPts.removeAt(0); // remove oldest data point
    tempDataPts.add(getNewDataPoint); // add new data point
  }
   updateSoundDataPoints(newData) {
    double getNewDataPoint= double.parse(newData); // your code to retrieve new data point here
    // update data points and rebuild chart
    noiseDataPts.removeAt(0); // remove oldest data point
    noiseDataPts.add(getNewDataPoint); // add new data point
  }
  /// //////////////////////


  periodicFunction() {
    //print('## start periodic ...');

    Timer.periodic(Duration(milliseconds: 1000), (timer) {

      updateGasDataPoints(gas_data);
      updateTempDataPoints(tem_data);
      updateSoundDataPoints(noise_data);

      update(['chart']);
      update(['appBar']);

    });

  }

  realTimeListen(String ser) async {
    print('## realTimeListen <Vasr/$ser> ...');
    //DatabaseReference serverData = database!.ref('Vasr/$server');
    DatabaseReference serverData = database!.ref('Vasr/$ser');
      streamData = serverData.onValue.listen((DatabaseEvent event) {


      // /////////////
      gas_data = event.snapshot.child('gas_once').value.toString();
      noise_data = event.snapshot.child('sound_once').value.toString();
      tem_data = event.snapshot.child('temperature_once').value.toString();

      // Save values to history
      saveToHistory(ser, 'gas', gas_data);
      saveToHistory(ser, 'sound', noise_data);
      saveToHistory(ser, 'temperature', tem_data);

      print('## LAST_read_data: <gas: $gas_data /tem: $tem_data /noise: $noise_data >');
      
      // Check for threshold violations
      checkDangerGasState();
      checkDangerTemState();
      checkDangerNoiseState();
      
      //print('## gas_data_pointd:$gasValueList');

      update(['chart']);

    });
  }

  // Save sensor values to history
  saveToHistory(String server, String sensorType, String value) {
    // Generate key for tracking last save time and value
    String key = '$server-$sensorType';
    DateTime now = DateTime.now();
    
    // Check if value has changed from last saved value
    if (lastHistorySaveValue.containsKey(key) && lastHistorySaveValue[key] == value) {
      // Skip if value hasn't changed
      return;
    }
    
    // Check for rate limiting (max once per 10 seconds)
    if (lastHistorySaveTime.containsKey(key)) {
      Duration timeSinceLastSave = now.difference(lastHistorySaveTime[key]!);
      if (timeSinceLastSave.inSeconds < historyRateLimitSeconds) {
        // Skip this save operation due to rate limiting
        return;
      }
    }
    
    // Update the last save time and value
    lastHistorySaveTime[key] = now;
    lastHistorySaveValue[key] = value;
    
    // Generate a unique ID based on timestamp
    String timeId = now.millisecondsSinceEpoch.toString();
    String currentTime = now.toString();
    
    // Create reference to the history path
    DatabaseReference historyRef = database!.ref('Vasr/$server/$sensorType/$timeId');
    
    // Save the data with timestamp
    historyRef.set({
      'value': double.parse(value),
      'time': currentTime,
    }).then((_) {
      print('## Saved $sensorType history: $value at $currentTime');
    }).catchError((error) {
      print('## Error saving $sensorType history: $error');
    });
  }


   // void sendNotif({String? name,String? idNotifRecever,String? bpm }){ // just the patient do THIS
   //
   //   print('## sending notif ..... ');
   //
   //
   //   NotificationController.createNewStoreNotification('', '');
   //
   //
   // }

// realTimeOnceListen(userID, server)  {
  //
  //   Timer.periodic(Duration(milliseconds: periodicUpdateData), (timer) async {
  //     DatabaseReference serverData = database!.ref('rooms/$userID/$server');
  //
  //     final snapshot = await serverData.get();
  //
  //     if (snapshot.exists) {
  //       gas_data = snapshot.child('gas').value.toString();
  //       updateDataPoints(gas_data);
  //
  //       print('## value_changing... <$gas_data>');
  //
  //
  //     } else {
  //       print('## No data available.');
  //     }
  //   });
  // }

  // Clear history data older than 4 months
  Future<void> clearOldHistoryData() async {
    print('## Checking for old history data to clear...');
    
    // Get current date
    DateTime now = DateTime.now();
    // Calculate date 4 months ago
    DateTime fourMonthsAgo = DateTime(now.year, now.month - 4, now.day);
    
    // For each server and sensor type
    for (String server in servers.isEmpty ? ['TheRoom'] : servers) {
      await clearOldSensorHistoryData(server, 'gas', fourMonthsAgo);
      await clearOldSensorHistoryData(server, 'sound', fourMonthsAgo);
      await clearOldSensorHistoryData(server, 'temperature', fourMonthsAgo);
    }
  }
  
  // Clear old history data for a specific sensor type
  Future<void> clearOldSensorHistoryData(String server, String sensorType, DateTime cutoffDate) async {
    try {
      DatabaseReference historyRef = database!.ref('Vasr/$server/$sensorType');
      final snapshot = await historyRef.get();
      
      if (snapshot.exists) {
        List<String> keysToDelete = [];
        
        snapshot.children.forEach((child) {
          try {
            // Get timestamp from child data
            Map<dynamic, dynamic> data = child.value as Map<dynamic, dynamic>;
            String timeString = data['time'] as String;
            DateTime entryTime = DateTime.parse(timeString);
            
            // If entry is older than cutoff date, mark for deletion
            if (entryTime.isBefore(cutoffDate)) {
              keysToDelete.add(child.key as String);
            }
          } catch (e) {
            print('## Error parsing date for history entry: $e');
          }
        });
        
        // Delete old entries
        for (String key in keysToDelete) {
          await historyRef.child(key).remove();
        }
        
        if (keysToDelete.isNotEmpty) {
          print('## Cleared ${keysToDelete.length} old history entries for $server $sensorType');
        }
      }
    } catch (e) {
      print('## Error clearing old history data: $e');
    }
  }

  // Timer for periodic history cleaning
  Timer? _historyCleanupTimer;
  
  // Setup periodic history cleaning (once a month)
  void setupPeriodicHistoryCleaning() {
    // Cancel existing timer if any
    _historyCleanupTimer?.cancel();
    
    // Schedule periodic cleaning (every 30 days)
    // For testing/demo purposes, you might want to use a shorter period
    _historyCleanupTimer = Timer.periodic(Duration(days: 30), (timer) {
      clearOldHistoryData();
    });
  }
  
  // Ensure we stop both the notification service alarm and our local alarm
  void stopAllAlarms() {
    _notificationService.stopAllAlerts();
    stopLocalAlarm();
  }
   
  // Stop the local alarm
  void stopLocalAlarm() {
    if (_alarmPlayer != null) {
      try {
        _alarmPlayer!.stop();
        print("🔊 Stopped local alarm");
      } catch (e) {
        print("⚠️ Error stopping local alarm: $e");
      }
    }
    
    // Restore original device volume
    if (_originalVolume > 0) {
      VolumeController.instance.setVolume(_originalVolume);
      print("📱 Restored device volume to: $_originalVolume");
    }
    
    // Stop vibration
    try {
      Vibration.cancel();
      print("📳 Vibration stopped");
    } catch (e) {
      print("⚠️ Error stopping vibration: $e");
    }
  }

  @override
  void onClose() {
    // Dispose of the alarm player
    _alarmPlayer?.dispose();
    
    // Cancel timer when controller is disposed
    _historyCleanupTimer?.cancel();
    
    // Cancel existing stream subscription
    streamData?.cancel();
    
    super.onClose();
  }
}

///read once
// final ref = FirebaseDatabase.instance.ref();
// final snapshot = await ref.child('users/key0').get();
// if (snapshot.exists) {
//   print('## dataref: ${snapshot.value}');
//
// } else {
//   print('## No data available.');
// }
///
