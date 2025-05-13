import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
Color primaryCol =Colors.blue.withOpacity(0.6);

SideTitles get topTitles => SideTitles(
  //interval: 1,
  showTitles: true,
  getTitlesWidget: (value, meta) {
    String text = '';
    switch (value.toInt()) {

    }

    return Text(
      text,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11),
    );
  },
);

// SideTitles get leftTitles => SideTitles(
//   interval: 50,
//   showTitles: true,
//   getTitlesWidget: (value, meta) {
//     String text = '';
//     switch (value.toInt()) {
//       case -50:
//         text = '-50';
//         break;
//       case 0:
//         text = '0';
//         break;
//       case 50:
//         text = '50';
//         break;
//       case 100:
//         text = '100';
//         break;
//     }
//
//     return Text(
//       text,
//       maxLines: 1,
//       textAlign: TextAlign.center,
//       style: TextStyle(fontSize: 11),
//     );
//   },
// );


SideTitles get leftTitlesHistory => SideTitles(
  //interval: 50,
  showTitles: true,
  getTitlesWidget: (double value, meta) {


    return Text(
      value.toString(),
      maxLines: 1,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11),
    );
  },
);
backGroundTemplate({Widget? child}){
  return Container(
    //alignment: Alignment.topCenter,
    width: 100.w,
    height: 100.h,
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/images/bg.png"),
        fit: BoxFit.cover,
      ),
    ),
    child: child,
  );
}

SideTitles  bottomTimeTitles(int eachTime, List<String> timeList) { //gas_times
  return SideTitles(
  interval: 1,
  showTitles: true,
  getTitlesWidget: (value, meta) {
    int index = value.toInt(); // 0 , 1 ,2 ...
    String bottomText = '';

    // Check if index is valid and in range
    if (index >= 0 && index < timeList.length) {
      // Show time at every point - no longer using eachTime intervals
      // Get the original timestamp (in DateTime format)
      String originalTime = timeList[index];
      
      // Format to show time as HH:mm
      try {
        DateTime dateTime = DateTime.parse(originalTime);
        // Format as HH:mm
        String hour = dateTime.hour.toString().padLeft(2, '0');
        String minute = dateTime.minute.toString().padLeft(2, '0');
        
        bottomText = "$hour:$minute";
      } catch (e) {
        // Fallback if parsing fails
        bottomText = originalTime.split(' ').last.split(':').take(2).join(':');
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
      bottomText,
      maxLines: 1,
      textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10),
      ),
    );
  },
);
}