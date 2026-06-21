/// Configuration class annotation
///
/// Indicates that a class contains one or more [@Bean] methods and may be
/// processed by the rs_iron container to generate bean definitions and service
/// requests for those beans at runtime.
///
/// Example:
/// ```dart
/// @Configuration()
/// class DatabaseConfig {
///   @Bean()
///   @Singleton()
///   Database createDatabase() {
///     return Database(connectionString: Environment.dbUrl);
///   }
///
///   @Bean()
///   @Qualifier('cache')
///   Cache createCache() {
///     return RedisCache();
///   }
/// }
/// ```
class Configuration {
  const Configuration([this.value]);

  /// Optional value to specify the configuration name
  final String? value;
}
