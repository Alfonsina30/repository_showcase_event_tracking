import 'dart:async';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:focushabit/core/platform/domain/platform_info.dart';
import 'package:focushabit/core/service/connectivity/connectivity_files.dart'
    show ConnectivityDatasource;

class ConnectivityDatasourceImpl extends ConnectivityDatasource {
  //
  final PlatformInfo platformInfo;
  final MethodChannel servicePlatformName;
  final EventChannel eventChannelConnection;
  final http.Client _client;
  final String _baseUrl;

  ConnectivityDatasourceImpl(
      {required this.servicePlatformName,
      required this.eventChannelConnection,
      required this.platformInfo,
      http.Client? client,
      String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? 'https://clients3.google.com/generate_204';

  @override
  Future<bool> hasInternet() async {
    // if app is run on web
    if (platformInfo.isWeb) {
      return true; // El Stream de abajo se encargará de gestionar el estado reactivo real en Web
    } else {
      //
      final hasConnectivity =
          await servicePlatformName.invokeMethod("checkConnection") as bool;

      if (!hasConnectivity) return false;
      //
      final response = await _client
          .get(Uri.parse(_baseUrl)) //'https://clients3.google.com/generate_204'
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 204 || response.statusCode == 200;
    }
  }

  @override
  Stream<bool> get onConnectionStatusChange {
    if (!platformInfo.isWeb) {
      return eventChannelConnection.receiveBroadcastStream().cast<bool>();
    }

    //  secure Stream for Memory Leaks
    Timer? timer;
    late StreamController<bool> controller;

    controller = StreamController<bool>.broadcast(
      onListen: () {
        timer = //-- each 3 seconds emit current state of browser
            Timer.periodic(const Duration(seconds: 3), (timer) async {
          if (controller.isClosed) {
            timer.cancel();
            return;
          }
          //
          try {
            final res = await _client
                .get(Uri.parse(
                    _baseUrl)) //'https://clients3.google.com/generate_204'
                .timeout(const Duration(seconds: 2));
            controller.add(res.statusCode == 204);
          } catch (_) {
            controller.add(false);
          }
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }
}
