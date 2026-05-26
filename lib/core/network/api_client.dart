import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:io' show Platform;

class ApiClient {
  // IMPORTANT: If running on a physical Android/iOS device, change this to your 
  // computer's local Wi-Fi IP address (e.g., '192.168.1.5'). Keep it '10.0.2.2' for emulator.
  static const String computerIp = '10.120.232.74'; 

  late final Dio _dio;

  ApiClient() {
    // Default base URL for web and desktop
    String baseUrl = 'http://localhost:3000/api';
    
    // Dynamic override for Android
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          baseUrl = 'http://$computerIp:3000/api';
        }
      } catch (e) {
        // Fallback in case platform check fails
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

    // Setup logging interceptor for debugging network calls
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
