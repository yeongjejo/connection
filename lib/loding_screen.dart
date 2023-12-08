
import 'dart:async';

import 'package:flutter/material.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Toast.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool isAnd = Platform.isAndroid;

  @override
  void initState() {
    super.initState();

    checkPermission(); // 권한 확인
  }

  // 권한 설정
  Future<void> checkPermission() async {
    bool rejectPermission = false;
    int andVersion = 0;

    // if (Platform.isAndroid) {
    //   AndroidDeviceInfo androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
    //   andVersion = androidDeviceInfo.version.sdkInt;
    // }

    // 위치 정보
    await Permission.location.request();
    await Permission.location.status.isDenied ? rejectPermission = true : "";
    debugPrint('location$rejectPermission');

    await Permission.locationAlways.request();
    debugPrint('locationAlways : ${await Permission.locationAlways.status.isDenied}');
    await Permission.locationAlways.status.isDenied
        ? rejectPermission = true
        : "";
    debugPrint('locationAlways$rejectPermission');

    // // 블루투스
    if (andVersion < 31 || !isAnd) {
      await Permission.bluetooth.request();
      await Permission.bluetooth.status.isDenied
          ? rejectPermission = true
          : "";
      debugPrint('bluetooth$rejectPermission');

    }

    if (andVersion >= 33  || !isAnd) {
      await Permission.notification.request();
      await Permission.notification.status.isDenied
          ? rejectPermission = true
          : "";
    }

    if (isAnd) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothScan.status.isDenied
          ? rejectPermission = true
          : "";
      debugPrint('bluetoothScan$rejectPermission');

      await Permission.bluetoothAdvertise.request();
      await Permission.bluetoothAdvertise.status.isDenied
          ? rejectPermission = true
          : "";
      debugPrint('bluetoothScan$rejectPermission');

      await Permission.bluetoothConnect.request();
      await Permission.bluetoothConnect.status.isDenied
          ? rejectPermission = true
          : "";
      debugPrint('bluetoothConnect$rejectPermission');


      debugPrint('bluetoothConnect : ${await Permission.bluetoothConnect.status}');
      if (await Permission.bluetoothConnect.status.isRestricted) {
        debugPrint('isRestricted Test');
      }

      await Permission.ignoreBatteryOptimizations.request();
      await Permission.ignoreBatteryOptimizations.status.isDenied
          ? rejectPermission = true
          : "";
      debugPrint('ignoreBatteryOptimizations$rejectPermission');

      await Permission.systemAlertWindow.request();
      await Permission.systemAlertWindow.status.isDenied
          ? rejectPermission = true
          : ""; // 다른 앱 위에 표시
      debugPrint('systemAlertWindow$rejectPermission');
    } else {
      //await Permission.criticalAlerts.request();
      // await Permission.criticalAlerts.status.isDenied
      //     ? rejectPermission = true
      //     : ""; // 다른 앱 위에 표시
      // debugPrint('criticalAlerts : $rejectPermission');
    }

    // 권한 설정 여부 확인
    goToMainPage(); // 페이지 이동
    // if (rejectPermission) {
    //   CustomToast().showToast("모든 권한을 (항상)허용 하셔야 됩니다.");
    //   Future.delayed(const Duration(seconds: 2), () {
    //     SystemNavigator.pop();
    //     exit(0);
    //   });
    // } else {
    //
    //   goToMainPage(); // 페이지 이동
    // }
  }

  // 페이지 이동
  void goToMainPage() {
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}