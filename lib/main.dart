
import 'dart:async';

import 'package:flutter/material.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'loding_screen.dart';
import 'main_screen.dart';



void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,


    initialRoute: '/',
    routes: {
      '/main' : (BuildContext context) => MainScreen(),
      '/' : (BuildContext context) => const LoadingScreen(),
    },
  ));
}