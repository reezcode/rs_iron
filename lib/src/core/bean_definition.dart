import '../annotations/conditional.dart';
import 'scope_type.dart';

/// Represents a bean definition in the Iron container
///
/// Contains all metadata about a bean including its type, scope,
/// qualifiers, and creation instructions.
class BeanDefinition {
  BeanDefinition({
    required this.type,
    required this.name,
    required this.factory,
    this.scope = ScopeType.singleton,
    this.qualifier,
    this.profiles = const [],
    this.isPrimary = false,
    this.isLazy = false,
    this.dependencies = const [],
    this.constructorParameters = const [],
    this.injectableFields = const [],
    this.conditions = const [],
    this.initMethod,
    this.destroyMethod,
  });

  /// The runtime type of the bean
  final Type type;

  /// The name/identifier of the bean
  final String name;

  /// The scope of the bean (singleton, factory, application, etc.)
  final ScopeType scope;

  /// Optional qualifier for disambiguation
  final String? qualifier;

  /// Profiles under which this bean is active
  final List<String> profiles;

  /// Whether this bean is primary (preferred when multiple candidates exist)
  final bool isPrimary;

  /// Whether this bean is lazy-initialized
  final bool isLazy;

  /// Factory function to create the bean instance
  final Function factory;

  /// Dependencies required for this bean
  final List<Type> dependencies;

  /// Constructor parameters metadata
  final List<ParameterDefinition> constructorParameters;

  /// Fields that need injection
  final List<FieldDefinition> injectableFields;

  /// Conditional annotations that must be satisfied
  final List<Conditional> conditions;

  /// Initialization method name (if any)
  final String? initMethod;

  /// Destroy method name (if any)
  final String? destroyMethod;

  /// The actual singleton instance (if scope is singleton)
  Object? _singletonInstance;

  /// Gets or creates the bean instance based on scope
  Object getInstance() {
    switch (scope) {
      case ScopeType.singleton ||
          ScopeType.application ||
          ScopeType.lazySingleton:
        return _singletonInstance ??= factory() as Object;
      case ScopeType.factory:
        return factory() as Object;
    }
  }

  /// Clears the singleton instance (useful for testing)
  void clearSingletonInstance() {
    _singletonInstance = null;
  }

  /// Checks if this bean matches the given qualifier
  bool matchesQualifier(String? requestedQualifier) {
    if (requestedQualifier == null) return qualifier == null;
    return qualifier == requestedQualifier;
  }

  /// Checks if this bean is active for the given profiles
  bool isActiveForProfiles(List<String> activeProfiles) {
    if (profiles.isEmpty) return true; // No profile restrictions
    return profiles.any((profile) => activeProfiles.contains(profile));
  }

  @override
  String toString() =>
      'BeanDefinition(type: $type, name: $name, scope: $scope, qualifier: $qualifier)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BeanDefinition &&
        other.type == type &&
        other.name == name &&
        other.qualifier == qualifier;
  }

  @override
  int get hashCode => Object.hash(type, name, qualifier);
}

/// Represents a constructor parameter that needs injection
class ParameterDefinition {
  const ParameterDefinition({
    required this.type,
    required this.name,
    this.isRequired = true,
    this.qualifier,
    this.defaultValue,
  });

  /// The parameter type
  final Type type;

  /// The parameter name
  final String name;

  /// Whether the parameter is required
  final bool isRequired;

  /// Optional qualifier for the parameter
  final String? qualifier;

  /// Default value for the parameter (if any)
  final Object? defaultValue;

  @override
  String toString() =>
      'ParameterDefinition(type: $type, name: $name, required: $isRequired, qualifier: $qualifier)';
}

/// Represents a field that needs injection
class FieldDefinition {
  const FieldDefinition({
    required this.type,
    required this.name,
    this.isRequired = true,
    this.qualifier,
  });

  /// The field type
  final Type type;

  /// The field name
  final String name;

  /// Whether the field is required
  final bool isRequired;

  /// Optional qualifier for the field
  final String? qualifier;

  @override
  String toString() =>
      'FieldDefinition(type: $type, name: $name, required: $isRequired, qualifier: $qualifier)';
}
