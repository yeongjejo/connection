import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Info {
  static Map<dynamic, dynamic> items = {};
  static Map<dynamic, dynamic> saveConnectTime = {};
  static List<BluetoothDevice> bleList = [];

  static Map<BluetoothDevice, bool> tryConnecting = {};

  static bool isScan = false;

  static bool tryWrite = false;

  static bool writeSuccess = false;


}