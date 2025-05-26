import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:server_room_new/history/history_ctr.dart';
import 'package:server_room_new/home_page/home_page_ctr.dart';
import 'package:intl/intl.dart';

import '../my_ui.dart';
import '../my_voids.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final HistoryCtr gc = Get.put<HistoryCtr>(HistoryCtr());
  final HomePageCtr gcc = Get.put<HomePageCtr>(HomePageCtr());
  int eachTimeHis = 7;

  Widget chartGraph(dataName, dataList, timeList, valList, minVal, maxVal, wid) {
    String min = getMinValue(valList).toString();
    String max = getMaxValue(valList).toString();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${dataName} ', textAlign: TextAlign.left, style: TextStyle(fontSize: 22)),
              Text('(min:$min, max:$max)', textAlign: TextAlign.left, style: TextStyle(fontSize: 15, color: Colors.black54)),
              if(gcc.selectedServer  =='TheRoom') TextButton(
                onPressed: () async {
                  await gc.deleteHisDialog(context, dataName, dataList);  // shoiw delete dialog
                },
                child: Text('reduce'),
              )
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            height: 33.h,
            width: 100.h * wid,
            //SingleChildScrollView / scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.only(left: 5.0, right: 8.0),
              child: Container(
                color: Colors.grey[200],
                //width: MediaQuery.of(context).size.width /1.02,
                //height: MediaQuery.of(context).size.height / 3,
                child: LineChart(


                  LineChartData(
                    clipData: FlClipData.all(),
                    // no overflow
                    lineTouchData: LineTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {},
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.blue,
                          tooltipRoundedRadius: 20.0,

                          showOnTopOfTheChartBoxArea: false,
                          //true
                          fitInsideHorizontally: true,
                          tooltipMargin: 50,
                          tooltipHorizontalOffset: 20,
                          fitInsideVertically: true,
                          tooltipPadding: EdgeInsets.all(8.0),
                          //maxContentWidth: 40,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map(
                              (LineBarSpot touchedSpot) {
                                //gc.changeGazTappedValue(gc.dataPoints[touchedSpot.spotIndex].toString());
                                const textStyle = TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                );
                                return LineTooltipItem(
                                  formatNumberAfterComma('${dataList[touchedSpot.spotIndex]}'),
                                  textStyle,
                                );
                              },
                            ).toList();
                          },
                        ),
                        getTouchedSpotIndicator: (LineChartBarData barData, List<int> indicators) {
                          return indicators.map(
                            (int index) {
                              final line = FlLine(color: Colors.blue, strokeWidth: 2, dashArray: [2, 5]);
                              return TouchedSpotIndicatorData(
                                line,
                                FlDotData(show: false),
                              );
                            },
                          ).toList();
                        },
                        getTouchLineEnd: (_, __) => double.infinity),
                    baselineY: 0,
                    minY: minVal,
                    maxY: maxVal,

                    ///rangeAnnotations
                    rangeAnnotations: RangeAnnotations(
                        // verticalRangeAnnotations:[
                        //   VerticalRangeAnnotation(x1: 1,x2: 2),
                        //   VerticalRangeAnnotation(x1: 3,x2: 4)
                        // ],
                        horizontalRangeAnnotations: [
                          //HorizontalRangeAnnotation(y1: 89,y2: 90,color: Colors.redAccent),
                          // HorizontalRangeAnnotation(y1: 3,y2: 4),
                          // HorizontalRangeAnnotation(y1: 5,y2: 6),
                        ]),

                    backgroundColor: Colors.white10,// color bg
                    borderData: FlBorderData(
                        border: const Border(
                      bottom: BorderSide(),
                      left: BorderSide(),
                      top: BorderSide(),
                      //right: BorderSide(),
                    )),
                    gridData: FlGridData(show: false, horizontalInterval: 50, verticalInterval: 1),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(sideTitles: bottomTimeTitles(eachTimeHis, timeList)), // time line
                      leftTitles: AxisTitles(sideTitles: leftTitlesHistory), // values line
                      topTitles: AxisTitles(sideTitles: topTitles),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        ///fill
                        // belowBarData: BarAreaData(
                        //     color: Colors.blue,
                        //     //cutOffY: 0,
                        //     //ap aplyCutOffY: true,
                        //     spotsLine: BarAreaSpotsLine(
                        //       show: true,
                        //     ),
                        //     show: true
                        // ),
                        dotData: FlDotData(
                          show: false,
                        ),
                        show: true,
                        preventCurveOverShooting: false,
                        //showingIndicators:[0,5,6],
                        isCurved: true,
                        isStepLineChart: false,
                        isStrokeCapRound: false,
                        isStrokeJoinRound: false,

                        barWidth: 3.0,
                        curveSmoothness: 0.02,
                        preventCurveOvershootingThreshold: 10.0,
                        lineChartStepData: LineChartStepData(stepDirection: 0),
                        //shadow: Shadow(color: Colors.blue,offset: Offset(0,8)),
                        color: Colors.blue,
                        //spots: points.map((point) => FlSpot(point.x, point.y)).toList(),

                        spots: gc.generateHistorySpots(valList),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryCol,
        title:  Text('History'),
        actions: <Widget>[
          // IconButton(
          //   padding: EdgeInsets.only(left: 0.0),
          //   icon: const Icon(Icons.add),
          //   onPressed: () {
          //     gcc.addServer(context);
          //     //sharedPrefs!.clear();
          //   },
          // ),
        if(false)  GetBuilder<HomePageCtr>(
              id:'appBar',
              builder: (_) {
                return Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: DropdownButton<String>(
                    icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                    underline: Container(),
                    dropdownColor: Colors.blue,
                    value: gcc.selectedServer,
                    items: gcc.servers.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child:  Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              value,
                              style: TextStyle(color: Colors.white),
                            ),
                            if(gcc.selectedServer != value) GestureDetector(
                              child: Icon(
                                size: 20,
                                Icons.close,
                                color: Colors.red,
                              ),
                              onTap: () {
                                showNoHeader(txt: 'Are you sure you want to remove this server ?').then((toRemove) {
                                  if (toRemove) {
                                    gcc.removeServer('$value');
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      //print('## select $newValue');

                      gcc.changeServer(newValue);

                    },
                  ),
                );
              }
          ),
        ],
      ),

      body: GetBuilder<HomePageCtr>(
          id: 'chart',
          builder: (_) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: (!gc.loading)
                  ? SingleChildScrollView(
                      child: Column(
                        //shrinkWrap: true,
                        //mainAxisAlignment: MainAxisAlignment.end,
                        children: [


                          /// GAS chart
                           (gc.gas_history.isNotEmpty)?
                            chartGraph(
                              'gas',
                              gc.gas_history, // list { 'time':25, 'value':147 }
                              gc.gas_times,//list [25,26 ..]
                              gcc.selectedServer  =='TheRoom'? gc.gas_values :List<String>.generate(
                                gc.gas_history.length,
                                    (i) => '0',
                              ),//list [147,144 ..]
                              gcc.selectedServer  =='TheRoom'? replaceWithClosestHalf(getMinValue(gc.gas_values) - 200.0):20.0,
                              gcc.selectedServer  =='TheRoom'? replaceWithClosestHalf(getMaxValue(gc.gas_values) + 200.0):-20.0,
                              gc.gas_history.length / 50 < 1.0 ? 1.0 : gc.gas_history.length / 50,
                            ):Center(
                             child: Text(
                               'no gas history saved yet',
                               style: TextStyle(
                                 color: Colors.grey,
                                 fontSize: 22,
                               ),
                             ),
                           ),

                          /// temperature chart
                          SizedBox(height: 20),
                          (gc.temp_history.isNotEmpty)?
                            chartGraph(
                              'temperature',
                              gc.temp_history,
                              gc.tem_times,
                              gcc.selectedServer  =='TheRoom'? gc.tem_values :List<String>.generate(
                                gc.temp_history.length,
                                    (i) => '0',
                              ),//list [147,144 ..]
                              gcc.selectedServer  =='TheRoom'? replaceWithClosestHalf(getMinValue(gc.tem_values) - 1.0):20.0,
                              gcc.selectedServer  =='TheRoom'? replaceWithClosestHalf(getMaxValue(gc.tem_values) + 1.0):-20.0,
                              gc.temp_history.length / 50 < 1.0 ? 1.0 : gc.temp_history.length / 50,
                            ):Center(
                            child: Text(
                              'no temp history saved yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 22,
                              ),
                            ),
                          ),

                          /// noise chart
                          SizedBox(height: 20),
                          (gc.noise_history.isNotEmpty)?
                            chartGraph(
                              'sound',
                              gc.noise_history,
                              gc.noise_times,
                              gcc.selectedServer  =='TheRoom'? gc.noise_values :List<String>.generate(
                                gc.noise_history.length,
                                    (i) => '0',
                              ),//list [147,144 ..]
                              gcc.selectedServer  =='TheRoom'? replaceWithClosestHalf(getMinValue(gc.noise_values) - 200.0):20.0,
                              gcc.selectedServer  =='TheRoom'? replaceWithClosestHalf(getMaxValue(gc.noise_values) + 200.0):-20.0,

                              // double.parse(getMinValue(gc.noise_values))-2.0,
                              // double.parse(getMaxValue(gc.noise_values))+2.0,
                              gc.noise_history.length / 50 < 1.0 ? 1.0 : gc.noise_history.length / 50,
                            ):Center(
                            child: Text(
                              'no sound history saved yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          SizedBox(height: 20)
                        ],
                      ),
                    )
                  : Center(
                      child: CircularProgressIndicator(),
                    ),
            );
          }),
      // floatingActionButton: ElevatedButton.icon(
      //   onPressed: () {
      //     setState(() {
      //       _isRunning = !_isRunning;
      //       if(!_isRunning){
      //         gc.realTimeListen();
      //       }
      //     });
      //   },
      //
      //   icon: _isRunning ? Icon(Icons.stop,color:  Colors.red,) : Icon(Icons.play_arrow,color: Colors.green,),
      //   label: Text(_isRunning ? 'Stop' : 'Start'),
      //   //textColor: Colors.white,
      // )
    );
  }
}

SideTitles bottomTimeTitles(int interval, List<String> timeList) {
  return SideTitles(
    showTitles: true,
    interval: 1,
    getTitlesWidget: (value, meta) {
      int index = value.toInt();
      if (index < 0 || index >= timeList.length) return Container();
      // Show only every Nth label to avoid overlap
      int showEvery = (timeList.length / 10).ceil();
      if (index % showEvery != 0 && index != timeList.length - 1) return Container();
      String timeStr = timeList[index];
      // Format time string if needed (e.g., HH:mm:ss)
      String label = timeStr.length > 8 ? timeStr.substring(11, 19) : timeStr;
      return Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.black),
        ),
      );
    },
  );
}
