import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  const StripeService._();
  static const StripeService instance = StripeService._();

  // TODO: Implementar lógica Stripe — leer la clave desde --dart-define o variables de entorno
  // flutter run --dart-define=STRIPE_PK=pk_test_...
  static const String _publishableKey = String.fromEnvironment(
    'STRIPE_PK',
    defaultValue: 'pk_test_PLACEHOLDER_SUSTITUIR_POR_CLAVE_REAL',
  );

  static Future<void> initialize() async {
    Stripe.publishableKey = _publishableKey;
    // applySettings() inicializa PaymentConfiguration en el lado nativo Android/iOS
    await Stripe.instance.applySettings();
  }

  // TODO: Implementar lógica Stripe
  // Flujo esperado con PaymentIntent client-side:
  //   1. POST al backend /api/stripe/create-payment-intent
  //      body: { amount: amountInCents, currency, booking_id }
  //   2. El backend devuelve { clientSecret, paymentIntentId }
  //   3. Stripe.instance.confirmPayment(clientSecret, ...) confirma el pago
  //      usando los datos del CardFormField directamente contra Stripe
  //   4. Retornar paymentIntentId para guardarlo en la reserva
  //
  // Hasta que el backend esté disponible, este método simula un pago exitoso.
  Future<String> processPayment({
    required double amount,
    required String currency,
    required String bookingId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    // Stub — sustituir por integración real con el backend
    return 'pi_stub_${DateTime.now().millisecondsSinceEpoch}';
  }
}
