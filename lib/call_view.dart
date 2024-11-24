import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:strappi_test/keys.dart';

class CreateOrderPage extends StatefulWidget {
  @override
  _CreateOrderPageState createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  String _responseMessage = "";
  String _clientSecret = "";

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = publishKey;
  }

  Future<void> createPaymentIntent() async {
    //La siguiente URL solamente es para prueba, ya que localmente no se puede utilice ngrok
    final url = Uri.parse("https://8bfe-200-68-161-194.ngrok-free.app/api/v1/stripe/create-payment-intent");
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $Token',
    };
    final body = json.encode({
      //Este "Cliente" es creado desde el dashboard de Stripe, puedes hacerlo asi o dinamicamente haciendo otra llamada a la API
      "customerId": "cus_RG8awjP0TplDzY",
      "amount": 2000,
      "currency": "usd",
      "metadata": {
        "orderId": "12345"
      }
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _clientSecret = responseData['clientSecret'];
          _responseMessage = "Payment Intent Created Successfully";
        });
        await _showPaymentDialog();
      } else if (response.statusCode == 401) {
        setState(() {
          _responseMessage = "Unauthorized: Invalid Bearer Token";
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _responseMessage = "Not Found: API endpoint might be incorrect.";
        });
      } else {
        setState(() {
          _responseMessage = "Failed to create payment intent: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = "Error: $e";
      });
    }
  }

  Future<void> _showPaymentDialog() async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: _clientSecret,
          style: ThemeMode.system,
          merchantDisplayName: 'GO1 Tech',
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      setState(() {
        _responseMessage = "Payment completed successfully!";
      });
    } catch (e) {
      setState(() {
        _responseMessage = "Payment failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Order"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: createPaymentIntent,
              child: const Text("Crear PaymentIntent desde la API 20 USD"),
            ),
            const SizedBox(height: 20),
            Text(
              _responseMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
