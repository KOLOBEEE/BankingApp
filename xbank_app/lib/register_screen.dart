import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final id = _idController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://YOUR_FLASK_BACKEND_IP:5000/api/register');
    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "email": email,
            "name": name,
            "surname": surname,
            "id": id,
            "phone": phone,
            "password": password,
          }));

      if (response.statusCode == 201) {
        // Registration success, navigate back to login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful. Please login.')));
          Navigator.of(context).pop();
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() => _errorMessage = data['error'] ?? "Registration failed");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error connecting to server");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'Enter email';
    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val)) return 'Enter valid email';
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Enter password';
    if (val.length < 6) return 'Minimum 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? val) {
    if (val != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _emailController,
              decoration:
                  const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (val) => val == null || val.isEmpty ? 'Enter name' : null,
            ),
            TextFormField(
              controller: _surnameController,
              decoration: const InputDecoration(labelText: 'Surname'),
              validator: (val) => val == null || val.isEmpty ? 'Enter surname' : null,
            ),
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'ID Number'),
              validator: (val) => val == null || val.isEmpty ? 'Enter ID number' : null,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (val) => val == null || val.isEmpty ? 'Enter phone number' : null,
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: _validatePassword,
            ),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
              validator: _validateConfirmPassword,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
            ],
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _register, child: const Text('Register')),
          ]),
        ),
      ),
    );
  }
}
