import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:strappi_test/keys.dart';
import 'package:strappi_test/list_payments_view.dart';

class ListCustomersPage extends StatefulWidget {
  @override
  _ListCustomersPageState createState() => _ListCustomersPageState();
}

class _ListCustomersPageState extends State<ListCustomersPage> {
  List<dynamic> _customers = [];
  String _responseMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    final url = Uri.parse('https://8bfe-200-68-161-194.ngrok-free.app/api/v1/stripe/list-customers');
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
          _customers = data;
          _responseMessage = "Customers loaded successfully!";
        });
      } else {
        setState(() {
          _responseMessage = "Failed to load customers: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers List"),
      ),
      body: _customers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    title: Text(customer['name'] ?? 'No Name'),
                    subtitle: Text('Email: ${customer['email'] ?? 'No Email'}''\n''Description: ${customer['description']}' ),
                    onTap: () {
                      // Aquí pasamos el id del cliente al navegar
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListPaymentsPage(customerId: customer['id']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
