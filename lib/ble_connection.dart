

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:newconnectiontest/info.dart';

class ScanResultBLE {
  var device;
  int rssi;

  ScanResultBLE(this.device, this.rssi);
  // 복사 생성자
  ScanResultBLE copyWith({var device, var rssi}) {
    return ScanResultBLE(
        device ?? this.device,
        rssi ?? this.rssi
    );
  }
}