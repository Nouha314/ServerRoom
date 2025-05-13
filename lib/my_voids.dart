import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:server_room_new/main.dart';
import 'package:server_room_new/models/user.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

SrUser currentUser = SrUser();
 FirebaseDatabase? get database => FirebaseDatabase.instance;

var usersColl = FirebaseFirestore.instance.collection('users');

Future<List<DocumentSnapshot>> getDocumentsByColl(coll) async {
  QuerySnapshot snap = await coll.get();

  final List<DocumentSnapshot> documentsFound = snap.docs;

  print('## collection docs number => (${documentsFound.length})');

  return documentsFound;
}

toastShow(text, {Color? color}) {
  Get.rawSnackbar(
    messageText: Text( // Your main message content
        text,
        style: TextStyle(color: Colors.white,fontSize: 15)
    ),
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor:color?? Colors.black45,

    margin: EdgeInsets.all(10),
    duration: Duration(seconds: 2),
  );
}

double getDoubleMinValue(List<double> values) {
  return values.reduce((currentMin, value) => value < currentMin ? value : currentMin);
}
double getDoubleMaxValue(List<double> values) {
  return values.reduce((currentMax, value) => value > currentMax ? value : currentMax);
}

double replaceWithClosestHalf(double value) {
  int intValue = value.toInt();
  double decimalPart = value - intValue;

  if (decimalPart < 0.25) {
    return intValue.toDouble();
  } else if (decimalPart >= 0.25 && decimalPart < 0.75) {
    return intValue.toDouble() + 0.5;
  } else {
    return intValue.toDouble() + 1.0;
  }
}

double getMinValue(List<String> values) {
  List<double> doubleList = values.map((str) => double.parse(str)).toList();
  double minValue = doubleList.reduce((currentMin, value) => value < currentMin ? value : currentMin);
  return minValue;
}

double getMaxValue(List<String> values) {
  List<double> doubleList = values.map((str) => double.parse(str)).toList();
  double maxValue = doubleList.reduce((currentMax, value) => value > currentMax ? value : currentMax);
  return maxValue;
}
changeUserName(String newName) {

}
void changeUserInfo(String newName,String newEmail, String newPassword) async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      if(newName!= '') await changeUserName(newName);

      // Change email
      if(newEmail!= '') await user.updateEmail(newEmail).then((value) {

        usersColl.doc(currentUser.id).get().then((DocumentSnapshot documentSnapshot) async {
          if (documentSnapshot.exists) {
            await usersColl.doc(currentUser.id).update({
              'email': newEmail, // turn verified to true in  db
            }).then((value) async {
              showSnk('email updated');

            }).catchError((error) async {
            });
          }
        });
      });

      // Change password
      if(newPassword!= '')  await user.updatePassword(newPassword).then((value){
        usersColl.doc(currentUser.id).get().then((DocumentSnapshot documentSnapshot) async {
          if (documentSnapshot.exists) {
            await usersColl.doc(currentUser.id).update({
              'pwd': newPassword, // turn verified to true in  db
            }).then((value) async {
              showSnk('password updated');

            }).catchError((error) async {
            });
          }
        });
      });


      if(newPassword!= '' || newPassword!= '' || newPassword!= ''){
        // ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        //   SnackBar(content: Text("Profile info modified successfully!"),backgroundColor: Colors.green.withOpacity(0.6)),
        // );

        Get.back();
      }else{

        showSnk('no new info to modify');

      }


      print('## Email and password updated successfully');
    } catch (e) {

      showSnk('This operation is sensitive and requires recent authentication.\n Log in again before retrying this request');

      print('## Failed to update email and password:===> $e');
    }
  }
}

// String getMinValue(List<String> values) {
//   return values.reduce((currentMin, value) {
//     return (value.compareTo(currentMin) < 0) ? value : currentMin;
//   });
// }
// String getMaxValue(List<String> values) {
//   return values.reduce((currentMax, value) {
//     return (value.compareTo(currentMax) > 0) ? value : currentMax;
//   });
// }

String formatNumberAfterComma(String number) {
  //final string = number.toString();
  if(number.contains('.')){
    final decimalIndex = number.indexOf('.');
    final end = min(decimalIndex + 3, number.length);
    return number.substring(0, end);
  }else{
    return number;
  }

}


showSnk(txt,{Color? clr}){
  ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
    SnackBar(content: Text(txt),backgroundColor: clr,),
  );
}
dialogShow(title, desc, {bool isSuccessful = false, bool autoHide = false}) {
  AwesomeDialog(
    autoDismiss: true,
    context: navigatorKey.currentContext!,
    dismissOnBackKeyPress: false,
    headerAnimationLoop: false,
    dismissOnTouchOutside: false,
    animType: AnimType.leftSlide,
    dialogType: isSuccessful ? DialogType.success : DialogType.error,
    //showCloseIcon: true,
    title: title,
    autoHide: autoHide ? Duration(seconds: 1) : null,

    btnOkColor: isSuccessful ? Color(0xFF00B962) : Color(0xFFD0494A),
    buttonsTextStyle: TextStyle(fontSize: 16, color: Colors.white),
    descTextStyle: TextStyle(
      height: 1.8,
      fontSize: 14,
    ),
    desc: desc,
    btnOkText: 'Ok',

    btnOkOnPress: () {},
    // onDissmissCallback: (type) {
    //   debugPrint('## Dialog Dissmiss from callback $type');
    // },
    //btnOkIcon: Icons.check_circle,
  ).show();
}

Future<bool> showNoHeader({String? txt,String? btnOkText='delete',Color btnOkColor=Colors.red,IconData? icon=Icons.delete}) async {
  bool shouldDelete = false;

  await AwesomeDialog(
    context: navigatorKey.currentContext!,
    autoDismiss: true,
    isDense: true,
    dismissOnTouchOutside: true,
    showCloseIcon: false,
    headerAnimationLoop: false,
    dialogType: DialogType.noHeader,
    animType: AnimType.scale,
    btnCancelIcon: Icons.close,
    btnCancelColor: Colors.grey,
    btnOkIcon: icon ?? Icons.delete,
    btnOkColor: btnOkColor,
    buttonsTextStyle: TextStyle(fontSize: 17, color: Colors.white),
    btnCancelText: 'cancel',
    btnOkText: btnOkText!,
    // texts
    title: 'Verification',
    desc: txt ?? 'Are you sure you want to deny this user request',
    padding: EdgeInsets.symmetric(vertical: 15,horizontal: 10),

    // buttons functions
    btnOkOnPress: () {
      shouldDelete = true;
    },
    btnCancelOnPress: () {
      shouldDelete = false;
    },
  ).show();
  return shouldDelete;
}

Future<bool> showThresholdAlert({
  required String value,
  required String thresholdType,
  String title = 'Threshold Alert',
  String? message,
  bool autoDismiss = false,
}) async {
  bool shouldStop = false;
  
  await AwesomeDialog(
    context: navigatorKey.currentContext!,
    autoDismiss: autoDismiss,
    dismissOnBackKeyPress: false,
    headerAnimationLoop: false,
    dismissOnTouchOutside: false,
    animType: AnimType.scale,
    dialogType: DialogType.warning,
    title: title,
    buttonsTextStyle: TextStyle(fontSize: 17, color: Colors.white),
    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    desc: message ?? '$thresholdType value has reached $value which exceeds the threshold!',
    btnCancelText: 'Continue',
    btnOkText: 'Stop',
    btnCancelIcon: Icons.play_arrow,
    btnCancelColor: Colors.green,
    btnOkIcon: Icons.stop,
    btnOkColor: Colors.red,
    
    btnOkOnPress: () {
      shouldStop = true;
    },
    btnCancelOnPress: () {
      shouldStop = false;
    },
  ).show();
  
  return shouldStop;
}

/// add DOCUMENT to fireStore
Future<void> addDocument({required fieldsMap, required String collName, bool addID = true}) async {
  CollectionReference coll = FirebaseFirestore.instance.collection(collName);

  coll.add(fieldsMap).then((value) async {
    print("## DOC ADDED TO <$collName>");

    //add id to doc
    if (addID) {
      String docID = value.id;
      //set id
      coll.doc(docID).update(
        {
          'id': docID,
        },
        //SetOptions(merge: true),
      );
    }
  }).catchError((error) {
    print("## Failed to add doc to <$collName>: $error");
  });
}
