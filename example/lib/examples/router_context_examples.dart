import 'package:flutter/material.dart';
import 'package:rs_iron/rs_iron.dart';

import '../app_module.rs_iron.dart';

/// Example demonstrating different ways to use router.context outside widgets
@Service()
class RouterContextExamples with IronCore, IronMixin {
  // ===== Basic Context Access =====

  /// Example 1: Basic context access
  void basicContextExample() {
    // Get context directly (can be null)
    BuildContext? context = routerService.context;
    print('Context available: ${context != null}');

    // Get context safely (checks if mounted)
    BuildContext? safeContext = routerService.safeContext;
    print('Safe context available: ${safeContext != null}');
  }

  // ===== UI Operations =====

  /// Example 2: Show snackbar from anywhere
  void showGlobalMessage(String message) {
    final context = routerService.safeContext;
    if (context != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Example 3: Show dialog from service
  Future<bool?> showConfirmDialog(String title, String message) async {
    final context = routerService.safeContext;
    if (context == null) return null;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // ===== Theme and Styling =====

  /// Example 4: Get theme data from context
  void themeExample() {
    final theme = routerService.theme;
    if (theme != null) {
      print('Primary color: ${theme.primaryColor}');
      print('Is dark mode: ${theme.brightness == Brightness.dark}');
    }

    // Using the convenience getter
    print('Is dark mode (convenience): ${routerService.isDarkMode}');
  }

  /// Example 5: Get responsive values based on screen size
  double getResponsivePadding() {
    final mediaQuery = routerService.mediaQuery;
    if (mediaQuery == null) return 16.0;

    final width = mediaQuery.size.width;
    if (width < 600) return 8.0; // Mobile
    if (width < 1200) return 16.0; // Tablet
    return 24.0; // Desktop
  }

  // ===== Error Handling =====

  /// Example 6: Safe operation with context check
  Future<void> safeOperation() async {
    final context = routerService.safeContext;
    if (context == null) {
      print('No context available, cannot show UI');
      return;
    }

    try {
      // Some async operation
      await Future.delayed(const Duration(seconds: 2));

      // Check if context is still valid after async operation
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Operation completed')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ===== Background/Async Operations =====

  /// Example 7: Background task with UI feedback
  Future<void> backgroundTaskWithUI() async {
    // Show loading
    _showLoadingDialog('Processing...');

    try {
      // Simulate background work
      await Future.delayed(const Duration(seconds: 3));

      // Hide loading and show result
      _hideDialog();
      showGlobalMessage('Background task completed!');
    } catch (e) {
      _hideDialog();
      showGlobalMessage('Task failed: $e');
    }
  }

  /// Example 8: Handle push notifications
  Future<void> handlePushNotification(Map<String, dynamic> data) async {
    final userId = data['userId'] as String?;
    final message = data['message'] as String?;

    // Show notification as snackbar
    if (message != null) {
      showGlobalMessage(message);
    }

    // Navigate based on notification data
    if (userId != null) {
      await routerService.navigateToUserDetails(userId);
    }
  }

  // ===== Utility Methods =====

  void _showLoadingDialog(String message) {
    final context = routerService.safeContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message),
            ],
          ),
        ),
      );
    }
  }

  void _hideDialog() {
    final context = routerService.safeContext;
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // ===== Advanced Examples =====

  /// Example 9: Context-aware logging
  void contextAwareLog(String message) {
    final context = routerService.safeContext;
    final route = context != null
        ? ModalRoute.of(context)?.settings.name
        : 'unknown';
    print('[$route] $message');
  }

  /// Example 10: Get localization from context
  String getLocalizedText(String key) {
    final context = routerService.safeContext;
    if (context != null) {
      // If you have localization setup:
      // return AppLocalizations.of(context)?.getString(key) ?? key;
      return key; // Fallback for this example
    }
    return key;
  }
}

/// Usage examples in other services
@Service()
class ExampleUsageService with IronCore, IronMixin {
  Future<void> demonstrateUsage() async {
    final examples = RouterContextExamples();

    // Basic usage
    examples.basicContextExample();

    // Show messages
    examples.showGlobalMessage('Hello from service!');

    // Get theme info
    examples.themeExample();

    // Safe operations
    await examples.safeOperation();

    // Background task
    await examples.backgroundTaskWithUI();
  }
}
