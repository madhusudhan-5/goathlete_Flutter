class RazorpayCheckoutRequest {
  final String keyId;
  final String orderId;
  final int amountPaise;
  final String currency;
  final String name;
  final String description;
  final String prefillName;
  final String prefillEmail;
  final String prefillContact;

  const RazorpayCheckoutRequest({
    required this.keyId,
    required this.orderId,
    required this.amountPaise,
    this.currency = 'INR',
    this.name = 'GoAthlete',
    required this.description,
    this.prefillName = '',
    this.prefillEmail = '',
    this.prefillContact = '',
  });
}

class RazorpayPaymentResult {
  final String orderId;
  final String paymentId;
  final String signature;

  const RazorpayPaymentResult({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });
}

class RazorpayCheckoutException implements Exception {
  final String message;
  final bool cancelled;

  const RazorpayCheckoutException(this.message, {this.cancelled = false});

  @override
  String toString() => message;
}
