// lib/views/auth/sign_up_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/locator.dart';
import '../../shared/enums.dart';
import '../../shared/utils.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../view_models/auth/sign_up_viewmodel.dart';
import '../main_navigation_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<SignUpViewModel>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Sign Up')),
        body: const _SignUpForm(),
      ),
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({Key? key}) : super(key: key);

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _userNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _userNameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleStateChanges(BuildContext context, SignUpViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (viewModel.state == ViewState.Error && viewModel.failure != null) {
        AppUtils.showSnackBar(context, viewModel.failure!.message, isError: true);
        // Clear input fields on error
        _userNameController.clear();
        _displayNameController.clear();
        _passwordController.clear();
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
    return Consumer<SignUpViewModel>(
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
                  const Icon(Icons.person_add_alt_1_outlined, size: 80, color: Colors.blue),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _userNameController,
                    labelText: 'Username',
                    prefixIcon: Icons.person_outline,
                    isEnabled: viewModel.state != ViewState.Busy,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username';
                      }
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _displayNameController,
                    labelText: 'Display Name',
                    prefixIcon: Icons.badge_outlined,
                    isEnabled: viewModel.state != ViewState.Busy,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your display name';
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
                    text: 'Sign Up',
                    isLoading: viewModel.state == ViewState.Busy,
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        viewModel.signUp(
                          _userNameController.text,
                          _passwordController.text,
                          _displayNameController.text,
                          context,
                        );
                      }
                    },
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
