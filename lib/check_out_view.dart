import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:strappi_test/keys.dart';

class PaymentForm extends StatefulWidget {
  @override
  _PaymentFormState createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _postalCodeController = TextEditingController();
  String? _selectedCountry;
  final Logger logger = Logger();
  String _paymentStatus = '';

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = publishKey;
  }

  Future<Map<String, dynamic>> makePaymentIntent(double amount, String currency) async {
    try {
      Map<String, dynamic>? paymentInfo = {
        "amount": (amount * 100).toInt().toString(),
        "currency": currency,
        "payment_method_types[]": "card",
      };

      var response = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        body: paymentInfo,
        headers: {
          "Authorization": "Bearer $secretKey",
          "Content-Type": "application/x-www-form-urlencoded"
        },
      );

      logger.d("Response from Stripe API: ${response.body}");
      return jsonDecode(response.body);
    } catch (error) {
      logger.e("Error al crear el PaymentIntent: $error");
      rethrow;
    }
  }

  Future<void> confirmPaymentIntent(String clientSecret, PaymentMethodParams paymentMethodParams) async {
    try {
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: paymentMethodParams,
      );

      setState(() {
        _paymentStatus = paymentIntent.status == PaymentIntentsStatus.Succeeded
            ? 'Pago realizado con éxito'
            : 'El pago no fue exitoso: ${paymentIntent.status}';
      });
    } catch (e) {
      setState(() {
        _paymentStatus = 'Error al confirmar el pago: $e';
      });
    }
  }

  PaymentMethodParams _createPaymentMethodParams() {
    return PaymentMethodParams.card(
      paymentMethodData: PaymentMethodData(
        billingDetails: const BillingDetails(
          name: 'John Doe',
          email: 'email@example.com',
        ),
        shippingDetails: ShippingDetails(
          address: Address(
            city: 'Ciudad',
            country: _selectedCountry ?? '',
            line1: 'Calle Ficticia 123',
            line2: 'Edificio A',
            postalCode: _postalCodeController.text,
            state: 'Estado',
          ),
        ),
      ),
    );
  }

  Future<void> processPaymentWithoutUI(double amount, String currency) async {
    setState(() {
      _paymentStatus = 'Procesando...';
    });

    try {
      final paymentIntentData = await makePaymentIntent(amount, currency);
      await confirmPaymentIntent(paymentIntentData['client_secret'], _createPaymentMethodParams());
    } catch (e) {
      setState(() {
        _paymentStatus = 'Error al procesar el pago: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CardFormField(
                style: CardFormStyle(
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  borderColor: Colors.grey,
                  borderRadius: 8,
                  textColor: const Color.fromARGB(255, 255, 255, 255),
                  fontSize: 16,
                ),
                controller: CardFormEditController(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(_paymentStatus),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    processPaymentWithoutUI(3500, "MXN");
                  }
                },
                child: const Text('Procesar pago'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
