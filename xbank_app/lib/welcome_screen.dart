import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isRegistering = false;

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _welcomeName;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uri = Uri.parse(_isRegistering
        ? 'http://localhost:5000/api/register'
        : 'http://localhost:5000/api/login');

    final body = _isRegistering
        ? {
            'name': _nameController.text.trim(),
            'surname': _surnameController.text.trim(),
            'id': _idController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          }
        : {
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          };

    final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        _welcomeName = _isRegistering
            ? _nameController.text.trim()
            : data['user']?['name'] ?? 'User';
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_welcomeName != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Welcome')),
        body: Center(
          child: Text(
            'Welcome, $_welcomeName!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? 'Register' : 'Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_isRegistering) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your first name' : null,
                ),
                TextFormField(
                  controller: _surnameController,
                  decoration: const InputDecoration(labelText: 'Surname'),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your surname' : null,
                ),
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(labelText: 'ID Number'),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your ID number' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your phone number' : null,
                ),
              ],
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter your email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter your password' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isRegistering ? 'Register' : 'Login'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegistering = !_isRegistering;
                  });
                },
                child: Text(_isRegistering
                    ? 'Already have an account? Login'
                    : 'New user? Register'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
