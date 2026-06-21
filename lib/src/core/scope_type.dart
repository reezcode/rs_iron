/// Enumeration of bean scope types
///
/// Defines the lifecycle and sharing behavior of beans in the Iron container
/// for mobile applications.
enum ScopeType {
  /// Singleton scope - only one instance is created and shared
  ///
  /// The same instance is returned for every injection request throughout
  /// the app's lifecycle. This is the default scope for services, repositories,
  /// and other shared resources.
  singleton,

  /// Factory scope - a new instance is created for each injection
  ///
  /// A new instance is created every time the bean is requested.
  /// Useful for stateful widgets, view models, or when you need fresh instances
  /// for each use. Perfect for creating new instances of widgets or UI components.
  factory,

  /// Application scope - similar to singleton but explicitly scoped to application
  ///
  /// Similar to singleton but with explicit application-level lifecycle.
  /// Used for app-wide resources and configuration.
  application,

  /// Lazy Singleton scope - instance is created only when first requested
  ///
  /// Unlike standard singleton which is eager, this delays creation until
  /// the bean is actually needed, saving startup time and memory.
  lazySingleton,
}
