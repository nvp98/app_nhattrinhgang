import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Env singleton dùng chung cho toàn bộ app
abstract class Env {
  static String get baseUrl =>
      dotenv.maybeGet('API_BASE_URL') ?? 'http://localhost:3000';
}

/// Hook để đọc baseUrl
String useBaseUrl() {
  return useMemoized(() => Env.baseUrl, []);
}

/// Hook để đọc token từ secure storage
String? useAccessToken() {
  final storage = useMemoized(() => const FlutterSecureStorage(), []);
  final token = useState<String?>(null);
  useEffect(() {
    Future<void> load() async {
      final t = await storage.read(key: 'access_token');
      token.value = t;
    }

    load();
    return null;
  }, []);
  return token.value;
}

/// Hook để tạo Dio instance với interceptor tự động đính token
Dio useDio({bool enableLog = true}) {
  final baseUrl = useBaseUrl();
  final token = useAccessToken();

  return useMemoized(() {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Content-Type': 'application/json'},
    );
    final dio = Dio(options);

    // Interceptor đính token
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }));

    // Log nếu cần
    if (enableLog) {
      dio.interceptors
          .add(LogInterceptor(requestBody: true, responseBody: true));
    }

    return dio;
  }, [baseUrl, token, enableLog]);
}

/// Hook để tạo ApiClient từ Dio
ApiClient useApiClient({bool enableLog = true}) {
  final dio = useDio(enableLog: enableLog);
  return useMemoized(() => ApiClient(dio), [dio]);
}

class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _dio.get(path, queryParameters: query);
  }

  Future<Response<dynamic>> post(String path,
      {dynamic data, Map<String, dynamic>? query}) {
    return _dio.post(path, data: data, queryParameters: query);
  }

  Future<Response<dynamic>> put(String path,
      {dynamic data, Map<String, dynamic>? query}) {
    return _dio.put(path, data: data, queryParameters: query);
  }

  Future<Response<dynamic>> delete(String path,
      {dynamic data, Map<String, dynamic>? query}) {
    return _dio.delete(path, data: data, queryParameters: query);
  }
}