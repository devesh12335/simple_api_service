import 'package:dio/dio.dart';



class DioClient {
  final Dio _dio;
  String? _authToken;
  Map<String,dynamic>? _customHeader;

  DioClient({String baseUrl = "Baseurl"})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add Authorization header if needed
          if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }

        if(_customHeader != null){
          options.headers.addAll(_customHeader!);
          
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Log response
        print("Response: ${response.statusCode} -> ${response.data}");
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        // Log error globally
        print("Error occurred: ${e.message}");
        return handler.next(e);
      },
    ));
  }

 

  void setAuthToken(String? token) {
    _authToken = token;
  }

   void setCustomHeader(Map<String,dynamic>? header) {
    _customHeader = header;
  }
  Dio get dio => _dio;
}


//Example usage of api service class

// void main() async {
//   const String token = 'your_jwt_token_here';
//   const String baseUrl = 'https://api.example.com';

//   // Create a new ApiService instance with custom DioClient (if not singleton)
//   final apiService = ApiService._internal(baseUrl: baseUrl)
//     .._dioClient.dio.options.headers['Authorization'] = 'Bearer $token';

//   // Example GET request to a protected endpoint
//   final response = await apiService.get<User>(
//     '/user/profile',
//     (json) => User.fromJson(json),
//   );

//   if (response.success) {
//     print('User name: ${response.data?.name}');
//   } else {
//     print('Error: ${response.message}');
//   }
// }
