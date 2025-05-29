import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // Step 1: Login
      final loginResponse = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/login'), // <- Updated from localhost
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      print('Login response code: ${loginResponse.statusCode}');
      print('Login response body: ${loginResponse.body}');

      if (loginResponse.statusCode != 200) {
        setState(() {
          _errorMessage = 'Invalid login credentials';
          _isLoading = false;
        });
        return;
      }

      // Decode login response
      final loginData = json.decode(loginResponse.body);

      // Optional: If your backend returns a token, store and use it
      final token = loginData['token'];

      // Step 2: Get user dashboard (adjust if token-based auth is required)
      final dashboardResponse = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('Dashboard response code: ${dashboardResponse.statusCode}');
      print('Dashboard response body: ${dashboardResponse.body}');

      if (dashboardResponse.statusCode != 200) {
        setState(() {
          _errorMessage = 'Failed to load user data';
          _isLoading = false;
        });
        return;
      }

      final user = json.decode(dashboardResponse.body)['user'];

      // Navigate to WelcomeScreen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WelcomeScreen(
            name: user['name'],
            surname: user['surname'],
            email: user['email'],
            phone: user['phone'],
          ),
        ),
      );
    } catch (e) {
      print('Login error: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
          ],
        ),
      ),
    );
  }
}
