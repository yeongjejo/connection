

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:newconnectiontest/info.dart';

class BleConnection {
  var valueStream;
  var scanTime;
  var subscription;

  setScanTime() {
    DateTime now = DateTime.now();
    scanTime = "${now.hour}:${now.minute}:${now.second}";

  }

  setConnectionStateStreem(BluetoothDevice device) {
    subscription = device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.connected) {
        // 1. typically, start a periodic timer that tries to
        //    reconnect, or just call connect() again right now
        // 2. you must always re-discover services after disconnection!
        debugPrint("여기 테스트트ㅡㅌ트 : ${device.platformName}");

        // await r.device.connect();
        await connect(device).then((value) async {
          // r.device.disconnect().then((_) {
          //
          //   tryConnecting[r.device] = false;
          // });
          if (value) {
            debugPrint("컨넥 종료 :  ${device.platformName}");
            await device.disconnect();
            Info.tryConnecting[device] = false;
            Info.tryWrite = false;
          } else {
            debugPrint("컨넥 종료2 :  ${device.platformName}");
            await device.disconnect();
            Info.tryConnecting[device] = false;
            Info.tryWrite = false;
          }

        });
      }
    });
  }


  Future<bool> connect(BluetoothDevice device) async {
    // if (Info.items[device]) {
    //   if (FlutterBluePlus.connectedDevices.first == device) {
    //     device.disconnect();
    //   }
    //   return true;
    // }


    // if (Info.tryConnecting.containsKey(device) && Info.tryConnecting[device]!) {
    //   return Future.value(false);
    // } else {
    //   Info.tryConnecting[device] = true;
    // }
    //
    bool isFail = false;
    //
    // debugPrint("디바이스 네임 : ${FlutterBluePlus.connectedDevices}");
    //
    // if (Info.saveConnectTime.containsKey(device)) {
    //   debugPrint('라스트 시간 확인 : ${DateTime.now().millisecondsSinceEpoch - Info.saveConnectTime[device]}');
    //   debugPrint('네임 확인 : ${device.platformName}');
    //   if (DateTime.now().millisecondsSinceEpoch - Info.saveConnectTime[device] < 1000) {
    //     return Future.value(false);
    //   }
    // }

    // if (FlutterBluePlus.connectedDevices.length > 0) {
    //   for(var connectedDvice in FlutterBluePlus.connectedDevices) {
    //     debugPrint("그래도 여기");
    //     await connectedDvice.disconnect();
    //   }
    // }


    // await device.connect().timeout(const Duration(milliseconds: 2000), onTimeout: () {
    //   debugPrint('Fail BLE Connect');
    //   isFail = true;
    // });
    //
    // if (isFail) {
    //   return Future.value(false);
    // }

    Info.saveConnectTime[device] = DateTime.now().millisecondsSinceEpoch;


    // connecctSubscription = device.connectionState.listen((BluetoothConnectionState state) async{
    //   if(state == BluetoothConnectionState.connected) {
    if(!Info.isScan) {
      return Future.value(false);
    }

    // debugPrint('connect 성공');
    if (device.platformName == "Nordic Beacon 53-2") {
      debugPrint("컨넥 중1111 :  ${device.platformName}");
    }
    late List<BluetoothService> services;

    try {
      services = await device.discoverServices().timeout(const Duration(milliseconds: 1500));
    } catch (e){
      if (device.platformName == "Nordic Beacon 53-2") {
        debugPrint("컨넥 종료22222 :  ${device.platformName}");
      }
      debugPrint('Fail Service Search');
      isFail = true;
    }

    if (isFail) {
      return Future.value(false);
    }


    late BluetoothCharacteristic char1;
    for (var service in services) {
      List<int> listenValue;
      var characteristics = service.characteristics;
      List<String> temp = service.uuid.toString().split("-");
      if (temp[0] == "75c276c3") {
        debugPrint("목표 Service");
      } else {
        continue;
      }
      if (device.platformName == "Nordic Beacon 53-2") {
        debugPrint("컨넥 종료22222 :  ${device.platformName}");
      }

      for (BluetoothCharacteristic c in characteristics) {
        debugPrint('Character 구조 : ${c.toString()}');
        debugPrint('Character UUID : ${c.uuid}');
        if (device.platformName == "Nordic Beacon 53-2") {
          debugPrint("컨넥 종료22222 :  ${device.platformName}");
        }

        List<String> temp2 = c.uuid.toString().split("-");
        debugPrint("temp2[0] : ${temp2[0]}");

        // 6acf4f08 read d3d46a35 wirte용(추정)
        if(temp2[0] == "d3d46a35") {
          await c.setNotifyValue(true);
          await char1.setNotifyValue(true);


          valueStream = c.onValueReceived.listen((value) async {
            //loading은 바로 해제
            debugPrint('!!!!!Value Changed');
            listenValue = value;
            debugPrint('!!!!!Value check : $listenValue');
            debugPrint('!!!!!Value check : ${device.platformName}');

            // await device.disconnect();
            if(listenValue[0].toString() == "17") {
              DateTime now = DateTime.now();
              String formattedTime = "${now.hour}:${now.minute}:${now.second}";
              debugPrint("${device.platformName} 스캔된 시간 : $scanTime");
              debugPrint("${device.platformName} 성공 시간 : $formattedTime");

              Info.items[device] = true;

              Info.writeSuccess = true;
              // return Future.value(true);
              // Info.items[device] = true;
              // device.disconnect();
            }
            //write 실패시 []가 읽혀옴
            //startSuccess 값으로 순서 구분

          });


          debugPrint("Start Write 시작");
          await char1.write([00], withoutResponse: true);
          await Future.delayed(const Duration(milliseconds: 500));
          // if(Info.items[device]) {
          //   return Future.value(true);
          // }


        } else {
          //1일 때는 write용이므로 일단 char1에 저장해두고 read용인 2찾으러가기
          debugPrint("Write Charateristic");
          char1 = c;
        }
      }

    }

    // device.disconnect();

    //   }
    // });

    return Future.value(true);


  }
}