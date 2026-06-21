import '../container/iron_container.dart';
import '../core/scope_type.dart';

/// Mixin for StatefulWidget States that provides easy access to dependency injection.
///
/// This mixin automatically initializes the IronContainer with discovered dependencies
/// and provides convenient methods to resolve dependencies without manual container management.
///
/// **Important**: To register generated dependencies, you must import your generated
/// `.rs_iron.dart` file and call `registerGeneratedDependencies()` manually in your app initialization:
///
/// ```dart
/// // main.dart
/// import 'package:flutter/material.dart';
/// import 'package:rs_iron/rs_iron.dart';
/// import 'app_module.rs_iron.dart'; // Your generated file
///
/// void main() async {
///   // Pre-initialize DI container with dependency registration
///   await IronCore.initialize((container) => container.registerGeneratedDependencies());
///   runApp(MyApp());
/// }
///
/// class MyApp extends StatefulWidget {
///   @override
///   _MyAppState createState() => _MyAppState();
/// }
///
/// class _MyAppState extends State<MyApp> with IronCore {
///   @override
///   void initState() {
///     super.initState();
///     // Dependencies are already registered via the callback in main()
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: MyHomePage(),
///     );
///   }
/// }
/// ```
///
/// Or use async pattern in individual widgets:
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   _MyWidgetState createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> with IronCore {
///   UserService? userService;
///
///   @override
///   void initState() {
///     super.initState();
///     _initializeDependencies();
///   }
///
///   void _initializeDependencies() async {
///     userService = await getAsync<UserService>();
///     setState(() {}); // Trigger rebuild with loaded dependencies
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     if (userService == null) {
///       return CircularProgressIndicator(); // Loading state
///     }
///     return Text('User: ${userService!.getCurrentUser()}');
///   }
/// }
/// ```
mixin IronCore {
  static IronContainer? _globalContainer;
  static bool _isInitialized = false;

  /// Gets the global IronContainer instance, initializing it if necessary.
  /// This is called automatically when using the get<T>() method.
  Future<IronContainer> get container async {
    if (!_isInitialized) {
      await _initializeContainer();
    }
    return _globalContainer!;
  }

  static IronContainer get currentContainer {
    if (!_isInitialized || _globalContainer == null) {
      throw StateError(
        'IronContainer not initialized. Either:\n'
        '1. Call "await IronCore.initialize()" in your main() method, or\n'
        '2. Use "await getAsync<T>()" for automatic initialization.\n'
        '3. In Flutter widgets, prefer using getAsync<T>() in initState().',
      );
    }
    return _globalContainer!;
  }

  /// Initialize the global container with generated dependencies.
  /// This method is called automatically on first access.
  static Future<void> _initializeContainer([
    void Function(IronContainer)? registerCallback,
  ]) async {
    if (_isInitialized) return;

    _globalContainer = IronContainer();
    await _globalContainer!.scan();

    // Call the registration callback if provided
    if (registerCallback != null) {
      registerCallback(_globalContainer!);
    }

    // Note: registerGeneratedDependencies() is an extension method from generated code.
    // Users need to ensure they import their generated .rs_iron.dart file where this
    // mixin is used for the extension to be available.

    _isInitialized = true;
  }

  /// Manually initialize the DI container.
  /// Call this in your app's main() method if you want to pre-initialize the container.
  ///
  /// Example:
  /// ```dart
  /// // Simple initialization
  /// await IronCore.initialize();
  ///
  /// // With dependency registration callback
  /// await IronCore.initialize((container) => container.registerGeneratedDependencies());
  /// ```
  static Future<void> initialize([
    void Function(IronContainer)? registerCallback,
  ]) async {
    await _initializeContainer(registerCallback);
  }

  /// Reset the container (useful for testing).
  static void reset() {
    _globalContainer = null;
    _isInitialized = false;
  }

  /// Get a dependency of type T from the container.
  ///
  /// **Important**: This method requires the container to be pre-initialized.
  /// For Flutter widgets, use `getAsync<T>()` in `initState()` or call
  /// `await IronCore.initialize()` in your app's main() method.
  ///
  /// Example:
  /// ```dart
  /// // Option 1: Pre-initialize in main()
  /// void main() async {
  ///   await IronCore.initialize();
  ///   runApp(MyApp());
  /// }
  ///
  /// // Then use synchronously:
  /// final userService = get<UserService>();
  ///
  /// // Option 2: Use async version in widgets
  /// final userService = await getAsync<UserService>();
  /// ```
  T get<T extends Object>([String? qualifier]) {
    if (!_isInitialized) {
      throw StateError(
        'IronContainer not initialized. Either:\n'
        '1. Call "await IronCore.initialize()" in your main() method, or\n'
        '2. Use "await getAsync<T>()" for automatic initialization.\n'
        '3. In Flutter widgets, prefer using getAsync<T>() in initState().',
      );
    }
    return _globalContainer!.get<T>(qualifier);
  }

  /// Asynchronously get a dependency of type T from the container.
  /// This method automatically initializes the container if needed.
  ///
  /// Example:
  /// ```dart
  /// final userService = await getAsync<UserService>();
  /// final namedService = await getAsync<UserService>('special');
  /// ```
  Future<T> getAsync<T extends Object>([String? qualifier]) async {
    final cont = await container;
    return cont.get<T>(qualifier);
  }

  /// Check if a dependency of type T is registered in the container.
  ///
  /// Example:
  /// ```dart
  /// if (has<UserService>()) {
  ///   final service = get<UserService>();
  /// }
  /// ```
  bool has<T extends Object>([String? qualifier]) {
    if (!_isInitialized) return false;
    return _globalContainer!.contains<T>(qualifier);
  }

  /// Asynchronously check if a dependency of type T is registered in the container.
  /// This method automatically initializes the container if needed.
  Future<bool> hasAsync<T extends Object>([String? qualifier]) async {
    final cont = await container;
    return cont.contains<T>(qualifier);
  }

  /// Register a dependency manually.
  /// This is useful for registering dependencies that aren't annotated.
  ///
  /// Example:
  /// ```dart
  /// register<ApiClient>(() => ApiClient(baseUrl: 'https://api.example.com'));
  /// ```
  Future<void> register<T extends Object>(
    T Function() factory, {
    String? name,
    ScopeType scope = ScopeType.singleton,
  }) async {
    final cont = await container;
    cont.register<T>(factory, name: name, scope: scope);
  }

  /// Get all dependencies of type T from the container.
  ///
  /// Example:
  /// ```dart
  /// final allServices = getAll<UserService>();
  /// ```
  List<T> getAll<T extends Object>() {
    if (!_isInitialized) {
      throw StateError(
        'IronContainer not initialized. Call await getAll<T>() or use getAllAsync<T>() for automatic initialization.',
      );
    }
    return _globalContainer!.getAll<T>();
  }

  /// Asynchronously get all dependencies of type T from the container.
  /// This method automatically initializes the container if needed.
  Future<List<T>> getAllAsync<T extends Object>() async {
    final cont = await container;
    return cont.getAll<T>();
  }
}
