import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:io' show Platform;

class ApiClient {
  static const String computerIp = '192.168.246.74'; 

  late final Dio _dio;

  ApiClient() {
    String baseUrl = 'http://localhost:3000/api';
    
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          baseUrl = 'http://$computerIp:3000/api';
        }
      } catch (e) {
        debugPrint('Platform detection error, using default: $e');
      }
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ),
    );
  }

  Dio get dio => _dio;
}
