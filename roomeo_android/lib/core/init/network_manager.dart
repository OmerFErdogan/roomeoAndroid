import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkManager {
  static NetworkManager? _instance;
  static NetworkManager get instance {
    _instance ??= NetworkManager._init();
    return _instance!;
  }

  late final Dio dio;

  NetworkManager._init() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://127.0.0.1:8081/api',
        contentType: 'application/json',
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SharedPreferences.getInstance().then(
            (prefs) => prefs.getString('token'),
          );

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            SharedPreferences.getInstance().then(
              (prefs) => prefs.remove('token'),
            );
          }
          return handler.next(error);
        },
      ),
    );
  }
}
