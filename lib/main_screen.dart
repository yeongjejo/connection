
import 'dart:async';

import 'package:flutter/material.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Toast.dart';
import 'ble_connection.dart';
import 'info.dart';

class MainScreen extends StatefulWidget {

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  StreamSubscription? subscription;
  StreamSubscription? connecctSubscription;
  StreamSubscription? valueStream;

  List<BluetoothDevice> connectingBLE = [];

  Map<BluetoothDevice, int> connectingBLECnt = {};


  Map<BluetoothDevice, int> scanResultCnt = {};

  Map<BluetoothDevice, BleConnection> bleConnectionMap = {};


  bool isConnect = false;




  var coneectTime = DateTime
      .now()
      .millisecondsSinceEpoch;

  String btnName = "Scan Start";

  @override
  void initState() {
    super.initState();

  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Nordic Beacon TEST'),
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // "Scan" 버튼을 눌렀을 때 동작하는 로직
                    if (Info.isScan) {
                      Info.isScan = false;
                      // FlutterBluePlus.stopScan();
                      // for (var i in FlutterBluePlus.connectedDevices) {
                      //   await i.disconnect();
                      // }

                      await FlutterBluePlus.stopScan();
                      await valueStream?.cancel();
                      await subscription?.cancel();

                      Info.isScan = false;
                      setState(() {
                        btnName = "Scan Start";
                        // Info.bleList.clear();
                        // Info.items.clear();
                      });

                      debugPrint("다 끊겼나? : ${FlutterBluePlus.connectedDevices.length}");
                    } else {
                      // Info.bleList.clear();
                      // Info.items.clear();
                      Info.isScan = true;
                      startScan();
                      print('Scanning...');
                      setState(() {
                        btnName = "Scan Stop";
                      });
                    }
                  },
                  child: Text(btnName),
                ),

                ElevatedButton(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('알림'),
                          content: Text('버튼을 눌렀습니다.'),
                          actions: [

                            TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text('취소')),
                            TextButton(
                              onPressed: () {
                                // 다이얼로그 닫기

                                Info.bleList.clear();
                                Info.items.clear();
                                bleConnectionMap = {};

                                setState(() {
                                  // btnName = "Scan Stop";
                                });

                                Navigator.of(context).pop();
                              },
                              child: Text('확인'),
                            ),
                          ],
                        );
                      },
                    );
                    debugPrint("다 끊겼나? : ${FlutterBluePlus.connectedDevices.length}");

                  },
                  child: Text("Reset"),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: Info.items.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Info.bleList.isEmpty ? Text("") : Text(
                        "${Info.bleList[index].platformName} : ${Info.items[Info
                            .bleList[index]].toString()}"),
                    // title: Text("${Info.bleList[index].platformName} : ${Info.items[Info.bleList[index]].toString()}"),
                    // 다양한 다른 위젯을 여기에 추가할 수 있습니다.
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }

  startScan() async {

    DateTime now = DateTime.now();
    String formattedTime = "${now.hour}:${now.minute}:${now.second}";
    // debugPrint("스캠 시작 시간: $formattedTime");
    subscription = FlutterBluePlus.onScanResults.listen((results) async {
      if (results.isNotEmpty) {
        for (var r in results) {

          // await Future.delayed(const Duration(milliseconds: 500));

          if(r.advertisementData.advName.contains("Nordic Beacon") && r.rssi > -80) {
            // debugPrint("스캔된 네임 : ${r.advertisementData.advName}");

            if (r.device.platformName == "Nordic Beacon 53-2") {

              debugPrint("connect55 : ${r.device.platformName}");
            }
            try {
              if(!Info.bleList.contains(r.device)) {
                Info.tryConnecting[r.device] = false;
                Info.bleList.add(r.device);
                Info.items[r.device] = false;
                bleConnectionMap[r.device] = BleConnection();
                bleConnectionMap[r.device]?.setScanTime();
                // bleConnectionMap[r.device]?.setConnectionStateStreem(r.device);
                setState(() {

                });
              }


              // debugPrint("11111111 : ${!r.device.isConnected}");
              // debugPrint("22222222 : ${Info.items.containsKey(r.device)}");
              // debugPrint("33333333 : ${!Info.items[r.device]}");
              // debugPrint("44444444 : ${!Info.tryWrite}");

              if (!r.device.isConnected && Info.items.containsKey(r.device) && !Info.items[r.device] && !Info.tryWrite) {
                // debugPrint("뭐가 찍히나 : ${r.device.platformName}");
                try {
                  await r.device.connect();
                  debugPrint("뭐가 찍히나 : ${r.device.platformName}");
                } catch (e) {
                  await r.device.disconnect();
                  isConnect = false;
                  debugPrint("뭐가 찍히나222 : ${e}");
                }
              }
              // debugPrint("확인용 :");
              // debugPrint("확인용 : ${FlutterBluePlus.connectedDevices.length}");
              // debugPrint("확인용 : ${r.device.connectionState.first}");
              // if(Info.items.containsKey(r.device) && FlutterBluePlus.connectedDevices.isEmpty && !Info.items[r.device]) {


              // await Future.delayed(const Duration(seconds: 2));

              // await Future.delayed(const Duration(milliseconds: 500));

            } catch (e) {
              // await r.device.disconnect();
              debugPrint("Scann! $e");
            }
          }
        }
        if (FlutterBluePlus.connectedDevices.length != 0 && !Info.tryWrite) {
          await test();
          //   // await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
    });

    //스캔 시작
    FlutterBluePlus.startScan(
      //UUID filter 설정
      withServices: [Guid("00003559-0000-1000-8000-00805F9B34FB")],
      //시간초 설정 (4초)
      continuousUpdates: true,
      continuousDivisor: 1,
      // timeout: const Duration(minutes: 10),
      oneByOne: true,
      androidScanMode: AndroidScanMode.lowLatency,
    ).then((_) {
      // timerStop();
      // scanRestart = true;
      // stopListen();
    });

  }

  test() async {
    Info.tryWrite = true;
    // if(Info.items.containsKey(r.device) && !Info.items[r.device] && !r.device.isConnected) {
    debugPrint("컨넥션 수 : ${FlutterBluePlus.connectedDevices.length}");
    // for (var device in FlutterBluePlus.connectedDevices) {
    // var device = FlutterBluePlus.connectedDevices.first;

    // await r.device.connect();
    for (var device in FlutterBluePlus.connectedDevices) {
      if (device.platformName == "Nordic Beacon 53-2") {

        debugPrint("connect 성공44wwww : ${device.platformName}");
      }
      connectingBLECnt[device] = 0;
      scanResultCnt[device] = 0;

      await bleConnectionMap[device]?.connect(device).then((value) async {
        // r.device.disconnect().then((_) {
        //
        //   tryConnecting[r.device] = false;
        // });
        if (value) {

          if (device.platformName == "Nordic Beacon 53-2") {
            debugPrint("컨넥 종료 :  ${device.platformName}");
          }
          await device.disconnect();
          Info.tryConnecting[device] = false;
          // Info.tryWrite = false;
          setState(() {

          });
        } else {
          if (device.platformName == "Nordic Beacon 53-2") {
            debugPrint("컨넥 종료5555222 :  ${device.platformName}");
          }
          Info.tryConnecting[device] = false;
          await device.disconnect();

          debugPrint("컨넥 3333 :  ${device.platformName}");
          // Info.tryConnecting[device] = false;
          // Info.tryWrite = false;
        }

      });
    }

    Info.tryWrite = false;
    debugPrint("----------------------");


    // for(var i in FlutterBluePlus.connectedDevices) {
    //   await i.disconnect();
    // }

    // await Future.delayed(const Duration(milliseconds: 2000));
    // }



  }



}