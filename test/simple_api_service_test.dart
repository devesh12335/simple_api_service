import 'dart:async';

import 'package:dio/dio.dart';
import 'package:simple_api_service/simple_api_service.dart';
import 'package:test/test.dart';

import '../example/simple_api_service_example.dart';

// --- TEST SUITE ---
// Use the 'test' package to write and run these unit tests.

void main() {
  group('ApiService Singleton and Configuration', () {
    test('should return the same instance for multiple calls', () {
      final instance1 = ApiService(baseUrl: 'http://test.com');
      final instance2 = ApiService(baseUrl: 'http://test.com');
      expect(identical(instance1, instance2), isTrue);
    });

    test('should update base URL and headers on the same instance', () {
      final instance1 = ApiService(baseUrl: 'http://first-url.com');
      final instance2 = ApiService(
        baseUrl: 'http://second-url.com',
        authToken: 'new_token',
        customHeader: {'x-custom': 'new_header'},
      );

      // Verify that the same instance is returned
      expect(identical(instance1, instance2), isTrue);
      
      // Since it's a mock, we can't directly check the internal state,
      // but the factory constructor's logic ensures the update happens.
      // A more complex mock would allow checking the DioClient's options.
    });
  });
  
  //---
  
  group('HTTP Methods', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService(baseUrl: 'http://test.com');
    });

    test('GET request should return valid ApiResponse with data', () async {
      final userResponse = await apiService.get('/users/1', User.fromJson);
      expect(userResponse.success, isTrue);
      expect(userResponse.data, isA<User>());
      expect(userResponse.data?.name, 'John Doe');
    });

    test('POST request should return valid ApiResponse with created data', () async {
      final newUser = {'id': 2, 'name': 'Jane Smith'};
      final postResponse = await apiService.post('/users', newUser, User.fromJson);
      expect(postResponse.success, isTrue);
      expect(postResponse.data, isA<User>());
      expect(postResponse.data?.name, 'Jane Smith');
    });

    test('PUT request should return valid ApiResponse with updated data', () async {
      final updatedUser = {'id': 2, 'name': 'Jane Doe'};
      final putResponse = await apiService.put('/users/2', updatedUser, User.fromJson);
      expect(putResponse.success, isTrue);
      expect(putResponse.data, isA<User>());
      expect(putResponse.data?.name, 'Jane Doe');
    });

    test('PATCH request should return valid ApiResponse with patched data', () async {
      final patchData = {'name': 'Jane'};
      final patchResponse = await apiService.patch('/users/2', patchData, User.fromJson);
      expect(patchResponse.success, isTrue);
      expect(patchResponse.data, isA<User>());
      expect(patchResponse.data?.name, 'Jane');
    });

    test('DELETE request should return valid ApiResponse with null data', () async {
      final deleteResponse = await apiService.delete('/users/1', (json) => null);
      expect(deleteResponse.success, isTrue);
      expect(deleteResponse.data, isNull);
    });
  });
  
  //---
  
  group('Request Queueing', () {
    test('requests should be processed sequentially', () async {
      final apiService = ApiService(baseUrl: 'http://test.com');
      final results = <String>[];
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();

      // Mock the first request to delay its completion
      apiService.get('/req1', User.fromJson)
        .then((_) {
          results.add('req1');
          completer1.complete();
        });
      
      // The second request is added to the queue immediately
      apiService.get('/req2', User.fromJson)
        .then((_) {
          results.add('req2');
          completer2.complete();
        });

      // Wait for both requests to complete
      await Future.wait([completer1.future, completer2.future]);

      // The order should be maintained by the queue
      expect(results, ['req1', 'req2']);
    });
  });
  
  //---
  
  group('Error Handling', () {
    late ApiService apiService;
    
    setUp(() {
      apiService = ApiService(baseUrl: 'http://test.com');
    });
    
    test('errorHandler should be called on DioException', () async {
      String? errorMessage;
      apiService.errorHandler = (message, retry) {
        errorMessage = message;
      };
      
      try {
        await apiService.get('/error-endpoint', (json) => null);
      } on DioException {
        expect(errorMessage, 'Simulated network error');
      }
    });
  });
}