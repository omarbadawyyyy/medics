import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymobManager {
  static const String apiKey = "ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRBek1qYzJOaXdpYm1GdFpTSTZJbWx1YVhScFlXd2lmUS5XVElzRGNBQVNWOUdZOElQT3ZtRUJVemxRTnZ0QmwtZVktMkhqUGpJZjBvelRGMHZlSERoenZDalZKTnREYkhyT1lneE16RGpyeVVPOGVZMl9zR3VpQQ==";
  static const String authUrl = "https://accept.paymob.com/api/auth/tokens";
  static const String orderUrl = "https://accept.paymob.com/api/ecommerce/orders";
  static const String paymentKeyUrl = "https://accept.paymob.com/api/acceptance/payment_keys";
  static const String integrationId = "5024366"; // الـ Integration ID الصحيح من حسابك

  Future<String> _getAuthToken() async {
    try {
      final response = await http.post(
        Uri.parse(authUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"api_key": apiKey}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        throw Exception('Failed to get auth token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting auth token: $e');
    }
  }

  Future<int> _registerOrder(String authToken, double amount) async {
    try {
      final response = await http.post(
        Uri.parse(orderUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          "delivery_needed": "false",
          "amount_cents": (amount * 100).toInt(),
          "currency": "EGP",
          "items": [],
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'];
      } else {
        throw Exception('Failed to register order: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error registering order: $e');
    }
  }

  Future<String> getPaymentKey(double amount) async {
    try {
      final authToken = await _getAuthToken();
      final orderId = await _registerOrder(authToken, amount);
      final response = await http.post(
        Uri.parse(paymentKeyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          "amount_cents": (amount * 100).toInt(),
          "currency": "EGP",
          "order_id": orderId.toString(),
          "billing_data": {
            "email": "user@example.com",
            "first_name": "Unknown",
            "last_name": "Unknown",
            "phone_number": "+201234567890",
            "street": "123 Main St",
            "city": "Cairo",
            "country": "EG",
            "state": "Cairo",
            "postal_code": "12345",
            "building": "1",
            "floor": "1",
            "apartment": "1",
          },
          "integration_id": integrationId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        throw Exception('Failed to get payment key: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting payment key: $e');
    }
  }

  // دالة جديدة للحصول على Token البطاقة بعد الدفع الناجح
  Future<String> getCardToken(String paymentKey) async {
    try {
      final authToken = await _getAuthToken();
      final response = await http.post(
        Uri.parse('https://accept.paymob.com/api/acceptance/registrations/card'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'payment_key': paymentKey,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        throw Exception('Failed to get card token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting card token: $e');
    }
  }

  // دالة جديدة لإجراء الدفع باستخدام الـ Token المحفوظ
  Future<bool> payWithToken(String cardToken, double amount) async {
    try {
      final authToken = await _getAuthToken();
      final orderId = await _registerOrder(authToken, amount);
      final response = await http.post(
        Uri.parse('https://accept.paymob.com/api/acceptance/payments/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          "source": {
            "identifier": cardToken,
            "subtype": "TOKEN",
          },
          "amount_cents": (amount * 100).toInt(),
          "currency": "EGP",
          "order_id": orderId.toString(),
          "billing_data": {
            "email": "user@example.com",
            "first_name": "Unknown",
            "last_name": "Unknown",
            "phone_number": "+201234567890",
            "street": "123 Main St",
            "city": "Cairo",
            "country": "EG",
            "state": "Cairo",
            "postal_code": "12345",
            "building": "1",
            "floor": "1",
            "apartment": "1",
          },
          "integration_id": integrationId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to pay with token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error paying with token: $e');
    }
  }
}
