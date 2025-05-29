import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  final String userEmail;
  const DashboardScreen({super.key, required this.userEmail});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  String message = '';

  final TextEditingController amountController = TextEditingController();
  final TextEditingController stashNameController = TextEditingController();
  final TextEditingController stashGoalController = TextEditingController();
  final TextEditingController stashMonthsController = TextEditingController();

  Map<String, TextEditingController> stashAmountControllers = {};

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  @override
  void dispose() {
    amountController.dispose();
    stashNameController.dispose();
    stashGoalController.dispose();
    stashMonthsController.dispose();
    stashAmountControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> fetchDashboard() async {
    final url = Uri.parse('http://127.0.0.1:5000/api/dashboard');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          userData = jsonDecode(response.body)['user'];
          isLoading = false;

          stashAmountControllers.forEach((key, controller) => controller.dispose());
          stashAmountControllers.clear();
          if (userData['stash'] != null) {
            for (var stash in userData['stash']) {
              stashAmountControllers[stash['name']] = TextEditingController();
            }
          }
        });
      } else {
        setState(() {
          message = 'Failed to load dashboard';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error fetching data';
        isLoading = false;
      });
    }
  }

  Future<void> depositToMain() async {
    final url = Uri.parse('http://127.0.0.1:5000/api/deposit_main');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"amount": amountController.text}),
      );
      if (response.statusCode == 200) {
        fetchDashboard();
        amountController.clear();
        setState(() {
          message = 'Deposit to main account successful';
        });
      } else {
        setState(() {
          message = 'Deposit failed';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Server error';
      });
    }
  }

  Future<void> createStash() async {
    final url = Uri.parse('http://127.0.0.1:5000/api/stash/create');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": stashNameController.text,
          "goal": stashGoalController.text,
          "months": stashMonthsController.text
        }),
      );
      if (response.statusCode == 201) {
        fetchDashboard();
        stashNameController.clear();
        stashGoalController.clear();
        stashMonthsController.clear();
        setState(() {
          message = 'Stash created successfully';
        });
      } else {
        setState(() {
          message = jsonDecode(response.body)['error'] ?? 'Stash creation failed';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Stash creation failed';
      });
    }
  }

  Future<void> depositToStash(String stashName, String amount) async {
    if (amount.isEmpty) {
      setState(() {
        message = 'Enter an amount for stash deposit';
      });
      return;
    }
    final url = Uri.parse('http://127.0.0.1:5000/api/stash/deposit');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"stash_name": stashName, "amount": amount}),
      );
      if (response.statusCode == 200) {
        fetchDashboard();
        stashAmountControllers[stashName]?.clear();
        setState(() {
          message = 'Deposited R$amount to stash "$stashName"';
        });
      } else {
        setState(() {
          message = jsonDecode(response.body)['error'] ?? 'Deposit failed';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Failed to deposit to stash';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('X Bank Dashboard')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Welcome ${userData['name']}!',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Email: ${userData['email']}'),
                  Text('Phone: ${userData['phone']}'),
                  Text('Main Balance: R${userData['main_balance']}'),
                  const Divider(),
                  const Text('Deposit to Main Account:'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'Amount'),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: depositToMain,
                        child: const Text('Deposit'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text('Create New Stash:'),
                  TextField(
                    controller: stashNameController,
                    decoration: const InputDecoration(labelText: 'Stash Name'),
                  ),
                  TextField(
                    controller: stashGoalController,
                    decoration: const InputDecoration(labelText: 'Monthly Goal (e.g. 900)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: stashMonthsController,
                    decoration: const InputDecoration(labelText: 'Duration in Months'),
                    keyboardType: TextInputType.number,
                  ),
                  ElevatedButton(
                    onPressed: createStash,
                    child: const Text('Create Stash'),
                  ),
                  const Divider(),
                  const Text('Your Stash Accounts:'),
                  if (userData['stash'] != null)
                    ...userData['stash'].map<Widget>((stash) {
                      final stashName = stash['name'];
                      final controller = stashAmountControllers[stashName];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${stashName} - R${stash['balance']}/${stash['goal']}'),
                              Text('Months Paid: ${stash['paid_months']} of ${stash['months']}'),
                              Text('Remaining this month: R${stash['remaining']}'),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(hintText: 'Amount'),
                                      keyboardType: TextInputType.number,
                                      onSubmitted: (value) {
                                        if (value.isNotEmpty) {
                                          depositToStash(stashName, value);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      final amount = controller?.text ?? '';
                                      if (amount.isNotEmpty) {
                                        depositToStash(stashName, amount);
                                      } else {
                                        setState(() {
                                          message = 'Enter amount to deposit';
                                        });
                                      }
                                    },
                                    child: const Text('Deposit'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 10),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
    );
  }
}
