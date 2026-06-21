/// Autowired annotation for automatic dependency injection
///
/// Marks a field, setter method, or constructor parameter for automatic
/// dependency injection by the rs_iron container.
///
/// Example:
/// ```dart
/// @Service()
/// class UserService {
///   @Autowired()
///   late UserRepository userRepository;
///
///   @Autowired()
///   late Logger logger;
///
///   // Constructor injection
///   UserService(@Autowired() this.emailService);
///
///   final EmailService emailService;
/// }
/// ```
class Autowired {
  const Autowired({this.required = true});

  /// Whether the dependency is required (default: true)
  /// If false and no bean is found, null will be injected
  final bool required;
}
