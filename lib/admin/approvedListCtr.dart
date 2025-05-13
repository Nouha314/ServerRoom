import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:server_room_new/main.dart';

import '../models/user.dart';
import '../my_voids.dart';

class UsersCtr extends GetxController {
   StreamSubscription<QuerySnapshot>?  streamSub;

  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(milliseconds: 50), () {
      getUsersData();
      //streamingDoc(usersColl,authCtr.cUser.id!);
    });
  }

  Map<String, SrUser> userMap = {};
  Map<String, SrUser> userMapReq = {};

  List<SrUser> userList = [];
  List<SrUser> userListReq = [];

  List<SrUser> foundUsersList = [];
  final TextEditingController typeAheadController = TextEditingController();
  bool shouldLoad = true;
  bool typing = false;

  getUsersData() async {
    print('## downloading users from fireBase...');
    List<DocumentSnapshot> usersData = await getDocumentsByColl(usersColl.where('isAdmin', isEqualTo: false));

    // Remove any existing users
    userMap.clear();
    userMapReq.clear();

    //fill user map
    for (var _user in usersData) {
      if (_user.get('verified') == true)
        userMap[_user.id] = SrUserFromMap(_user);//verified in list
      else
        userMapReq[_user.id] = SrUserFromMap(_user);// not verifies in other list
    }

    userList = userMap.entries.map((entry) => entry.value).toList();
    userListReq = userMapReq.entries.map((entry) => entry.value).toList();

    foundUsersList = userList;
    shouldLoad = false;
    print('## < ${userMap.length} > users loaded from database');
    update();
  }

  // search voids
  void runFilterList(String enteredKeyword) {
    print('## running filter ...');
    List<SrUser>? results = [];

    if (enteredKeyword.isEmpty) {
      results = userList;
    } else {
      results = userList.where((user) => user.name!.toLowerCase().contains(enteredKeyword.toLowerCase())).toList();
    }

    foundUsersList = results;
    update();
  }
  clearSelectedProduct() async {
    typeAheadController.clear();
    runFilterList(typeAheadController.text);
    appBarTyping(false);
    update();
  }
  appBarTyping(typ) {
    typing = typ;
    update();
  }
  // //////


  addFirstServer(userID) async {

    DatabaseReference serverData = database!.ref('Vasr');
    await serverData.update({
      "$userID}": {
        "server1": {
          "gas": {},
          "noise": {},
          "tem": {},
        }
      }
    }).then((value) async {
      print('##  < First_Server > ADDED!');
    });

    //update(['chart']);

  }
  removeUserServers(userID) async {
    database!.ref('rooms/$userID').remove().then((value) async {
      print('##  < $userID > Servers removed!');
    });
  }


  acceptUser(String userID) {
    usersColl.doc(userID).get().then((DocumentSnapshot documentSnapshot) async {
      if (documentSnapshot.exists) {
        await usersColl.doc(userID).update({
          'verified': true, // turn verified to true in  db
        }).then((value) async {
          //addFirstServer(userID);
          print('## user request accepted');
          toastShow('user request accepted');
        }).catchError((error) async {
          print('## user request accepted accepting error =${error}');
          toastShow('user request accepted accepting error');
        });
      }
    });
  }





  makeUserAdmin(String userID) {
    usersColl.doc(userID).get().then((DocumentSnapshot documentSnapshot) async {
      if (documentSnapshot.exists) {
        await usersColl.doc(userID).update({
          'isAdmin': true, // turn verified to true in  db
        }).then((value) async {
          //addFirstServer(userID);
          print('## user is admin now');
          toastShow('user is admin now');
        }).catchError((error) async {
          //print('## user request accepted accepting error =${error}');
          toastShow('user making admin error');
        });
      }
    });
  }
  deleteUser(String userID) {
    usersColl.doc(userID).delete().then((value) async {
      print('## user deleted');
      //removeUserServers(userID);
      toastShow('user deleted');
    }).catchError((error) async {
      print('## user deleting error = ${error}');
      toastShow('user deleting error');
    });
    ;
  }

  Widget userCard0(SrUser user, {bool hasRequest = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        height: 100,
        child: Stack(
          children: [
            Card(
              shadowColor: Colors.black,
              //color: Colors.blueGrey,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    // Centered user image
                    Container(
                      width: 80,
                      child: Center(
                        child: Image.asset(
                          'assets/images/user.png',
                          width: 40,
                        ),
                      ),
                    ),
                    // User details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(user.email!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          SizedBox(height: 4),
                          Text("Password: ${user.pwd}"),
                          SizedBox(height: 4),
                          Text("Name: ${user.name}"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            hasRequest
                ? Positioned(
                    bottom: 10,
                    right: 10,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      GestureDetector(
                        child: Icon(
                          size: 20,
                          Icons.check,
                          color: Colors.green,
                        ),
                        onTap: () {
                          showNoHeader(
                            txt: 'Are you sure you want to accept this user request ?',
                            icon: Icons.check,
                            btnOkColor: Colors.green,
                            btnOkText: 'Accept',
                          ).then((toAllow) {// if admin accept
                            if (toAllow) {
                              acceptUser(user.id!);
                              getUsersData();//refresh
                            }
                          });
                        },
                      ),
                      SizedBox(width: 17),
                      GestureDetector(
                        child: Icon(
                          size: 20,
                          Icons.close,
                          color: Colors.red,
                        ),
                        onTap: () {
                          showNoHeader(txt: 'Are you sure you want to deny this user request ?').then((toDeny) {
                            if (toDeny) {
                              deleteUser(user.id!);// delete user from firestore
                              getUsersData();//refresh
                              deleteUserFromAuth(user.email, user.pwd);// delete from auth

                            }
                          });
                        },
                      ),
                    ]))
                : Positioned(
                    bottom: 10,
                    right: 10,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      GestureDetector(
                        child: Icon(
                          size: 20,
                          Icons.close,
                          color: Colors.red,
                        ),
                        onTap: () {
                          showNoHeader(txt: 'Are you sure you want to remove this user ?').then((toRemove) {
                            if (toRemove) {
                              deleteUser(user.id!);
                              getUsersData();
                              deleteUserFromAuth(user.email, user.pwd);

                            }
                          });
                        },
                      ),
                      SizedBox(width: 17),
                      GestureDetector(
                        child: Icon(
                          size: 20,
                          Icons.admin_panel_settings,
                          color: Colors.blue,
                        ),
                        onTap: () {
                          showNoHeader(txt: 'Are you sure you want to \nmake this user an admin ?',btnOkText: 'Yes',btnOkColor: Colors.green,icon: Icons.check).then((toMakeAdmin) {
                            if (toMakeAdmin) {
                              makeUserAdmin(user.id!);
                              getUsersData();//refresh
                            }
                          });
                        },
                      ),
                    ]))
          ],
        ),
      ),
    );
  }


}
