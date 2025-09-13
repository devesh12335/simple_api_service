import 'package:simple_api_service/simple_api_service.dart';

/// A mock user model for demonstration purposes.
class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  @override
  String toString() => 'User(id: $id, name: $name)';
}

// --- EXAMPLE USAGE ---

void main() async {
  print('--- Initializing ApiService ---');
  // Initialize the ApiService singleton with a base URL and an error handler.
  final apiService = ApiService(
    baseUrl: 'https://api.example.com',
    errorHandler: (message, retryCallback) {
      print('Caught an error in the handler: $message');
      print('You could show a dialog here and call retry() on a button press.');
    },
  );

  // Demonstrate using the singleton from another part of the app.
  // This will return the same instance as the one above.
  final anotherApiServiceInstance = ApiService(baseUrl: 'https://another-url.com');
  print('\n--- Singleton Verification ---');
  print('Are the instances the same? ${identical(apiService, anotherApiServiceInstance)}');

  print('\n--- 1. Performing a GET request ---');
  final userResponse = await apiService.get('/users/1', User.fromJson);
  print(userResponse);

  print('\n--- 2. Performing a POST request ---');
  final newUser = {'id': 2, 'name': 'Jane Smith'};
  final postResponse = await apiService.post('/users', newUser, User.fromJson);
  print(postResponse);

  print('\n--- 3. Performing a PUT request ---');
  final updatedUser = {'id': 2, 'name': 'Jane Doe'};
  final putResponse = await apiService.put('/users/2', updatedUser, User.fromJson);
  print(putResponse);

  print('\n--- 4. Performing a PATCH request ---');
  final patchData = {'name': 'Jane'};
  final patchResponse = await apiService.patch('/users/2', patchData, User.fromJson);
  print(patchResponse);

  print('\n--- 5. Performing a DELETE request ---');
  final deleteResponse = await apiService.delete('/users/1', (json) => null);
  print(deleteResponse);

  print('\n--- 6. Demonstrating the Error Handler ---');
  // This call will trigger the mock error and the custom errorHandler callback.
  final errorResponse = await apiService.get('/error-endpoint', (json) => null);
  print(errorResponse);
}
