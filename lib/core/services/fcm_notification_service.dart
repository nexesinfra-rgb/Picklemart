import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

/// Service for calling the FCM notification Edge Function
class FcmNotificationService {
  static final FcmNotificationService _instance =
      FcmNotificationService._internal();
  factory FcmNotificationService() => _instance;
  FcmNotificationService._internal();

  /// Send FCM notification to admin users via Edge Function
  Future<bool> sendAdminNotification({
    required String type,
    required String title,
    required String message,
    String? orderId,
    String? conversationId,
    String? orderNumber,
    String? userName,
  }) async {
    try {
      final functionUrl =
          '${Environment.supabaseUrl}/functions/v1/send-admin-fcm-notification';

      final payload = {
        'type': type,
        'title': title,
        'message': message,
        if (orderId != null) 'order_id': orderId,
        if (conversationId != null) 'conversation_id': conversationId,
        if (orderNumber != null) 'order_number': orderNumber,
        if (userName != null) 'user_name': userName,
      };

      return _sendNotification(functionUrl, payload);
    } catch (e) {
      if (kDebugMode) {
        print('❌ FcmNotificationService: Error sending admin notification: $e');
      }
      return false;
    }
  }

  /// Send FCM notification to a specific user via Edge Function
  Future<bool> sendUserNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? orderId,
    String? orderNumber,
  }) async {
    try {
      final functionUrl =
          '${Environment.supabaseUrl}/functions/v1/send-user-fcm-notification';

      final payload = {
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        if (orderId != null) 'order_id': orderId,
        if (orderNumber != null) 'order_number': orderNumber,
      };

      return _sendNotification(functionUrl, payload);
    } catch (e) {
      if (kDebugMode) {
        print('❌ FcmNotificationService: Error sending user notification: $e');
      }
      return false;
    }
  }

  Future<bool> _sendNotification(
    String functionUrl,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(functionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${Environment.supabaseAnonKey}',
              'apikey': Environment.supabaseAnonKey,
            },
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          final responseData = json.decode(response.body);
          print('✅ FcmNotificationService: Notification sent successfully');
          print(
            '   Sent: ${responseData['sent']}, Failed: ${responseData['failed']}',
          );
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ FcmNotificationService: Failed to send notification');
          print('   Status: ${response.statusCode}');
          print('   Response: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FcmNotificationService: Error in _sendNotification: $e');
      }
      return false;
    }
  }

  /// Send order status change notification
  Future<bool> sendOrderStatusNotification({
    required String orderId,
    required String orderNumber,
    required String status,
  }) async {
    final statusLabel = _getStatusLabel(status);
    return sendAdminNotification(
      type: 'order_status_changed',
      title: 'Order Status Updated',
      message: 'Order #$orderNumber status changed to: $statusLabel',
      orderId: orderId,
      orderNumber: orderNumber,
    );
  }

  /// Send chat message notification
  Future<bool> sendChatNotification({
    required String conversationId,
    required String userName,
    required String messagePreview,
  }) async {
    return sendAdminNotification(
      type: 'chat_message',
      title: 'New Message from $userName',
      message: messagePreview,
      conversationId: conversationId,
      userName: userName,
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Accepted';
      case 'processing':
        return 'Order Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      case 'out_for_delivery':
        return 'Out for Delivery';
      default:
        return status;
    }
  }
}

/// Provider for FCM notification service
final fcmNotificationServiceProvider = Provider<FcmNotificationService>((ref) {
  return FcmNotificationService();
});
