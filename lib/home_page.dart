import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:strappi_test/call_view.dart';
import 'package:strappi_test/check_out_view.dart';
import 'package:strappi_test/keys.dart';

class HomePage extends StatefulWidget{
  const HomePage ({super.key});
  @override
  State<HomePage> createState() => _HomePageState(); 
}

class _HomePageState extends State<HomePage>{
  double amount = 10;
  Map<String, dynamic>? intentPaymentData;
  
  showPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((val){
        intentPaymentData = null;
      }).onError((errorMsg, sTrace){
        if (kDebugMode) {
          print(errorMsg.toString() + sTrace.toString());
        }
      });
    } 
    on StripeException catch(error) {
      if (kDebugMode) {
        print(error);
      }
      showDialog(context: context, builder: (c)=>const AlertDialog(content: Text("Cancelled"),));
    }
    catch (errorMsg) {
      if (kDebugMode) {
        print(errorMsg);
      }
      print(errorMsg.toString());
    }
  }

  makeIntentForPayment(amountToBeCharge, currency) async {
    try {
      Map<String, dynamic>? paymentInfo = {
        "amount" : (int.parse(amountToBeCharge)*100).toString(),
        "currency" : currency,
        "payment_method_types[]" : "card",
      };

      var responseFromStripeAPI = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        body: paymentInfo,
        headers: {
          "Authorization" : "Bearer $secretKey",
          "Content-Type" : "application/x-www-form-urlencoded"
        }
      );

      print("response from API = ${responseFromStripeAPI.body}");

      return jsonDecode(responseFromStripeAPI.body);

    } catch (errorMsg) {
      if (kDebugMode) {
        print(errorMsg);
      }
      // ignore: avoid_print
      print(errorMsg.toString());
    }
  }

  paymentSheetInitialization(amountToBeCharge, currency) async{
    try {
      intentPaymentData = await makeIntentForPayment(amountToBeCharge, currency);
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          allowsDelayedPaymentMethods: true,
          paymentIntentClientSecret: intentPaymentData!["client_secret"],
          style: ThemeMode.dark,
          merchantDisplayName: "GO1 Company"
          )
      ).then((val)
      {
        print(val);
      });
      showPaymentSheet();
    } catch (errorMsg, s) {
      if (kDebugMode) {
        print(s);
      }
      // ignore: avoid_print
      print(errorMsg.toString());
    }
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
            onPressed:()
            {
              paymentSheetInitialization(amount.round().toString(), "USD");
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: 
            Text("Pay now ${amount.toString()}",
            style: const TextStyle(color: Colors.white)
            ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentForm()),
              ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: 
            const Text("Here is for the check",
            style: TextStyle(color: Colors.white)
            ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateOrderPage()),
              ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: 
            const Text("Call from the API stripe...",
            style: TextStyle(color: Colors.white)
            ),
            )
          ],
        ),
      ),
    );
  }
}