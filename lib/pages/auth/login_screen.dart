import 'package:flutter/material.dart';
import '../../models/local_profile.dart';
import '../../services/auth_service.dart';
import 'account_form_screen.dart';

typedef LocalProfileCallback = Future<void> Function(LocalProfile profile);

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onAuthenticated,
    AuthService? authService,
  }) : _authService = authService;

  final LocalProfileCallback onAuthenticated;
  final AuthService? _authService;

  @override
  Widget build(BuildContext context) => AccountFormScreen(
        isRegister: false,
        onAuthenticated: onAuthenticated,
        authService: _authService,
      );
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({
    super.key,
    required this.onAuthenticated,
    AuthService? authService,
  }) : _authService = authService;

  final LocalProfileCallback onAuthenticated;
  final AuthService? _authService;

  @override
  Widget build(BuildContext context) => AccountFormScreen(
        isRegister: true,
        onAuthenticated: onAuthenticated,
        authService: _authService,
      );
}
