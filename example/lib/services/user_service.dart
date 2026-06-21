import 'package:flutter/material.dart';
import 'package:rs_iron/rs_iron.dart';

import '../../repositories/user_repository.dart';
import '../app_module.rs_iron.dart';
import 'database_service.dart';

@Service()
class UserService with IronCore, IronMixin {
  UserService(ConfigurationService config)
    : serviceName = 'UserService-${config.environment}';
  final String serviceName;

  @Autowired()
  late UserRepository userRepository;

  void getUserById(String id) {
    print('$serviceName: Getting user $id');
    userRepository.findUser(id);
  }

  // ===== Examples using router.context =====

  /// Delete user with confirmation dialog using router context
  Future<bool> deleteUserWithConfirmation(String userId) async {
    final context = routerService.safeContext;
    if (context == null) {
      print('No context available for dialog');
      return false;
    }

    // Show confirmation dialog using router context
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Perform delete
        await userRepository.deleteUser(userId);

        // Show success message using router context
        _showSnackBar('User deleted successfully', Colors.green);

        // Navigate back to home
        await routerService.navigateToHome();

        return true;
      } catch (e) {
        // Show error message using router context
        _showSnackBar('Failed to delete user: $e', Colors.red);
        return false;
      }
    }

    return false;
  }

  /// Create user and show progress using router context
  Future<void> createUserWithProgress(String name, String email) async {
    final context = routerService.safeContext;
    if (context == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Creating user...'),
          ],
        ),
      ),
    );

    try {
      // Create user
      final user = await userRepository.createUser(name, email);

      // Hide loading dialog
      Navigator.of(context).pop();

      // Show success and navigate
      _showSnackBar('User created successfully!', Colors.green);
      await routerService.navigateToUserDetails(user.id);
    } catch (e) {
      // Hide loading dialog
      Navigator.of(context).pop();

      // Show error
      _showSnackBar('Failed to create user: $e', Colors.red);
    }
  }

  /// Get theme-aware color based on router context
  Color getUserStatusColor(String status) {
    final isDark = routerService.isDarkMode;

    switch (status.toLowerCase()) {
      case 'active':
        return isDark ? Colors.green[300]! : Colors.green[700]!;
      case 'inactive':
        return isDark ? Colors.grey[400]! : Colors.grey[600]!;
      case 'blocked':
        return isDark ? Colors.red[300]! : Colors.red[700]!;
      default:
        return isDark ? Colors.blue[300]! : Colors.blue[700]!;
    }
  }

  /// Show user options bottom sheet using router context
  Future<String?> showUserOptionsSheet(String userId) async {
    final context = routerService.safeContext;
    if (context == null) return null;

    return showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext sheetContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'User Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit User'),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () => Navigator.of(sheetContext).pop('block'),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete User'),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
          ],
        ),
      ),
    );
  }

  /// Private helper to show snackbar
  void _showSnackBar(String message, Color backgroundColor) {
    final context = routerService.safeContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
