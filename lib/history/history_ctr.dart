import 'dart:async';
import 'dart:ffi';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:server_room_new/main.dart';

import '../../models/user.dart';
import '../../my_voids.dart';
import 'package:intl/intl.dart';

import 'history.dart';

class HistoryCtr extends GetxController {


  List gas_history = [];//json value and time
  List<String> gas_times = [];//time
  List<String> gas_values = [];//value

  List noise_history = [];
  List<String> noise_times = [];//time
  List<String> noise_values = [];//value

  List temp_history = [];
  List<String> tem_times = [];//time
  List<String> tem_values = [];//value


  bool loading = true;



  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(milliseconds: 500), () async { //time to start readin history  data

      initHistoryValues();
    });
  }


  // to get history values
  initHistoryValues() async {

     gas_history = [];//json value and time
     gas_times = [];//time
     gas_values = [];//value

     noise_history = [];
     noise_times = [];//time
     noise_values = [];//value

     temp_history = [];
    tem_times = [];//time
    tem_values = [];//value


    loading = true;
    gas_history = await getHistoryData('Vasr/TheRoom/gas'); // path history
    if (gas_history.length > 100) gas_history = gas_history.sublist(gas_history.length - 100);
    gas_values = gas_history.map((map) => map['value'].toDouble().toString() ).toList();
    gas_times = gas_history.map((map) => map['time'].toString() ).toList();
    print('## gas_history<${gas_history.length}>// gas_values<${gas_values}>// gas_times<${gas_times}>');



    temp_history = await getHistoryData('Vasr/TheRoom/temperature');
    if (temp_history.length > 100) temp_history = temp_history.sublist(temp_history.length - 100);
    tem_values = temp_history.map((map) => map['value'].toString() ).toList();
    tem_times = temp_history.map((map) => map['time'].toString() ).toList();
    //
    //
    noise_history = await getHistoryData('Vasr/TheRoom/sound');
    if (noise_history.length > 100) noise_history = noise_history.sublist(noise_history.length - 100);
    noise_values = noise_history.map((map) => map['value'].toString() ).toList();
    noise_times = noise_history.map((map) => map['time'].toString() ).toList();

    loading =false;
    update(['chart']);
    update(['appBar']);
  }


  /// delete history values /////
  deleteFirstValues(int deleteCount,String type) async {
      DatabaseReference gasRef = database!.ref('Vasr/TheRoom/$type');

    await gasRef.limitToFirst(deleteCount).once().then((DatabaseEvent value) {
      if (value.snapshot.exists){
        Map<dynamic, dynamic> gasValues = value.snapshot.value as Map<dynamic, dynamic>;
        List keys = gasValues.keys.toList();
        keys.forEach((key) { // 20 loop
          gasRef.child(key).remove();
        });
      }else{
        print('## failed to delete: values dont exist');
      }
      //print('## vals: $gasValues');

    });
    //     .then((snapshot) {
    //   Map<dynamic, dynamic> gasValues = snapshot.value;
    //   List<String> keys = gasValues.keys.toList();
    //
    //   keys.forEach((key) {
    //     gasRef.child(key).remove();
    //   });
    // });
  }
  Future<void> deleteHisDialog(BuildContext context,String type,List hisList) {
    TextEditingController _textEditingController = TextEditingController();
    final _serverFormKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Values number to delete'),
          content: Form(
            key: _serverFormKey,
            child: TextFormField(
              controller: _textEditingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'number (max: ${hisList.length})',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'number cannot be empty';
                }
                if(int.parse(value)>hisList.length){
                  return 'number is greater than max';
                }
                return null;
              },
            ),
          ),

          actions: [
            ElevatedButton(
              onPressed: () {
                //if(sName.isNotEmpty && servers.contains(sName))
                if(_serverFormKey.currentState!.validate()){
                  int count = int.parse(_textEditingController.text);

                  deleteFirstValues(count,type);
                  Navigator.of(context).pop();
                  Future.delayed(const Duration(milliseconds: 800), () async { //time to start readin history  data
                    initHistoryValues();
                  });                  // Navigator.of(context).pop();
                  // Future.delayed(const Duration(milliseconds: 1000), () async { //time to start readin history  data
                  //
                  //   Get.to(() => HistoryView());
                  // });
                }
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  /// //////////////


  Future<List> getHistoryData(dataTypePath) async {
    List dataHis = [];
    DatabaseReference serverData = database!.ref(dataTypePath);
    //servers = sharedPrefs!.getStringList('servers') ?? ['server1'];

    final snapshot = await serverData.get();

    if (snapshot.exists) {
      snapshot.children.forEach((element) {
        //print('## ele ${element.key}');
        dataHis.add(element.value);
        //print('## type... <${element.value.runtimeType}>');

      });

      print('## <${dataTypePath}> history exists with <${dataHis.length}> values');
    } else {
      print('## <${dataTypePath}> history DONT exists');
    }

    update(['chart']);
    //print('## <<${dataHis.length}>> hisValues=<$dataHis> ');
    return dataHis;
  }
  List<FlSpot> generateHistorySpots(List dataList) {
    //print('## generate spots...');
    // dataList <gas_history>
    List<FlSpot> spots = [];
    for (int i = 0 ; i < dataList.length ; i++) {
      //print('## ${dataList[i]['value']}');
      //bool isLast = i % spots.length == 0;
      spots.add(
          FlSpot(
              i.toDouble(), // X
              double.parse(dataList[i]) // Y
          )
      );
    }

    return spots;
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
