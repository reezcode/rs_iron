import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:rs_iron/rs_iron.dart';

import '../app_router.dart';

@Service()
class RouterService {
  late final AppRouter _appRouter;

  RouterService() {
    _appRouter = AppRouter();
  }

  /// Get the AppRouter instance
  AppRouter get router => _appRouter;

  /// Get the router configuration
  RouterConfig<Object> get config => _appRouter.config();

  /// Get the current BuildContext from the router
  BuildContext? get context => _appRouter.navigatorKey.currentContext;

  /// Get the current BuildContext safely with null check
  BuildContext? get safeContext {
    final ctx = _appRouter.navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      return ctx;
    }
    return null;
  }

  /// Navigate to a route
  Future<T?> push<T extends Object?>(PageRouteInfo route) {
    return _appRouter.push<T>(route);
  }

  /// Navigate back
  void pop<T extends Object?>([T? result]) {
    _appRouter.maybePop<T>(result);
  }

  /// Replace current route
  Future<T?> replace<T extends Object?>(PageRouteInfo route) {
    return _appRouter.replace<T>(route);
  }

  /// Navigate to home
  Future<void> navigateToHome() {
    return push(const HomeRoute());
  }

  /// Navigate to create user
  Future<void> navigateToCreateUser() {
    return push(const CreateUserRoute());
  }

  /// Navigate to user details
  Future<void> navigateToUserDetails(String userId) {
    return push(UserDetailsRoute(userId: userId));
  }

  // ===== BuildContext utility methods =====

  /// Show a snackbar using the router context
  void showSnackBar(String message, {Duration? duration}) {
    final ctx = safeContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration ?? const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show a dialog using the router context
  Future<T?> showAppDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    final ctx = safeContext;
    if (ctx != null) {
      return showDialog<T>(
        context: ctx,
        barrierDismissible: barrierDismissible,
        builder: (context) => child,
      );
    }
    return Future.value(null);
  }

  /// Show a bottom sheet using the router context
  Future<T?> showAppBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = false,
  }) {
    final ctx = safeContext;
    if (ctx != null) {
      return showModalBottomSheet<T>(
        context: ctx,
        isScrollControlled: isScrollControlled,
        builder: (context) => child,
      );
    }
    return Future.value(null);
  }

  /// Get theme data from the router context
  ThemeData? get theme {
    final ctx = safeContext;
    return ctx != null ? Theme.of(ctx) : null;
  }

  /// Get media query data from the router context
  MediaQueryData? get mediaQuery {
    final ctx = safeContext;
    return ctx != null ? MediaQuery.of(ctx) : null;
  }

  /// Check if the current theme is dark
  bool get isDarkMode {
    final themeData = theme;
    return themeData?.brightness == Brightness.dark;
  }
}
