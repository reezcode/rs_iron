/// Qualifier annotation for specific bean selection
///
/// When multiple beans of the same type are available, use [@Qualifier]
/// to specify which specific bean should be injected.
///
/// Example:
/// ```dart
/// @Service()
/// @Qualifier('primary')
/// class PrimaryUserService implements UserService { }
///
/// @Service()
/// @Qualifier('secondary')
/// class SecondaryUserService implements UserService { }
///
/// @Component()
/// class UserController {
///   @Autowired()
///   @Qualifier('primary')
///   late UserService userService;
/// }
/// ```
class Qualifier {
  const Qualifier(this.value);

  /// The qualifier name to distinguish beans
  final String value;
}
