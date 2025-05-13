import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import '../models/user.dart';
import '../my_ui.dart';
import 'approvedListCtr.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class RequestsList extends StatefulWidget {
  const RequestsList({super.key});

  @override
  State<RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<RequestsList> {
  final UsersCtr gc = Get.find<UsersCtr>();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        backgroundColor: primaryCol,

        title: Text('Users requests'),
      ),
      body: Container(
        // alignment: Alignment.topCenter,
        // width: 100.w,
        // height: 100.h,

        child: GetBuilder<UsersCtr>(
          builder: (ctr) => (gc.userListReq.isNotEmpty)
              ? ListView.builder(
                  //itemExtent: 130,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  shrinkWrap: true,
                  itemCount: gc.userListReq.length,
                  itemBuilder: (BuildContext context, int index) {
                    SrUser user = gc.userListReq[index];
                    return gc.userCard0(user,hasRequest: true);
                  })
              : gc.shouldLoad
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Center(
                      child: Text(
                        'no requests found',
                        style: TextStyle(
                          fontSize: 25,
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
