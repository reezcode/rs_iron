/// Bean method annotation
///
/// Indicates that a method produces a bean to be managed by the rs_iron container.
/// This annotation is typically used within [@Configuration] classes.
///
/// Example:
/// ```dart
/// @Configuration()
/// class AppConfig {
///   @Bean()
///   @Singleton()
///   HttpClient createHttpClient() {
///     return HttpClient()..timeout = Duration(seconds: 30);
///   }
///
///   @Bean()
///   @Qualifier('logger')
///   Logger createLogger() {
///     return Logger('app');
///   }
/// }
/// ```
class Bean {
  const Bean({this.name, this.initMethod, this.destroyMethod});

  /// Optional name for the bean
  final String? name;

  /// Optional initialization method to call after instantiation
  final String? initMethod;

  /// Optional destroy method to call before disposal
  final String? destroyMethod;
}
