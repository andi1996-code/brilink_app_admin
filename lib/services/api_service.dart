import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;

  ApiService._internal(this._dio);

  /// Initialize an [ApiService] with a pre-configured [Dio] instance.
  ///
  /// Interceptors (logging, error handling) are attached here so the caller
  /// only needs to provide a properly configured [Dio].
  static ApiService initWithDio(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Basic logging to help debug connectivity / server issues
          print('--> ${options.method.toUpperCase()} ${options.uri}');
          print('Headers: ${options.headers}');
          if (options.data != null) print('Request data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('<-- ${response.statusCode} ${response.requestOptions.uri}');
          print('Response data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          // More helpful error logging
          if (error.type == DioExceptionType.connectionError) {
            print('Connection error when calling: ${error.requestOptions.uri}');
            print('Error: ${error.message}');
          } else if (error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionTimeout) {
            print('Timeout when calling: ${error.requestOptions.uri}');
          } else {
            print('Dio error: ${error.type} - ${error.message}');
          }

          // If running on Android emulator, remind about 10.0.2.2
          try {
            final host = Uri.parse(dio.options.baseUrl).host;
            if (host == '127.0.0.1' || host == 'localhost') {
              print(
                'Note: If you run on Android emulator use 10.0.2.2 instead of localhost',
              );
            }
          } catch (_) {}

          return handler.next(error);
        },
      ),
    );

    return ApiService._internal(dio);
  }

  /// Exposes the underlying Dio instance for advanced usage, mocking, or
  /// tests.
  Dio get dio => _dio;

  /// Set bearer token for authorization header
  void setAuthToken(String? token) {
    if (token == null) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      // rethrow with more context
      print('GET $path failed: ${e.message}');
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      print('POST $path failed: ${e.message}');
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      print('PUT $path failed: ${e.message}');
      rethrow;
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      print('DELETE $path failed: ${e.message}');
      rethrow;
    }
  }

  // Add other methods as needed (patch, etc.)
}
