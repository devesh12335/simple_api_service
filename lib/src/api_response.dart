class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return ApiResponse(
      success: json.containsKey('success') ? json['success'] : true, // Default to true if key is missing
      message: json['message'] ?? 'Success',
      data: json.isNotEmpty ? fromJsonT(json) : null, // Pass the whole JSON if no "data" key exists
    );
  }
}
