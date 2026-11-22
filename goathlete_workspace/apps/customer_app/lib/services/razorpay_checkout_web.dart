import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'razorpay_checkout_types.dart';

@JS('Razorpay')
extension type _RazorpayJS._(JSObject _) implements JSObject {
  external factory _RazorpayJS(JSObject options);
  external void open();
  external void on(String event, JSFunction callback);
}

@JS('window')
external JSObject get _window;

/// Opens Razorpay Checkout.js on Flutter Web (iOS Safari / Mobile Chrome PWA).
Future<RazorpayPaymentResult> openRazorpayCheckout(
  RazorpayCheckoutRequest request,
) {
  final completer = Completer<RazorpayPaymentResult>();

  if (!_window.has('Razorpay')) {
    completer.completeError(
      const RazorpayCheckoutException(
        'Razorpay Checkout script failed to load. Please refresh and try again.',
      ),
    );
    return completer.future;
  }

  final prefill = JSObject();
  if (request.prefillName.isNotEmpty) {
    prefill['name'] = request.prefillName.toJS;
  }
  if (request.prefillEmail.isNotEmpty) {
    prefill['email'] = request.prefillEmail.toJS;
  }
  if (request.prefillContact.isNotEmpty) {
    prefill['contact'] = request.prefillContact.toJS;
  }

  final theme = JSObject();
  theme['color'] = '#DA6F2B'.toJS;

  final modal = JSObject();
  modal['ondismiss'] = (() {
    if (!completer.isCompleted) {
      completer.completeError(
        const RazorpayCheckoutException('Payment cancelled.', cancelled: true),
      );
    }
  }).toJS;

  final options = JSObject();
  options['key'] = request.keyId.toJS;
  options['amount'] = request.amountPaise.toJS;
  options['currency'] = request.currency.toJS;
  options['name'] = request.name.toJS;
  options['description'] = request.description.toJS;
  options['order_id'] = request.orderId.toJS;
  options['prefill'] = prefill;
  options['theme'] = theme;
  options['modal'] = modal;
  options['handler'] = ((JSObject response) {
    if (completer.isCompleted) return;
    final paymentId = (response['razorpay_payment_id'] as JSString?)?.toDart ?? '';
    final orderId = (response['razorpay_order_id'] as JSString?)?.toDart ?? request.orderId;
    final signature = (response['razorpay_signature'] as JSString?)?.toDart ?? '';

    if (paymentId.isEmpty || signature.isEmpty) {
      completer.completeError(
        const RazorpayCheckoutException('Incomplete Razorpay payment response.'),
      );
      return;
    }

    completer.complete(
      RazorpayPaymentResult(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      ),
    );
  }).toJS;

  try {
    final rzp = _RazorpayJS(options);
    rzp.on(
      'payment.failed',
      ((JSObject errResponse) {
        if (completer.isCompleted) return;
        final errObj = errResponse['error'] as JSObject?;
        final desc = (errObj?['description'] as JSString?)?.toDart;
        completer.completeError(
          RazorpayCheckoutException(
            (desc != null && desc.isNotEmpty) ? desc : 'Payment failed.',
          ),
        );
      }).toJS,
    );
    rzp.open();
  } catch (e) {
    if (!completer.isCompleted) {
      completer.completeError(
        RazorpayCheckoutException('Could not open Razorpay Checkout: $e'),
      );
    }
  }

  return completer.future;
}
