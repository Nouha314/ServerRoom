import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:server_room_new/admin/requestsList.dart';

import '../models/user.dart';
import '../my_ui.dart';
import 'approvedListCtr.dart';

class ApprovedListView extends StatefulWidget {
  @override
  State<ApprovedListView> createState() => _ApprovedListViewState();
}

class _ApprovedListViewState extends State<ApprovedListView> {
  final UsersCtr gc = Get.put<UsersCtr>(UsersCtr());

  searchAppBar() {
    return AppBar(
      backgroundColor: primaryCol,
      toolbarHeight: 60.0,
      title: GetBuilder<UsersCtr>(
          //id: 'appBar',
          builder: (_) {
        return gc.typing
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 0.0),
                child: SizedBox(
                  height: 40,
                  child: Container(
                      //margin: EdgeInsets.symmetric(vertical: 50),
                      decoration: BoxDecoration(
                        color: primaryCol,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      //margin: EdgeInsets.all(20.0),
                      //alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 0.0),

                        ///TextFormField
                        child: TextFormField(
                          autocorrect: true,
                          cursorColor: Colors.white54,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                          textAlign: TextAlign.start,
                          controller: gc.typeAheadController,
                          autofocus: true,
                          onChanged: (input) {
                            gc.runFilterList(input);
                          },
                          decoration: InputDecoration(
                            //filled: true,

                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                           // fillColor: Colors.green,
                            hintStyle: const TextStyle(
                              color: Colors.white60,
                            ),

                            hintText: 'search for user'.tr,

                            contentPadding: EdgeInsets.only(
                                right: 10.0, left: 10.0, bottom: 10),
                          ),
                        ),
                      )),
                ),
              )
            : Text('Users List');
      }),
      actions: <Widget>[
        GetBuilder<UsersCtr>(
            //id: 'appBar',
            builder: (_) {
          return !gc.typing
              ? IconButton(
                  padding: EdgeInsets.only(right: 15.0),
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    gc.appBarTyping(true);
                  },
                )
              : IconButton(
                  padding: EdgeInsets.only(right: 15.0),
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    gc.clearSelectedProduct();
                    setState(() {});
                  },
                );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: searchAppBar(),
      body: Container(
        //alignment: Alignment.topCenter,

        // width: 100.w,
        // height: 100.h,
        child: GetBuilder<UsersCtr>(
          builder: (_) {
            return (gc.foundUsersList.isNotEmpty)
              ? ListView.builder(
                  scrollDirection: Axis.vertical,

                  //shrinkWrap: true,
                  physics: ScrollPhysics(),
                  //itemExtent: 130,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
                  //shrinkWrap: true,
                  itemCount: gc.foundUsersList.length,
                  itemBuilder: (BuildContext context, int index) {
                    SrUser user = gc.foundUsersList[index];
                    //String key = gc.foundUsersMap.keys.elementAt(index);
                    //return gc.userCard(gc.foundUsersList[index]);
                    return gc.userCard0(user,hasRequest: false);
                  })
              : gc.shouldLoad
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Center(
                      child: Text(
                        'no users found',
                        style: TextStyle(
                          fontSize: 25,
                        ),
                      ),
                    );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
        child: FittedBox(
          child: FloatingActionButton.extended(
            onPressed: () {
              Get.to(() => RequestsList());
            },
            heroTag: '.Requests',
            backgroundColor: primaryCol,
            label: Text('Requests',style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
