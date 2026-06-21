import '../core/scope_type.dart';

/// Scope annotation for controlling bean lifecycle
///
/// Specifies the scope of a bean, determining when and how many instances
/// are created.
///
/// Example:
/// ```dart
/// @Service()
/// @Scope(ScopeType.singleton)
/// class ConfigurationService {
///   // Single instance shared across the application
/// }
///
/// @Service()
/// @Scope(ScopeType.factory)
/// class RequestProcessor {
///   // New instance created for each injection
/// }
/// ```
class Scope {
  const Scope(this.value);

  /// The scope type for the bean
  final ScopeType value;
}

/// Convenience annotation for singleton scope
///
/// Equivalent to @Scope(ScopeType.singleton)
class Singleton extends Scope {
  const Singleton() : super(ScopeType.singleton);
}

/// Convenience annotation for factory scope
///
/// Equivalent to @Scope(ScopeType.factory)
class Factory extends Scope {
  const Factory() : super(ScopeType.factory);
}

/// Convenience annotation for lazy singleton scope
///
/// Equivalent to @Scope(ScopeType.lazySingleton)
class LazySingleton extends Scope {
  const LazySingleton() : super(ScopeType.lazySingleton);
}
