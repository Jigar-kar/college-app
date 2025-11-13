import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformPaymentHandler {
  final Razorpay _razorpay = Razorpay();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PlatformPaymentHandler() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> startPayment({
    required String key,
    required double amount,
    required String name,
    required String description,
    required Map<String, String> prefill,
    required Map<String, String> notes,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) async {
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;
    final options = {
      'key': key,
      'amount': (amount * 100).toInt(),
      'name': name,
      'description': description,
      'prefill': prefill,
      'notes': notes,
      'theme': {
        'color': '#1A237E',
      }
    };

    if (kIsWeb) {
      await _handleWebPayment(options);
    } else {
      try {
        if (!options.containsKey('key') || options['key'].toString().isEmpty) {
          throw PaymentFailureResponse(400, 'Authentication failed', {'code': 'BAD_REQUEST_ERROR'});
        }
        _razorpay.open(options);
      } catch (e) {
        if (e is PaymentFailureResponse) {
          onError(e);
        } else {
          onError(PaymentFailureResponse(
            500,
            'Payment processing failed',
            {'code': 'PAYMENT_ERROR', 'details': e.toString()}
          ));
        }
      }
    }
  }

  Future<void> _handleWebPayment(Map<String, dynamic> options) async {
    try {
      // Validate authentication
      if (!options.containsKey('key') || options['key'].toString().isEmpty) {
        throw PaymentFailureResponse(400, 'Authentication failed', {
          'code': 'BAD_REQUEST_ERROR',
          'description': 'API key is missing or invalid'
        });
      }

      // Validate API key format
      final String apiKey = options['key'].toString();
      if (!apiKey.startsWith('rzp_')) {
        throw PaymentFailureResponse(400, 'Authentication failed', {
          'code': 'BAD_REQUEST_ERROR',
          'description': 'Invalid API key format'
        });
      }

      // Create order in Firestore with additional validation
      final response = await _firestore.collection('razorpay_orders').add({
        'api_key_valid': true,
        'key_type': apiKey.startsWith('rzp_test_') ? 'test' : 'live',
        'amount': options['amount'],
        'currency': 'INR',
        'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'created',
        'created_at': FieldValue.serverTimestamp(),
      });

      // Validate order creation response
      if (response.id.isEmpty) {
        throw PaymentFailureResponse(500, 'Order creation failed', {
          'code': 'ORDER_CREATION_ERROR',
          'description': 'Failed to create order in Firestore'
        });
      }

      // Get the current origin for the callback URL
      final String origin = Uri.base.origin;
      final String callbackUrl = '$origin/payment-callback';

      // Setup message listener for payment responses
      html.window.onMessage.listen((html.MessageEvent e) {
        final data = e.data;
        if (data is Map) {
          if (data['type'] == 'PAYMENT_SUCCESS') {
            final paymentData = data['data'];
            _handlePaymentSuccess(PaymentSuccessResponse(
              paymentData['razorpay_payment_id'],
              response.id,
              paymentData['razorpay_signature']
            , 'INR' as Map?)); // Added currency parameter as the 4th argument
          } else if (data['type'] == 'PAYMENT_ERROR') {
            final error = data['data'];
            _handlePaymentError(PaymentFailureResponse(
              error['code'] ?? 500,
              error['description'] ?? 'Payment Failed',
              error
            ));
          }
        }
      });

      // Create a payment handler function
      const js = '''window.razorpayHandler = function(response) {
        if (response.razorpay_payment_id) {
          window.parent.postMessage({ type: 'PAYMENT_SUCCESS', data: response }, '*');
        } else if (response.error) {
          window.parent.postMessage({ type: 'PAYMENT_ERROR', data: response.error }, '*');
        }
      }''';

      // Inject the payment handler script
      if (kIsWeb) {
        final scriptElement = html.ScriptElement()..text = js;
        html.document.body?.children.add(scriptElement);
      }

      // Construct checkout URL with validated parameters
      final Uri url = Uri.https('api.razorpay.com', '/v1/checkout/embedded', {
        'key': options['key'],
        'amount': options['amount'].toString(),
        'currency': 'INR',
        'name': options['name'],
        'description': options['description'],
        'prefill': jsonEncode(options['prefill']),
        'notes': jsonEncode(options['notes']),
        'callback_url': callbackUrl,
        'order_id': response.id,
        'handler': 'razorpayHandler',
        '_': DateTime.now().millisecondsSinceEpoch.toString(), // Cache buster
      });

      // Validate URL and launch checkout
      if (!await canLaunchUrl(url)) {
        throw PaymentFailureResponse(500, 'URL launch failed', {
          'code': 'URL_LAUNCH_ERROR',
          'description': 'Unable to launch payment gateway URL'
        });
      }

      // Validate and launch the payment URL
      await launchUrl(
        url,
        webOnlyWindowName: '_self',
        mode: LaunchMode.platformDefault
      );
    } catch (e) {
      if (e is PaymentFailureResponse) {
        _onError(e);
      } else {
        _onError(PaymentFailureResponse(
          500,
          'Payment processing failed',
          {'code': 'PAYMENT_ERROR', 'details': e.toString()}
        ));
      }
    }
  } 

  late Function(PaymentSuccessResponse) _onSuccess;
  late Function(PaymentFailureResponse) _onError;
  late Function(ExternalWalletResponse) _onExternalWallet;

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _onSuccess(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onError(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onExternalWallet(response);
  }

  void dispose() {
    _razorpay.clear();
  }
}