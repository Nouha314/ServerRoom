#include <WiFi.h>
#include "Time.h"

#include <FirebaseESP32.h>
#include <DHT.h>
#include <NTPClient.h>
#include <WiFiUDP.h>

#define WIFI_SSID "Nounou"
#define WIFI_PASSWORD "nouha2000"

#define FIREBASE_HOST "https://serverroom-2c00f-default-rtdb.europe-west1.firebasedatabase.app/"
#define FIREBASE_AUTH "l54R8kMReXpHgACxipay2zMnQbuXrvyZJFVqUOV1"
//for time
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 0;
const int   daylightOffset_sec = 3600;

#define DHTPIN 4
#define DHTTYPE DHT11

#define MQ2PIN 34

#define KY037PIN 35
WiFiUDP ntpUDP;


NTPClient timeClient(ntpUDP, "pool.ntp.org");
FirebaseJson json;

DHT dht(DHTPIN, DHTTYPE);

FirebaseData firebaseData;
  float temperature ;
  int mq2Value ;
  int ky037Value ;


 void uploadData() {
  // Get the number of records in the database
   if (Firebase.getInt(firebaseData, "/numRecords")) {
    int numRecords = firebaseData.intData();

  // Check if the number of records is greater than MAX_RECORDS
  if (numRecords >= 50) {
    // Calculate the number of records to delete
    int numToDelete = numRecords - 50 + 1;

    // Delete the oldest record(s)
    for (int i = 0; i < numToDelete; i++) {
      // Get the key of the oldest record
           Firebase.deleteNode(firebaseData, "/Vasr/TheRoom/temperature_history");
    }

 for (int i = 0; i < numToDelete; i++) {
      // Get the key of the oldest record
           Firebase.deleteNode(firebaseData, "/Vasr/TheRoom/gas");
    }

 for (int i = 0; i < numToDelete; i++) {
      // Get the key of the oldest record
           Firebase.deleteNode(firebaseData, "/Vasr/TheRoom/sound");
    }
    
  }
  // Update the number of records
  Firebase.setInt(firebaseData, "/numRecords", numRecords + 1);
   }
}
  
   
void setup() {
  Serial.begin(9600);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
 // Init and get the time
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  
  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);

  WiFiUDP ntpUDP;
  NTPClient timeClient(ntpUDP);
  timeClient.begin();

  pinMode(MQ2PIN, INPUT);
  pinMode(KY037PIN, INPUT);

}

 
void loop() {

  
    // Get the current time ///////
    
      struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    Serial.println("Failed to obtain time");
    return;
  }
  char currentTime[9];
  strftime(currentTime, sizeof(currentTime), "%H:%M:%S", &timeinfo);
    Serial.println(currentTime);

    // ////////////////////////////
    
   // Read sensor values
  temperature = dht.readTemperature();
  mq2Value = analogRead(MQ2PIN);
  ky037Value = analogRead(KY037PIN);



  
  uploadData();
  // Send gas data to Firebase
  //if (mq2Value > 400) {
    //Firebase.pushInt(firebaseData, "/gas_alert", mq2Value );
    
  //} else {
    //Firebase.pushInt(firebaseData, "/gas_value", mq2Value);
  //}

    json.clear();
 json.set("value", mq2Value);
  json.set("time", currentTime);

  
    //Serial.printf("Gaz:", mq2Value);
//    Firebase.pushInt(firebaseData, "/Vasr/TheRoom/gas", mq2Value);

 if (Firebase.pushJSON(firebaseData, "/Vasr/TheRoom/gas", json)) {
    Serial.println("Data added successfully");
  } else {
    Serial.println("Data push failed");
    Serial.println(firebaseData.errorReason());
  }
    Firebase.setInt(firebaseData, "/Vasr/TheRoom/gas_once", mq2Value);

    
 json.set("value", temperature);
  json.set("time", currentTime);
  if (Firebase.pushJSON(firebaseData, "/Vasr/TheRoom/temperature", json)) {
    Serial.println("Data added successfully");
  } else {
    Serial.println("Data push failed");
    Serial.println(firebaseData.errorReason());
  }
    Firebase.setInt(firebaseData, "/Vasr/TheRoom/temperature_once", temperature);

    json.set("value", ky037Value);
  json.set("time", currentTime);
  if (Firebase.pushJSON(firebaseData, "/Vasr/TheRoom/sound", json)) {
    Serial.println("Data added successfully");
  } else {
    Serial.println("Data push failed");
    Serial.println(firebaseData.errorReason());
  }
    Firebase.setInt(firebaseData, "/Vasr/TheRoom/sound_once", ky037Value);
  }
