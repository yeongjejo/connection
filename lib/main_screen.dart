
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
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


  // Map<BluetoothDevice, List<ScanResultBLE>> scanCloberList = {};

  List<ScanResultBLE> scanCloberList = [];



  bool isConnect = false;

  late Timer duration;
  late Timer serviceTimer;

  bool timerValid = false;
  bool scanDone = false;
  bool searchDone = false;
  bool connecting = false;
  bool isScanning = false;


  BluetoothDevice? maxClober;
  BluetoothDevice? connectingDivce;



  //스캔 결과 list
  List<ScanResult> scanResultList = [];
  Map<String, List> cloberList = {};




  List<BluetoothDevice> testList = [];


  var saerchTime = DateTime.now();

  String btnName = "Scan Start";

  @override
  void initState() {
    super.initState();

  }

  Future<void> onEvent() async {
    try {
      if (!isScanning && !Info.tryWrite) {
        await scan();
      }
      // await Future.delayed(const Duration(microseconds: 100));
      if (scanDone && !Info.tryWrite) {

        // debugPrint("***서치 시도 : ${maxClober}");
        await searchClober();
        // debugPrint("***서치 종료 : ${maxClober}");
      }
      // await Future.delayed(const Duration(microseconds: 100));

      //
      // debugPrint("111111 : ${searchDone}");
      // debugPrint("222222 : ${!Info.tryWrite}");
      // debugPrint("333333 : ${maxClober != null}");

      if (searchDone && !Info.tryWrite && maxClober != null) {
        try {
          // debugPrint("***컨넥 시도 : ${maxClober}");
          // debugPrint("***컨넥 시도 : ${DateTime.now()}");
          await tryConnect().then((value) async {
            if (value) {
              debugPrint("***성공공 : ${maxClober}");
              debugPrint("***성공공 : ${DateTime.now()}");
              setState(() {

              });
            }
            await tryDisconnect();

            debugPrint("***컨넥 종료 : ${DateTime.now()}");
          });
        } catch (e) {
          await tryDisconnect();

          // debugPrint("컨넥 종료2222 $e");   // debugPrint("Connect Error!!!");
          debugPrint("***컨넥 종료2222  : ${DateTime.now()}");   // debugPrint("Connect Error!!!");
        }
      }
    } catch (e) {
      // debugPrint("여기입니다. : $e");
    }



    // await Future.delayed(const Duration(microseconds: 100));
    // if(searchDone && !Info.tryWrite && maxClober != null) {
    //   debugPrint("커넥 시도!!!! : ${maxClober!.platformName}");
    //   connectingDivce = maxClober;
    //   searchDone = false;
    //   Info.tryWrite = true;
    //   bool isFail = false;
    //   try {
    //     await maxClober!
    //         .connect(autoConnect: false)
    //         .timeout(const Duration(milliseconds: 2000), onTimeout: () {
    //       isFail = true;
    //     });
    //     if (!isFail) {
    //       debugPrint("뭐가 찍히나 : ${maxClober!.platformName}");
    //       await test();
    //     }
    //   } catch (e) {
    //     if(maxClober!.isConnected) {
    //       await maxClober!.disconnect();
    //     }
    //     // await maxClober.disconnect();
    //     isConnect = false;
    //     debugPrint("뭐가 찍히나222 : ${e}");
    //   }
    //
    //
    //   if(maxClober!.isConnected) {
    //     await maxClober?.disconnect();
    //   }
    //   debugPrint("커넥 종료 !!!!");
    //
    //   maxClober = null;
    //
    //   timerValid = true;
    //   Info.tryWrite = false;
    //   connectingDivce = null;
    //
    // }

  }

  Future<bool> scan() async {
    scanResultList.clear();
    cloberList.clear();
    isScanning = true;

    AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: "00003559-0000-1000-8000-00805F9B34FA",
      manufacturerId: 117,
      manufacturerData: Uint8List.fromList([...[1], ...[1]]),
    );
    debugPrint("Data 생성, ${advertiseData.manufacturerData}");

    final AdvertiseSettings advertiseSettings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowLatency,
      // txPowerLevel: AdvertiseTxPower.advertiseTxPowerMedium,
      // txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      connectable: true,
      timeout: 5000,
    );

    BluetoothPeripheralState response;
    response = await FlutterBlePeripheral().start(
        advertiseData: advertiseData,
        advertiseSettings: advertiseSettings
    );

    debugPrint("!!!!!!!!response : $response");

    Future<bool>? returnValue;

    // Future.delayed(const Duration(seconds: 1), (){
      // debugPrint("1 Second !!!");
      // timerValid = true;
    // });

    timerValid = true;

    timerStart();

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

    //스캔 결과 (list형태)가 나오면 가져와서 저장
    subscription = FlutterBluePlus.scanResults.listen((results) {
      scanResultList = results;
      if (results.isNotEmpty) {
        for(ScanResult r in scanResultList) {
          if(r.advertisementData.advName.contains("Nordic Beacon") && r.rssi > -80 && r.device.platformName != "Nordic Beacon 41-4") {
          // if(r.advertisementData.advName.contains("Nordic Beacon") && r.rssi > -80 && r.device.platformName != "Nordic Beacon 41-4") {
            try {
              if (!Info.bleList.contains(r.device)) {
                Info.bleList.add(r.device);
                Info.items[r.device] = false;
                // bleConnectionMap[r.device] = BleConnection();
                // bleConnectionMap[r.device]?.setScanTime();
                // bleConnectionMap[r.device]?.setConnectionStateStreem(r.device);
                setState(() {

                });
              }


              // debugPrint("스캔된 클로버 : ${r.device.platformName} ");
              if (Info.items.containsKey(r.device) && !Info.items[r.device]) {

                testList.add(r.device);

                // maxClober = r.device;

                // debugPrint("1111111111 ");
                // if(connectingDivce == null || connectingDivce != r.device) {

                // debugPrint("2222222222 ");
                // // var addData = ScanResultBLE(DateTime.now(), r.rssi);
                // scanCloberList.add(ScanResultBLE(r.device, r.rssi));
                // if (scanCloberList.length > 50) {
                //   scanCloberList.removeAt(0);
                // }
                // scanCloberList[r.device]?[1] = scanCloberList[r.device]![1] + 1;
                // }
              }
              // else if (Info.items.containsKey(r.device) && !Info.items[r.device]) {
              //
              //   // debugPrint("3333333 ");
              //   // if(connectingDivce == null || connectingDivce != r.device) {
              //
              //   debugPrint("44444444 ");
              //   scanCloberList[r.device] = [ScanResultBLE(DateTime.now(), r.rssi)];
              //   // scanCloberList[r.device] = [r.rssi, 1];
              //   // }
              // }

            } catch (e) {
              debugPrint("여기요 : $e");
            }

          }
        }
      }
      //searchClober();
    });

    return Future.value(true);

  }

  Future<bool> searchClober() async {

    // var newMaxClober;
    // var newMaxRssi = -99.0;
    // // Map<BluetoothDevice, List<ScanResultBLE>>  scanCloberListCopy = {};
    //
    // List<ScanResultBLE> scanCloberListCopy = scanCloberList.map((scanResult) => scanResult.copyWith()).toList();
    // // 0 = rssr 1 = count
    // Map<BluetoothDevice, List<int>> data = {};
    // if(scanCloberListCopy.isNotEmpty) {
    //   for(var i in scanCloberListCopy) {
    //     if (data.containsKey(i.device)) {
    //       data[i.device]![0] = data[i.device]![0] + i.rssi;
    //       data[i.device]![0] = data[i.device]![1] + 1;
    //     } else {
    //       data[i.device] = [i.rssi, 1];
    //     }
    //   }
    // }


    //
    // scanCloberList.forEach((device, scanResults) {
    //   // 각각의 ScanResultBLE 리스트를 복사
    //   List<ScanResultBLE> copiedList = scanResults.map((result) => ScanResultBLE.copy(result)).toList();
    //
    //   // BluetoothDevice와 복사된 ScanResultBLE 리스트를 새로운 Map에 추가
    //   scanCloberListCopy[device] = copiedList;
    // });

    // if(scanCloberListCopy.isNotEmpty) {
    //   for (var device in data.keys) {
    //     // debugPrint("device : $device");
    //     if(Info.items.containsKey(device) && Info.items[device]) {
    //       continue;
    //     }
    //     var avgRssi = data[device]![0] / data[device]![1];
    //     if(newMaxRssi < avgRssi) {
    //       newMaxRssi = avgRssi;
    //       newMaxClober = device;
    //     }
    //   }
    //   maxClober = newMaxClober;
    //   if (newMaxClober == null) {
    //     return Future.value(false);
    //   }
    //   searchDone = true;
    //   connectingDivce = maxClober;
    //   // scanCloberList.clear();
    //   scanDone = false;
    //   // scanDone = false;
    // } else {
    //
    //   // debugPrint("isNull");
    // }




    if(testList.isNotEmpty) {
      List<int> deleteList = [];

      for(int i = 0; i < testList.length; i++) {
        if (Info.items[testList[i]]) {
          deleteList.add(i);
        } else {
          debugPrint("****testList : $testList");
          maxClober = testList[i];
          connectingDivce = maxClober;
          deleteList.add(i);

          searchDone = true;
          scanDone = false;

          break;
        }
      }

      if (deleteList.isNotEmpty) {
        for (int i = deleteList.length - 1; i >= 0; i--) {
          testList.removeAt(i);
        }
      }

    }



    return Future.value(true);
  }



  Future<bool> tryConnect() async {
    searchDone = false;
    Info.tryWrite = true;

    Future<bool>? returnValue;
    bool isFail = false;



    debugPrint('*** try connect : ${DateTime.now()}');
    await maxClober?.connect(autoConnect: false).timeout(const Duration(milliseconds: 2000), onTimeout: ()
    {
      debugPrint('***Fail BLE Connect');
      returnValue = Future.value(false);
      isFail = true;
    });


    if (isFail) {
      timerValid = true;
      return returnValue ?? Future.value(false);
    }
    debugPrint('***connect');
    returnValue = Future.value(true);

    //device 내 service 검색
    late List<BluetoothService>? services;
    try {
      services = await maxClober?.discoverServices()
          .timeout(const Duration(milliseconds: 1500));
    } on TimeoutException catch (_) {
      debugPrint('***Fail Service Search');
      returnValue = Future.value(false);
      isFail = true;
    }

    if (isFail) {
      timerValid = true;
      return returnValue ?? Future.value(false);
    }

    late BluetoothCharacteristic char1;
    for (var service in services!) {
      List<int> listenValue;
      var characteristics = service.characteristics;
      List<String> temp = service.uuid.toString().split("-");
      if (temp[0] == "75c276c3") {
        debugPrint("***목표 Service");
      } else {
        continue;
      }

      for (BluetoothCharacteristic c in characteristics) {
        debugPrint('Character 구조 : ${c.toString()}');
        debugPrint('Character UUID : ${c.uuid}');

        List<String> temp2 = c.uuid.toString().split("-");
        debugPrint("***temp2[0] : ${temp2[0]}");

        // 6acf4f08 read d3d46a35 wirte용(추정)
        if(temp2[0] == "d3d46a35") {
          await c.setNotifyValue(true);
          await char1.setNotifyValue(true);


          valueStream = c.onValueReceived.listen((value) async {
            //loading은 바로 해제
            debugPrint('***!!!!!Value Changed');
            listenValue = value;
            debugPrint('***!!!!!Value check : $listenValue');
            debugPrint('***!!!!!Value check : ${maxClober!.platformName}');

            // await device.disconnect();
            if(listenValue[0].toString() == "17") {
              DateTime now = DateTime.now();
              String formattedTime = "${now.hour}:${now.minute}:${now.second}";
              // debugPrint("${maxClober!.platformName} 스캔된 시간 : $scanTime");
              debugPrint("***${maxClober!.platformName} 성공 시간 : $formattedTime");

              Info.items[maxClober!] = true;

              // return Future.value(true);
              // Info.items[device] = true;
              // device.disconnect();
            }
            //write 실패시 []가 읽혀옴
            //startSuccess 값으로 순서 구분

          });


          debugPrint("***Start Write 시작 : ${maxClober!.platformName}");
          await char1.write([00], withoutResponse: true);
          await Future.delayed(const Duration(milliseconds: 500));
          if(!Info.items[maxClober!]) {
            valueStream?.cancel();
            debugPrint("***Start Write를 실패했습니다.");
            timerValid = true;
            return Future.value(false);
          }


          valueStream?.cancel();

        } else {
          //1일 때는 write용이므로 일단 char1에 저장해두고 read용인 2찾으러가기
          debugPrint("***Write Charateristic");
          char1 = c;
        }
      }

    }

    timerValid = true;
    return returnValue ?? Future.value(false);
  }


  //connect된 BLE 끊기
  Future<void> tryDisconnect() async {
    debugPrint("Disconnecting...");
    timerValid = true;
    connectingDivce = null;
    if (Info.tryWrite) {
      Info.tryWrite = false;
      valueStream?.cancel();
      if(maxClober != null && maxClober!.isConnected) {
        await maxClober!.disconnect();
      }
    }
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

                      debugPrint("버튼 클릭");
                      Info.isScan = false;
                      // FlutterBluePlus.stopScan();
                      // for (var i in FlutterBluePlus.connectedDevices) {
                      //   await i.disconnect();
                      // }

                      await FlutterBluePlus.stopScan();
                      await valueStream?.cancel();
                      await subscription?.cancel();
                      serviceTimer.cancel();
                      duration.cancel();
                      isScanning = false;
                      Info.isScan = false;
                      setState(() {
                        btnName = "Scan Start";
                        // Info.bleList.clear();
                        // Info.items.clear();
                      });

                      // debugPrint("다 끊겼나? : ${FlutterBluePlus.connectedDevices.length}");
                    } else {
                      // Info.bleList.clear();
                      // Info.items.clear();
                      Info.isScan = true;
                      serviceTimer =
                          Timer.periodic(const Duration(milliseconds: 500), (timer) {
                            debugPrint("Timer Printasdf");
                            onEvent();
                          });
                      // print('Scanning...');
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

  // startScan() {
  //
  //   serviceTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
  //         debugPrint("Timer Print");
  //         onEvent();
  //       });
  //
  //   Future.delayed(const Duration(seconds: 1), () {
  //     debugPrint("1 Second !!!");
  //     timerValid = true;
  //   });
  //   timerStart();
  //   onEvent();
  //
  //   // debugPrint("스캠 시작 시간: $formattedTime");
  //   subscription = FlutterBluePlus.onScanResults.listen((results) async {
  //     if (results.isNotEmpty) {
  //       for (var r in results) {
  //
  //         // await Future.delayed(const Duration(milliseconds: 500));
  //
  //         if(r.advertisementData.advName.contains("Nordic Beacon") && r.rssi > -80 && r.advertisementData.advName != "Nordic Beacon 41-4") {
  //           debugPrint("스캔된 네임 : ${r.advertisementData.advName}");
  //
  //
  //           try {
  //             if(!Info.bleList.contains(r.device)) {
  //               Info.bleList.add(r.device);
  //               Info.items[r.device] = false;
  //               bleConnectionMap[r.device] = BleConnection();
  //               bleConnectionMap[r.device]?.setScanTime();
  //               // bleConnectionMap[r.device]?.setConnectionStateStreem(r.device);
  //               setState(() {
  //
  //               });
  //             }
  //
  //             if (scanCloberList.containsKey(r.device) && Info.items.containsKey(r.device) && !Info.items[r.device] ) {
  //               if(connectingDivce == null || connectingDivce != r.device) {
  //                 scanCloberList[r.device]?[0] = scanCloberList[r.device]![0] + r.rssi;
  //                 scanCloberList[r.device]?[1] = scanCloberList[r.device]![1] + 1;
  //               }
  //             } else {
  //               scanCloberList[r.device] = [r.rssi, 1];
  //             }
  //
  //
  //             // if (!r.device.isConnected && Info.items.containsKey(r.device) && !Info.items[r.device] && !Info.tryWrite) {
  //             //   // debugPrint("뭐가 찍히나 : ${r.device.platformName}");
  //             //   try {
  //             //     await r.device.connect();
  //             //     debugPrint("뭐가 찍히나 : ${r.device.platformName}");
  //             //   } catch (e) {
  //             //     await r.device.disconnect();
  //             //     isConnect = false;
  //             //     debugPrint("뭐가 찍히나222 : ${e}");
  //             //   }
  //             // }
  //             // debugPrint("확인용 :");
  //             // debugPrint("확인용 : ${FlutterBluePlus.connectedDevices.length}");
  //             // debugPrint("확인용 : ${r.device.connectionState.first}");
  //             // if(Info.items.containsKey(r.device) && FlutterBluePlus.connectedDevices.isEmpty && !Info.items[r.device]) {
  //
  //
  //             // await Future.delayed(const Duration(seconds: 2));
  //
  //             // await Future.delayed(const Duration(milliseconds: 500));
  //
  //           } catch (e) {
  //             // await r.device.disconnect();
  //             debugPrint("Scann! $e");
  //           }
  //         }
  //       }
  //       // if (FlutterBluePlus.connectedDevices.length != 0 && !Info.tryWrite) {
  //       //   await test();
  //       //   //   // await Future.delayed(const Duration(milliseconds: 1000));
  //       // }
  //     }
  //   });
  //
  //   //스캔 시작
  //   FlutterBluePlus.startScan(
  //     //UUID filter 설정
  //     withServices: [Guid("00003559-0000-1000-8000-00805F9B34FB")],
  //     //시간초 설정 (4초)
  //     continuousUpdates: true,
  //     continuousDivisor: 1,
  //     // timeout: const Duration(minutes: 10),
  //     oneByOne: true,
  //     androidScanMode: AndroidScanMode.lowLatency,
  //   ).then((_) {
  //     // timerStop();
  //     // scanRestart = true;
  //     // stopListen();
  //   });
  //
  // }

  void timerStart() {
    duration = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      //if (timerValid && counter > 15) {

      debugPrint("Scan Cut : $timerValid");
      if (timerValid) {
        DateTime nowTime = DateTime.now();
        if (nowTime.millisecondsSinceEpoch-saerchTime.millisecondsSinceEpoch >= 1) {
          // debugPrint("Scan Cut");
          //debugPrint("Scan Length : ${scanResultList.length}");
          timerValid = false;
          scanDone = true;
          saerchTime = nowTime;
        }
      }
    });
  }

  // test() async {
  //   Info.tryWrite = true;
  //   // if(Info.items.containsKey(r.device) && !Info.items[r.device] && !r.device.isConnected) {
  //   debugPrint("컨넥션 수 : ${FlutterBluePlus.connectedDevices.length}");
  //   // for (var device in FlutterBluePlus.connectedDevices) {
  //   // var device = FlutterBluePlus.connectedDevices.first;
  //
  //   // await r.device.connect();
  //   for (var device in FlutterBluePlus.connectedDevices) {
  //
  //     await bleConnectionMap[device]?.connect(device).then((value) async {
  //       // r.device.disconnect().then((_) {
  //       //
  //       //   tryConnecting[r.device] = false;
  //       // });
  //       if (value) {
  //         await device.disconnect();
  //         debugPrint("전송 성공 :  ${device.platformName}");
  //         // Info.tryWrite = false;
  //         setState(() {
  //
  //         });
  //       } else {
  //         await device.disconnect();
  //
  //         debugPrint("컨넥 실패 :  ${device.platformName}");
  //         // Info.tryConnecting[device] = false;
  //         // Info.tryWrite = false;
  //       }
  //
  //     });
  //   }
  //
  //   // Info.tryWrite = false;
  //   debugPrint("----------------------");
  //
  //
  //   // for(var i in FlutterBluePlus.connectedDevices) {
  //   //   await i.disconnect();
  //   // }
  //
  //   // await Future.delayed(const Duration(milliseconds: 2000));
  //   // }
  //
  //
  //
  // }



}
