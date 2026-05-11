import 'dart:convert';
import 'dart:developer' as dev;

import 'package:d_table_erp_app/config/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  late final Dio dio;
  int _currentBaseUrlIndex = 0;

  String get currentBaseUrl => ApiConstants.baseUrls[_currentBaseUrlIndex];

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: currentBaseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.requestTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = currentBaseUrl;

          final token = Hive.box('settingsBox').get('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          print(
            "🚀 SENDING REQUEST: [${options.method}] "
            "${options.baseUrl}${options.path}",
          );

          if (options.data != null) {
            if (options.data is FormData) {
              print("📦 PAYLOAD: [FormData / multipart upload]");
            } else {
              try {
                print("📦 PAYLOAD: ${jsonEncode(options.data)}");
              } catch (_) {
                print("📦 PAYLOAD: [non-serializable data]");
              }
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            "✅ RESPONSE RECEIVED: [${response.statusCode}] "
            "${response.requestOptions.baseUrl}${response.requestOptions.path}",
          );
          dev.log("📄 DATA: ${jsonEncode(response.data)}");
          return handler.next(response);
        },
        onError: (err, handler) async {
          final handled = await _tryFallbackRequest(err, handler);
          if (handled) {
            return;
          }

          print(
            "❌ API ERROR: [${err.response?.statusCode}] "
            "${err.requestOptions.baseUrl}${err.requestOptions.path}",
          );
          print("⚠️ MESSAGE: ${_extractErrorMessage(err)}");

          if (err.response?.statusCode == 401) {
            Hive.box('settingsBox').clear();
          }

          return handler.next(err);
        },
      ),
    );
  }

  bool _isRetryableNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown;
  }

  String _extractErrorMessage(DioException err) {
    final data = err.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return err.message ?? 'Unexpected network error';
  }

  Future<bool> _tryFallbackRequest(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (!_isRetryableNetworkError(err) || options.data is FormData) {
      return false;
    }

    final triedBaseUrls = List<String>.from(
      options.extra['tried_base_urls'] as List? ?? <String>[options.baseUrl],
    );

    for (final baseUrl in ApiConstants.baseUrls) {
      if (triedBaseUrls.contains(baseUrl)) {
        continue;
      }

      print("🔁 RETRYING WITH FALLBACK BASE URL: $baseUrl");

      final retryOptions = options.copyWith(
        baseUrl: baseUrl,
        extra: {
          ...options.extra,
          'tried_base_urls': [...triedBaseUrls, baseUrl],
        },
      );

      try {
        final response = await dio.fetch<dynamic>(retryOptions);
        _currentBaseUrlIndex = ApiConstants.baseUrls.indexOf(baseUrl);
        dio.options.baseUrl = currentBaseUrl;
        print("✅ FALLBACK SUCCESS. ACTIVE BASE URL: $currentBaseUrl");
        handler.resolve(response);
        return true;
      } on DioException catch (retryErr) {
        if (!_isRetryableNetworkError(retryErr)) {
          handler.next(retryErr);
          return true;
        }
      }
    }

    return false;
  }

  factory DioClient() => _instance;
}
