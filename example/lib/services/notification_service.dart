import 'package:flutter/material.dart';
import 'package:rs_iron/rs_iron.dart';

import '../app_module.rs_iron.dart';

@Service(scope: ScopeType.factory)
class NotificationService with IronCore, IronMixin {
  /// Show success message using router context
  void showSuccess(String message) {
    routerService.showSnackBar(message, duration: const Duration(seconds: 2));
  }

  /// Show error message using router context
  void showError(String message) {
    final context = routerService.safeContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Show confirmation dialog using router context
  Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Yes',
    String cancelText = 'No',
  }) async {
    final result = await routerService.showAppDialog<bool>(
      child: AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(routerService.context!).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(routerService.context!).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show loading dialog using router context
  void showLoadingDialog({String message = 'Loading...'}) {
    routerService.showAppDialog(
      barrierDismissible: false,
      child: AlertDialog(
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

  /// Hide any currently shown dialog
  void hideDialog() {
    final context = routerService.safeContext;
    if (context != null) {
      Navigator.of(context).pop();
    }
  }

  /// Show a custom bottom sheet using router context
  Future<T?> showOptionsBottomSheet<T>({
    required String title,
    required List<BottomSheetOption<T>> options,
  }) {
    return routerService.showAppBottomSheet<T>(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...options.map(
              (option) => ListTile(
                leading: option.icon,
                title: Text(option.title),
                subtitle: option.subtitle != null
                    ? Text(option.subtitle!)
                    : null,
                onTap: () {
                  Navigator.of(routerService.context!).pop(option.value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get screen size using router context
  Size? get screenSize {
    final mediaQuery = routerService.mediaQuery;
    return mediaQuery?.size;
  }

  /// Check if screen is small using router context
  bool get isSmallScreen {
    final size = screenSize;
    return size != null && size.width < 600;
  }
}

class BottomSheetOption<T> {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final T value;

  BottomSheetOption({
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
  });
}
