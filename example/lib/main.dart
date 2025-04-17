import 'package:flutter/material.dart';
import 'dart:async';

import 'package:apptrace_flutter_plugin/apptrace_flutter_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String result = "";
  late ApptraceFlutterPlugin _apptraceFlutterPlugin;

  @override
  void initState() {
    super.initState();

    if (!mounted) return;

    _apptraceFlutterPlugin = ApptraceFlutterPlugin.getInstance();
    _apptraceFlutterPlugin.init(enableClipboard: true);
    _apptraceFlutterPlugin.registerWakeUp(_registerWakeUpHandler);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text('Apptrace Flutter Plugin Demo'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  _apptraceFlutterPlugin.getInstall(_getInstallHandler);
                },
                child: const Text(
                  '获取参数',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 50),
              Text(
                result,
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _getInstallHandler(Map<String, String> data) async {
    setState(() {
      result = "getInstallTrace result:\n\n code = ${data['code']}, msg = ${data['msg']}, paramsData = ${data['paramsData']}";
    });
  }

  Future _registerWakeUpHandler(Map<String, String> data) async {
    setState(() {
      result = "wakeupTrace result:\n\n code = ${data['code']}, msg = ${data['msg']},  paramsData = ${data['paramsData']}";
    });
  }
}
