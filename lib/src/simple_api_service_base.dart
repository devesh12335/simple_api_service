import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:simple_api_service/src/api_response.dart';

import 'dio_client.dart';

typedef ErrorHandler = void Function(String message, Function retryCallback);

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final DioClient _dioClient;
  final Queue<Future Function()> _requestQueue = Queue();
  bool _isProcessing = false;
  ErrorHandler? errorHandler;

  factory ApiService({
    required String baseUrl,
    String? authToken,
    Map<String, dynamic>? customHeader,
    ErrorHandler? errorHandler,
  }) {
    if (_instance._dioClient.dio.options.baseUrl != baseUrl) {
      _instance._dioClient.dio.options.baseUrl = baseUrl;
    }
    if (authToken != null) {
      _instance._dioClient.setAuthToken(authToken);
    }
    if (customHeader != null) {
      _instance._dioClient.setCustomHeader(customHeader);
    }
    if (errorHandler != null) {
      _instance.errorHandler = errorHandler;
    }
    return _instance;
  }

  ApiService._internal({String baseUrl = "BaseURL"})
    : _dioClient = DioClient(baseUrl: baseUrl);

  Future<ApiResponse<T>> _enqueueRequest<T>(
    String method,
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? data,
  }) async {
    final completer = Completer<ApiResponse<T>>();

    _requestQueue.add(() async {
      try {
        final response = await _executeRequest<T>(
          method,
          endpoint,
          fromJson,
          queryParams,
          data,
        );
        completer.complete(response);
      } catch (e) {
        completer.completeError(e);
      }
    });

    if (!_isProcessing) {
      _processQueue();
    }

    return completer.future;
  }

  void _processQueue() {
    if (_requestQueue.isNotEmpty) {
      _isProcessing = true;
      _requestQueue
          .removeFirst()()
          .then((_) {
            _processQueue();
          })
          .catchError((_) {
            _processQueue();
          });
    } else {
      _isProcessing = false;
    }
  }

  Future<ApiResponse<T>> _executeRequest<T>(
    String method,
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? data,
  ) async {
    try {
      Response response;
      switch (method) {
        case 'GET':
          response = await _dioClient.dio.get(
            endpoint,
            queryParameters: queryParams,
          );
          break;
        case 'POST':
          response = await _dioClient.dio.post(
            endpoint,
            data: data,
            queryParameters: queryParams,
          );
          break;
        case 'PUT':
          response = await _dioClient.dio.put(
            endpoint,
            data: data,
            queryParameters: queryParams,
          );
          break;
        case 'PATCH':
          response = await _dioClient.dio.patch(
            endpoint,
            data: data,
            queryParameters: queryParams,
          );
          break;
        case 'DELETE':
          response = await _dioClient.dio.delete(
            endpoint,
            queryParameters: queryParams,
          );
          break;
        default:
          throw Exception("Invalid HTTP method: $method");
      }

      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  ApiResponse<T> _handleError<T>(DioException e) {
    String errorMessage = e.message ?? "Unexpected error";
    if (errorHandler != null) {
      errorHandler!(errorMessage, () => _processQueue()); // Retry
    } else {
      print("[ApiService Error] $errorMessage");
    }
    return ApiResponse(success: false, message: errorMessage);
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
  }) => _enqueueRequest<T>('GET', endpoint, fromJson, queryParams: queryParams);

  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
  }) => _enqueueRequest<T>(
    'POST',
    endpoint,
    fromJson,
    data: data,
    queryParams: queryParams,
  );

  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
  }) => _enqueueRequest<T>(
    'PUT',
    endpoint,
    fromJson,
    data: data,
    queryParams: queryParams,
  );

  Future<ApiResponse<T>> patch<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
  }) => _enqueueRequest<T>(
    'PATCH',
    endpoint,
    fromJson,
    data: data,
    queryParams: queryParams,
  );

  Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
  }) => _enqueueRequest<T>(
    'DELETE',
    endpoint,
    fromJson,
    queryParams: queryParams,
  );
}
