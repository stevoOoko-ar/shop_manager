import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/sale.dart';
import '../screens/reports_screen.dart';
import '../config.dart';
import 'shop_service.dart';

class BackendService implements ShopService {
  final String baseUrl;

  BackendService({required this.baseUrl});

  /// Helper method to make HTTP requests with timeout and error handling.
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final client = http.Client();

    try {
      final request = http.Request(method, uri);
      if (headers != null) {
        request.headers.addAll(headers);
      }
      if (body != null) {
        request.body = body;
      }

      // Log outgoing request
      debugPrint('📤 $method $uri');
      if (body != null) {
        debugPrint('   Body: $body');
      }

      final streamedResponse = await client.send(request).timeout(
            Duration(seconds: httpTimeoutSeconds),
          );

      final response = await http.Response.fromStream(streamedResponse);

      // Log response
      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('   Body: ${response.body}');

      // Check for successful status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Success');
        return response;
      } else {
        // Parse error message if available
        String errorMessage = response.reasonPhrase ?? 'Unknown error';
        try {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorBody['detail'] ?? errorMessage;
        } catch (_) {
          // Use response body if JSON parsing fails
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }

        debugPrint('❌ Error: $errorMessage');

        throw HttpException(
          'HTTP ${response.statusCode}: $errorMessage\n'
          'URL: $uri\n'
          'Method: $method',
        );
      }
    } on SocketException catch (e) {
      debugPrint('❌ Network Error: $e');
      throw Exception('Network error: Unable to connect to backend\n'
          'URL: $uri\n'
          'Please check your internet connection and backend availability.\n'
          'Error: $e');
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout Error: $e');
      throw Exception('Request timeout: Backend took too long to respond\n'
          'URL: $uri\n'
          'Timeout: ${httpTimeoutSeconds}s\n'
          'This may be due to cold start on free tier hosting.\n'
          'Error: $e');
    } catch (e) {
      debugPrint('❌ Unexpected Error: $e');
      throw Exception('Unexpected error during HTTP request\n'
          'URL: $uri\n'
          'Error: $e');
    } finally {
      client.close();
    }
  }

  @override
  Future<void> initDB() async {
    // Backend service doesn't need local DB initialization
    return;
  }

  @override
  Future<List<Product>> getProducts() async {
    final response = await _makeRequest('GET', '/products');
    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .map((item) => Product.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Sale>> getSales() async {
    final response = await _makeRequest('GET', '/sales');
    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .map((item) => Sale.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addProduct(Product product) async {
    debugPrint('📦 Adding product: ${product.id}');
    try {
      final body = jsonEncode(product.toMap());
      debugPrint('   Sending: $body');
      await _makeRequest(
        'POST',
        '/products',
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      debugPrint('✅ Product added successfully');
    } catch (e) {
      debugPrint('❌ Failed to add product: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _makeRequest(
      'PUT',
      '/products/${product.id}',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toMap()),
    );
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _makeRequest('DELETE', '/products/$productId');
  }

  @override
  Future<void> recordSale(Sale sale) async {
    await _makeRequest(
      'POST',
      '/sales',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(sale.toMap()),
    );
  }

  @override
  Future<void> seedProducts(List<Product> products) async {
    for (final product in products) {
      await addProduct(product);
    }
  }

  @override
  Future<List<ReportItem>> getReports(int days) async {
    final response = await _makeRequest('GET', '/reports/daily?days=$days');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final dailyReports = body['dailyReports'] as List<dynamic>;

    return dailyReports.map((item) {
      final itemMap = item as Map<String, dynamic>;
      final date =
          DateTime.fromMillisecondsSinceEpoch((itemMap['date'] as num).toInt());
      return ReportItem(
        date: date,
        sales: (itemMap['sales'] as num).toDouble(),
        profit: (itemMap['profit'] as num).toDouble(),
      );
    }).toList();
  }
}
