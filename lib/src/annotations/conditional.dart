/// Conditional annotations for conditional bean registration
///
/// These annotations allow beans to be registered only when certain
/// conditions are met, similar to Spring Boot's conditional annotations.
library;

/// Base class for all conditional annotations
abstract class Conditional {
  const Conditional();
}

/// Register bean only if the specified property exists and matches the value
///
/// Example:
/// ```dart
/// @Service()
/// @ConditionalOnProperty(
///   name: 'feature.email.enabled',
///   havingValue: 'true',
///   matchIfMissing: false
/// )
/// class EmailService {
///   // Only registered if feature.email.enabled=true
/// }
/// ```
class ConditionalOnProperty extends Conditional {
  const ConditionalOnProperty({
    required this.name,
    this.havingValue = 'true',
    this.matchIfMissing = false,
  });

  /// The property name to check
  final String name;

  /// The expected value (default: 'true')
  final String havingValue;

  /// Whether to match if the property is missing (default: false)
  final bool matchIfMissing;
}

/// Register bean only if the specified class is present on the classpath
///
/// Example:
/// ```dart
/// @Service()
/// @ConditionalOnClass('package:sqflite/sqflite.dart')
/// class SQLiteUserRepository implements UserRepository {
///   // Only registered if sqflite package is available
/// }
/// ```
class ConditionalOnClass extends Conditional {
  const ConditionalOnClass(this.className);

  /// The class/library name to check for
  final String className;
}

/// Register bean only if no bean of the specified type exists
///
/// Example:
/// ```dart
/// @Service()
/// @ConditionalOnMissingBean(UserService)
/// class DefaultUserService implements UserService {
///   // Only registered if no other UserService bean exists
/// }
/// ```
class ConditionalOnMissingBean extends Conditional {
  const ConditionalOnMissingBean(this.type, {this.qualifier});

  /// The type to check for
  final Type type;

  /// Optional qualifier to check for
  final String? qualifier;
}

/// Register bean only if a bean of the specified type exists
///
/// Example:
/// ```dart
/// @Service()
/// @ConditionalOnBean(DatabaseService)
/// class UserCacheService {
///   // Only registered if DatabaseService bean exists
/// }
/// ```
class ConditionalOnBean extends Conditional {
  const ConditionalOnBean(this.type, {this.qualifier});

  /// The type to check for
  final Type type;

  /// Optional qualifier to check for
  final String? qualifier;
}
