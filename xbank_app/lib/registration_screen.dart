import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController(); // ✅
  final TextEditingController idNumberController = TextEditingController(); // ✅
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String preferredContact = 'Email';
  String message = '';
  bool isLoading = false;

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        message = 'Passwords do not match!';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    final url = Uri.parse('http://127.0.0.1:5000/api/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text.trim(),
          'surname': surnameController.text.trim(), // ✅ added
          'id': idNumberController.text.trim(), // ✅ added
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'password': passwordController.text,
          'preferred_contact': preferredContact.toLowerCase(),
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          message = 'Registration successful! Check your ${preferredContact.toLowerCase()} for confirmation.';
        });
      } else {
        final resBody = jsonDecode(response.body);
        setState(() {
          message = resBody['error'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error connecting to server.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('XBank Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              TextFormField(
                controller: surnameController,
                decoration: const InputDecoration(labelText: 'Surname'), // ✅
                validator: (value) => value!.isEmpty ? 'Please enter your surname' : null,
              ),
              TextFormField(
                controller: idNumberController,
                decoration: const InputDecoration(labelText: 'ID Number'), // ✅
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter your ID number' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Cellphone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
              ),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                validator: (value) => value!.isEmpty ? 'Please confirm your password' : null,
              ),
              const SizedBox(height: 20),
              const Text('Preferred Communication Method:'),
              ListTile(
                title: const Text('Email'),
                leading: Radio<String>(
                  value: 'Email',
                  groupValue: preferredContact,
                  onChanged: (value) {
                    setState(() {
                      preferredContact = value!;
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('SMS'),
                leading: Radio<String>(
                  value: 'SMS',
                  groupValue: preferredContact,
                  onChanged: (value) {
                    setState(() {
                      preferredContact = value!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: registerUser,
                      child: const Text('Register'),
                    ),
              const SizedBox(height: 20),
              Text(
                message,
                style: TextStyle(color: message.contains('successful') ? Colors.green : Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
