import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'razorpay_checkout_types.dart';

/// Opens native Razorpay Checkout on Android / iOS.
Future<RazorpayPaymentResult> openRazorpayCheckout(
  RazorpayCheckoutRequest request,
) {
  final completer = Completer<RazorpayPaymentResult>();
  final razorpay = Razorpay();

  void finishWithSuccess(PaymentSuccessResponse response) {
    razorpay.clear();
    if (completer.isCompleted) return;
    final paymentId = response.paymentId ?? '';
    final orderId = response.orderId ?? request.orderId;
    final signature = response.signature ?? '';
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
  }

  void finishWithError(PaymentFailureResponse response) {
    razorpay.clear();
    if (completer.isCompleted) return;
    final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    final msg = isCancelled
        ? 'Payment cancelled.'
        : (response.message?.isNotEmpty == true
            ? response.message!
            : 'Payment failed (code ${response.code}).');
    completer.completeError(
      RazorpayCheckoutException(msg, cancelled: isCancelled),
    );
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    // External wallet redirects back to success/error once completed.
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, finishWithSuccess);
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, finishWithError);
  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);

  final options = <String, dynamic>{
    'key': request.keyId,
    'amount': request.amountPaise,
    'currency': request.currency,
    'name': request.name,
    'description': request.description,
    'order_id': request.orderId,
    'prefill': {
      if (request.prefillName.isNotEmpty) 'name': request.prefillName,
      if (request.prefillEmail.isNotEmpty) 'email': request.prefillEmail,
      if (request.prefillContact.isNotEmpty) 'contact': request.prefillContact,
    },
    'theme': {'color': '#DA6F2B'},
  };

  try {
    razorpay.open(options);
  } catch (e) {
    razorpay.clear();
    if (!completer.isCompleted) {
      completer.completeError(
        RazorpayCheckoutException('Could not open Razorpay Checkout: $e'),
      );
    }
  }

  return completer.future;
}
