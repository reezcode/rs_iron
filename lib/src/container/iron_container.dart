import 'package:collection/collection.dart';

import '../core/bean_definition.dart';
import '../core/injection_context.dart';
import '../core/scope_type.dart';
import '../exceptions/iron_exceptions.dart';

/// The main dependency injection container for rs_iron
///
/// This container provides Spring-like dependency injection capabilities
/// with code generation support for Flutter compatibility.
///
/// Example usage:
/// ```dart
/// final container = IronContainer();
/// await container.scan(); // Uses generated code for scanning
///
/// final userService = container.get<UserService>();
/// ```
class IronContainer {
  IronContainer({
    List<String> activeProfiles = const [],
    Map<String, String> properties = const {},
    bool allowCircularDependencies = false,
    List<String> scanPackages = const [],
  }) : _context = InjectionContext(
         activeProfiles: activeProfiles,
         properties: properties,
       ),
       _allowCircularDependencies = allowCircularDependencies,
       _scanPackages = List.from(scanPackages);

  /// Injection context for managing profiles, properties, and state
  InjectionContext _context;

  /// Bean registry storing all registered bean definitions
  final Map<Type, List<BeanDefinition>> _beanRegistry = {};

  /// Named bean registry for qualified beans
  final Map<String, BeanDefinition> _namedBeanRegistry = {};

  /// Singleton instance cache
  final Map<String, Object> _singletonCache = {};

  /// Whether to allow circular dependencies
  final bool _allowCircularDependencies;

  /// Package patterns to scan for components
  // ignore: unused_field
  final List<String> _scanPackages;

  /// Whether the container has been initialized
  bool _initialized = false;

  /// Scans for components and registers them automatically
  ///
  /// This method will call the generated registration code instead of using mirrors
  Future<void> scan([List<String>? packagePatterns]) async {
    if (_initialized) {
      throw ContainerInitializationException('Container already initialized');
    }

    try {
      // The generated extension should override this method or provide additional setup
      _initialized = true;
    } catch (e) {
      throw ContainerInitializationException('Failed to scan components: $e');
    }
  }

  /// Internal method to mark container as initialized
  void markInitialized() {
    _initialized = true;
  }

  /// Manually registers a bean definition
  void register<T extends Object>(
    T Function() factory, {
    String? name,
    String? qualifier,
    ScopeType scope = ScopeType.singleton,
    List<String> profiles = const [],
    bool isPrimary = false,
  }) {
    if (!_isProfileActive(profiles)) return;

    final beanName = name ?? qualifier ?? T.toString();
    final beanDef = BeanDefinition(
      type: T,
      name: beanName,
      factory: factory,
      scope: scope,
      qualifier: qualifier,
      profiles: profiles,
      isPrimary: isPrimary,
    );

    // Register by type
    _beanRegistry.putIfAbsent(T, () => []).add(beanDef);

    // Register by name if provided
    if (name != null || qualifier != null) {
      _namedBeanRegistry[beanName] = beanDef;
    }
  }

  /// Registers an existing instance as a singleton bean
  void registerInstance<T extends Object>(
    T instance, {
    String? name,
    String? qualifier,
    List<String> profiles = const [],
    bool isPrimary = false,
  }) {
    if (!_isProfileActive(profiles)) return;

    final beanName = name ?? qualifier ?? T.toString();
    final beanDef = BeanDefinition(
      type: T,
      name: beanName,
      factory: () => instance,
      qualifier: qualifier,
      profiles: profiles,
      isPrimary: isPrimary,
    );

    // Cache the instance immediately
    _singletonCache[beanName] = instance;

    // Register the definition
    _beanRegistry.putIfAbsent(T, () => []).add(beanDef);
    if (beanName != T.toString()) {
      _namedBeanRegistry[beanName] = beanDef;
    }
  }

  /// Gets a bean of the specified type
  T get<T extends Object>([String? qualifier]) {
    if (!_initialized) {
      throw ContainerInitializationException(
        'Container not initialized. Call scan() first.',
      );
    }

    if (qualifier != null) {
      return _getByName<T>(qualifier);
    }
    return _getByType<T>();
  }

  /// Gets a bean by name
  Object getByName(String name) {
    if (!_initialized) {
      throw ContainerInitializationException(
        'Container not initialized. Call scan() first.',
      );
    }

    final beanDef = _namedBeanRegistry[name];
    if (beanDef == null) {
      throw BeanNotFoundException(Object, qualifier: name);
    }

    return _createInstance(beanDef, name);
  }

  /// Gets a bean by type and optional qualifier
  T _getByType<T extends Object>() {
    final candidates = _beanRegistry[T];
    if (candidates == null || candidates.isEmpty) {
      throw BeanNotFoundException(T);
    }

    if (candidates.length == 1) {
      final beanDef = candidates.first;
      return _createInstance(beanDef, beanDef.name) as T;
    }

    // Multiple candidates - look for primary
    final primary = candidates.firstWhereOrNull((def) => def.isPrimary);
    if (primary != null) {
      return _createInstance(primary, primary.name) as T;
    }

    throw MultipleBeanFoundException(
      T,
      candidates.map((def) => def.name).toList(),
    );
  }

  /// Gets a bean by name with type checking
  T _getByName<T extends Object>(String name) {
    final instance = getByName(name);
    if (instance is! T) {
      throw BeanNotFoundException(T, qualifier: name);
    }
    return instance;
  }

  /// Creates an instance of a bean, handling singletons and circular dependencies
  Object _createInstance(BeanDefinition beanDef, String key) {
    // Check singleton cache
    final isSingletonLike =
        beanDef.scope == ScopeType.singleton ||
        beanDef.scope == ScopeType.lazySingleton ||
        beanDef.scope == ScopeType.application;

    if (isSingletonLike) {
      final cached = _singletonCache[key];
      if (cached != null) {
        return cached;
      }
    }

    // Check for circular dependencies
    if (_context.isCreating(beanDef.type)) {
      if (!_allowCircularDependencies) {
        throw CircularDependencyException([beanDef.type]);
      }
    }

    _context.pushCreation(beanDef.type);

    try {
      final instance = beanDef.factory() as Object;

      // Cache singletons
      if (isSingletonLike) {
        _singletonCache[key] = instance;
      }

      return instance;
    } finally {
      _context.popCreation(beanDef.type);
    }
  }

  /// Checks if any of the given profiles is active
  bool _isProfileActive(List<String> profiles) {
    if (profiles.isEmpty) return true;
    return profiles.any(_context.activeProfiles.contains);
  }

  /// Checks if a bean of the specified type exists
  bool contains<T extends Object>([String? qualifier]) {
    if (qualifier != null) {
      return _namedBeanRegistry.containsKey(qualifier);
    }
    return _beanRegistry.containsKey(T);
  }

  /// Gets all beans of the specified type
  List<T> getAll<T extends Object>() {
    final candidates = _beanRegistry[T];
    if (candidates == null || candidates.isEmpty) {
      return [];
    }

    return candidates.map((def) {
      final key = def.name;
      return _createInstance(def, key) as T;
    }).toList();
  }

  /// Gets bean names of the specified type
  List<String> getBeanNames<T extends Object>([String? qualifier]) {
    final candidates = _beanRegistry[T];
    if (candidates == null || candidates.isEmpty) {
      return [];
    }

    return candidates
        .map((def) => def.name)
        .where((name) => qualifier == null || name == qualifier)
        .toList();
  }

  /// Clears all singleton instances (useful for testing)
  void clearSingletons() {
    _singletonCache.clear();
  }

  /// Initializes all eager singletons
  void initializeSingletons() {
    for (final beans in _beanRegistry.values) {
      for (final beanDef in beans) {
        if (beanDef.scope == ScopeType.singleton) {
          final key = beanDef.name;
          if (!_singletonCache.containsKey(key)) {
            _createInstance(beanDef, key);
          }
        }
      }
    }
  }

  /// Destroys the container and cleans up resources
  void destroy() {
    _singletonCache.clear();
    _beanRegistry.clear();
    _namedBeanRegistry.clear();
    _initialized = false;
  }

  /// Sets active profiles
  void setActiveProfiles(List<String> profiles) {
    // Create new context with updated profiles
    _context = InjectionContext(
      activeProfiles: profiles,
      properties: _context.properties,
      allowCircularDependencies: _allowCircularDependencies,
    );
  }

  /// Adds properties to the container
  void addProperties(Map<String, String> properties) {
    // Create new context with updated properties
    final newProps = Map<String, String>.from(_context.properties);
    newProps.addAll(properties);
    _context = InjectionContext(
      activeProfiles: _context.activeProfiles,
      properties: newProps,
      allowCircularDependencies: _allowCircularDependencies,
    );
  }

  /// Gets a property value
  String? getProperty(String key) => _context.getProperty(key);

  /// Gets a property value with default
  String getPropertyOrDefault(String key, String defaultValue) =>
      _context.getProperty(key) ?? defaultValue;

  /// Gets the injection context
  InjectionContext get context => _context;
}
