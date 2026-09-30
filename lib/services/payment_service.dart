import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/order_record.dart';

class PaymentService {
  static const baseUrl = String.fromEnvironment('PAYMENT_API_BASE_URL');
  static const token = String.fromEnvironment('PAYMENT_API_TOKEN');

  void checkConfiguration() {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasAuthority || token.isEmpty) {
      throw StateError('Online payment is unavailable. Please choose cash on delivery.');
    }
    final localDebug = !kReleaseMode && uri.scheme == 'http' &&
      ['127.0.0.1', 'localhost', '10.0.2.2'].contains(uri.host);
    if (uri.scheme != 'https' && !localDebug) {
      throw StateError('Use HTTPS, or the documented USB debug connection.');
    }
  }

  Future<Map<String, dynamic>> _request(String path, [Map<String, dynamic>? data]) async {
    checkConfiguration();
    final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}$path');
    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
    http.Response response;
    try {
      response = await (data == null ? http.get(uri, headers: headers) :
        http.post(uri, headers: headers, body: jsonEncode(data)))
        .timeout(const Duration(seconds: 40));
    } on TimeoutException {
      throw StateError('Payment server timed out. Your order is saved; retry to check its status.');
    } on http.ClientException {
      throw StateError('Cannot reach the payment server. Check the USB connection and server.');
    }
    Map<String, dynamic> result;
    try { result = jsonDecode(response.body) as Map<String, dynamic>; }
    catch (_) { throw StateError('Invalid response from payment server.'); }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(result['error'] as String? ?? 'Payment request failed.');
    }
    return result;
  }

  Future<Map<String, dynamic>> prepare(OrderRecord order) => _request('/orders', {
    'client_order_id': order.id,
    'items': order.items.map((x) => {'food_id': x.foodId, 'quantity': x.quantity}).toList(),
  });
  Future<Map<String, dynamic>> status(OrderRecord order) =>
    _request('/orders/${order.id}/status');
  Future<Map<String, dynamic>> verify(OrderRecord order) => _request('/verify', {
    'client_order_id': order.id, 'razorpay_order_id': order.razorpayOrderId,
    'razorpay_payment_id': order.paymentId, 'razorpay_signature': order.signature,
  });
}
