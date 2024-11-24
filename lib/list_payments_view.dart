import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:strappi_test/keys.dart';

// Usamos un alias para evitar conflicto con la clase Card de Stripe
import 'package:flutter/material.dart' as flutter_material;

class ListPaymentsPage extends StatefulWidget {
  final String customerId;

  ListPaymentsPage({required this.customerId});

  @override
  _ListPaymentsPageState createState() => _ListPaymentsPageState();
}

class _ListPaymentsPageState extends State<ListPaymentsPage> {
  List<dynamic> _payments = [];
  String _responseMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    final url = Uri.parse(
        'https://8bfe-200-68-161-194.ngrok-free.app/api/v1/stripe/list-payments?customerId=${widget.customerId}');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $Token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _payments = data;
          _responseMessage = "Payments loaded successfully!";
        });
      } else {
        setState(() {
          _responseMessage = "Failed to load payments: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = "Error: $e";
      });
    }
  }

  Future<void> _resumePaymentIntent(String paymentIntentId) async {
    try {
      final responseFromStripeAPI = await http.get(
        Uri.parse("https://api.stripe.com/v1/payment_intents/$paymentIntentId"),
        headers: {
          "Authorization": "Bearer $secretKey",
          "Content-Type": "application/x-www-form-urlencoded",
        },
      );

      if (responseFromStripeAPI.statusCode == 200) {
        final paymentIntentData = jsonDecode(responseFromStripeAPI.body);

        if (paymentIntentData != null &&
            paymentIntentData['status'] == 'requires_payment_method') {
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntentData["client_secret"],
              style: ThemeMode.dark,
              merchantDisplayName: "GO1 Company",
            ),
          );
          await _showPaymentSheet();
        }
      } else {
        throw Exception("Failed to retrieve PaymentIntent");
      }
    } catch (error) {
      print("Error resuming PaymentIntent: $error");
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          content: Text("Error: $error"),
        ),
      );
    }
  }

  Future<void> _showPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((val) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment completed successfully")),
        );
      }).onError((errorMsg, sTrace) {
        print(errorMsg.toString() + sTrace.toString());
      });
    } on StripeException catch (error) {
      print("Payment cancelled: $error");
      showDialog(
        context: context,
        builder: (c) => const AlertDialog(
          content: Text("Cancelled"),
        ),
      );
    } catch (errorMsg) {
      print("Error presenting PaymentSheet: $errorMsg");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payments List"),
      ),
      body: _payments.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _payments.length,
              itemBuilder: (context, index) {
                final payment = _payments[index];
                return flutter_material.Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    title: Text("Payment ID: ${payment['id']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Amount: \$${(payment['amount'] / 100).toString()}"),
                        Text("Status: ${payment['status']}"),
                        Text("Currency: ${payment['currency']}"),
                        Text("Order ID: ${payment['metadata']['orderId'] ?? 'N/A'}"),
                        Text(
                            "Created: ${DateTime.fromMillisecondsSinceEpoch(payment['created'] * 1000)}"),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      if (payment['status'] == 'requires_payment_method') {
                        _resumePaymentIntent(payment['id']);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Payment is not in a resumable state."),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
