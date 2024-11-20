import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateOrderPage extends StatefulWidget {
  @override
  _CreateOrderPageState createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  String _responseMessage = "";

  Future<void> createOrder() async {
    final url = Uri.parse("http://localhost:5000/api/frontoffice/v1/order/createorder");
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyTmFtZSI6InN1cGVyYWRtaW4iLCJzZWN1cml0eUNvZGVMb2dpbiI6IkZhbHNlIiwianRpIjoiNTdiZjY0NzEtYTEyMS00MTRlLThjZjAtM2E1MDI1NmM0MGI1IiwiZW1haWwiOiJzdXBlcmFkbWluLWdvMUBnbWFpbC5jb20iLCJ1aWQiOiIxIiwiaXAiOiIxOTIuMTY4LjguOSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvcm9sZSI6WyJTdXBlckFkbWluIiwiQWRtaW4iLCJBcHAiXSwiUGVybWlzc2lvbiI6WyJEZXN0aW5hdGlvbi5DcmVhdGUiLCJEZXN0aW5hdGlvbi5VcGRhdGUiLCJEZXN0aW5hdGlvbi5WaWV3IiwiRGVzdGluYXRpb24uRGVsZXRlIiwiSW1hZ2UuQ3JlYXRlIiwiSW1hZ2UuVXBkYXRlIiwiSW1hZ2UuVmlldyIsIkltYWdlLkRlbGV0ZSIsIkhvbWUuVG9wRGVzdGluYXRpb24iLCJIb21lLlRvcFRvdXJzIl0sImV4cCI6MTczMjE1MjU0MCwiaXNzIjoiQ29yZUlkZW50aXR5IiwiYXVkIjoiQ29yZUlkZW50aXR5VXNlciJ9.un-X7Aq5pCFdjAMxuerQizLU3THOJSfQUr46W3ZxsN4',
    };
    final body = json.encode({
      "userId": 0,
      "amount": 100.00,
      "currency": "MXN",
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        setState(() {
          _responseMessage = "Order created successfully: ${response.body}";
        });
        print("Response: ${response.body}");
      } else {
        setState(() {
          _responseMessage = "Failed to create order: ${response.statusCode}";
        });
        print("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      setState(() {
        _responseMessage = "Error: $e";
      });
      print("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Order"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: createOrder,
              child: Text("Create Order"),
            ),
            SizedBox(height: 20),
            Text(
              _responseMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
