import 'dart:async';

import 'package:flutter/services.dart';

typedef Future<dynamic> ResponseHandler(Map<String, String> data);

class ApptraceFlutterPlugin {
  final MethodChannel _channel = const MethodChannel('apptrace_flutter_plugin');

  static final ApptraceFlutterPlugin _instance = ApptraceFlutterPlugin._internal();

  ApptraceFlutterPlugin._internal() {
    _channel.setMethodCallHandler(_onMethodHandle);
  }

  factory ApptraceFlutterPlugin.getInstance() => _instance;

  late ResponseHandler _installRespHandler;
  late ResponseHandler _wakeUpRespHandler;

  Future<dynamic> _onMethodHandle(MethodCall call) async {
    if (call.method == "onInstallResponse") {
      return _installRespHandler(call.arguments.cast<String, String>());
    } else if (call.method == "onWakeUpResponse") {
      return _wakeUpRespHandler(call.arguments.cast<String, String>());
    }
  }

  void registerWakeUp(ResponseHandler responseHandler) {
    _wakeUpRespHandler = responseHandler;
    _channel.invokeMethod("registerWakeUp");
  }

  void getInstall(ResponseHandler responseHandler) {
    _installRespHandler = responseHandler;
    _channel.invokeMethod("getInstall");
  }

  void init({bool enableClipboard = true}) {
    var args = new Map<String, bool>();
    args["enableClipboard"] = enableClipboard;

    _channel.invokeMethod("init", args);
  }
}
