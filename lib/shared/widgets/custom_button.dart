// lib/shared/widgets/custom_button.dart

import 'package:flutter/material.dart';

/// It handles showing a loading indicator when `isLoading` is true,
/// and disables the button to prevent multiple taps during an async operation.
class CustomButton extends StatelessWidget {
  /// The text to display on the button.
  final String text;

  /// The callback function to execute when the button is tapped.
  final VoidCallback? onPressed;

  /// A boolean to indicate if the button should be in a loading state.
  final bool isLoading;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a SizedBox to maintain the button's height even when showing the indicator.
    return SizedBox(
      height: 48, // A standard height for buttons
      width: double.infinity, // Make the button take the full width
      child: ElevatedButton(
        // Disable the button if it's loading or if no onPressed is provided.
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.0,
          ),
        )
            : Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}