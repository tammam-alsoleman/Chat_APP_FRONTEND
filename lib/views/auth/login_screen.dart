// lib/views/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/locator.dart'; // <-- 1. IMPORT get_it LOCATOR
import '../../shared/enums.dart';
import '../../shared/utils.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../view_models/auth/login_viewmodel.dart';
import '../main_navigation_screen.dart';

class LoginScreen extends StatelessWidget { // <-- 2. CAN BE A StatelessWidget
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We get a fresh instance of AuthViewModel from our service locator
    return ChangeNotifierProvider(
      create: (_) => sl<AuthViewModel>(), // <-- 3. USE sl<AuthViewModel>()
      child: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: const _LoginForm(),
      ),
    );
  }
}

/// A private StatefulWidget to manage the form's state (controllers, form key).
class _LoginForm extends StatefulWidget {
  const _LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // This helper function remains the same, it's an excellent pattern.
  void _handleStateChanges(BuildContext context, AuthViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if the widget is still in the tree before showing UI
      if (!mounted) return;

      if (viewModel.state == ViewState.Error && viewModel.failure != null) {
        AppUtils.showSnackBar(context, viewModel.failure!.message, isError: true);
      } else if (viewModel.state == ViewState.Success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, viewModel, child) {
        _handleStateChanges(context, viewModel);

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.blue),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _usernameController,
                    labelText: 'Username',
                    prefixIcon: Icons.person_outline,
                    isEnabled: viewModel.state != ViewState.Busy,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    isObscure: true,
                    isEnabled: viewModel.state != ViewState.Busy,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Login',
                    isLoading: viewModel.state == ViewState.Busy,
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        viewModel.login(
                          _usernameController.text,
                          _passwordController.text,
                          context,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: viewModel.state == ViewState.Busy ? null : () {
                      // TODO: Navigate to SignUpScreen
                    },
                    child: const Text("Don't have an account? Sign Up"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}