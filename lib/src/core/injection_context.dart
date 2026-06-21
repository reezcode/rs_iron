/// Injection context for managing bean creation and dependency resolution
///
/// Provides context information during the bean creation and injection process,
/// including circular dependency detection and active profiles.
class InjectionContext {
  InjectionContext({
    this.activeProfiles = const [],
    this.properties = const {},
    this.allowCircularDependencies = false,
  });

  /// Stack of types currently being created (for circular dependency detection)
  final List<Type> _creationStack = [];

  /// Currently active profiles
  final List<String> activeProfiles;

  /// Environment properties
  final Map<String, String> properties;

  /// Whether to allow circular dependencies
  final bool allowCircularDependencies;

  /// Pushes a type onto the creation stack
  void pushCreation(Type type) {
    if (_creationStack.contains(type) && !allowCircularDependencies) {
      final cycle = [..._creationStack, type];
      throw StateError(
        'Circular dependency detected: ${cycle.join(' -> ')}',
      );
    }
    _creationStack.add(type);
  }

  /// Pops a type from the creation stack
  void popCreation(Type type) {
    if (_creationStack.isNotEmpty && _creationStack.last == type) {
      _creationStack.removeLast();
    }
  }

  /// Checks if a type is currently being created
  bool isCreating(Type type) => _creationStack.contains(type);

  /// Gets a property value
  String? getProperty(String name) => properties[name];

  /// Checks if a property matches the expected value
  bool checkProperty(
    String name,
    String expectedValue, {
    bool matchIfMissing = false,
  }) {
    final value = getProperty(name);
    if (value == null) return matchIfMissing;
    return value == expectedValue;
  }

  /// Creates a copy of this context with additional properties
  InjectionContext copyWith({
    List<String>? activeProfiles,
    Map<String, String>? properties,
    bool? allowCircularDependencies,
  }) =>
      InjectionContext(
        activeProfiles: activeProfiles ?? this.activeProfiles,
        properties: properties ?? this.properties,
        allowCircularDependencies:
            allowCircularDependencies ?? this.allowCircularDependencies,
      );

  @override
  String toString() =>
      'InjectionContext(activeProfiles: $activeProfiles, properties: ${properties.length}, creationStack: $_creationStack)';
}
