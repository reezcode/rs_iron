/// Profile annotation for environment-specific beans
///
/// Allows conditional registration of beans based on active profiles.
/// Useful for having different implementations for different environments
/// (development, testing, production).
///
/// Example:
/// ```dart
/// @Service()
/// @Profile('development')
/// class DevEmailService implements EmailService {
///   void sendEmail(String to, String subject, String body) {
///     print('DEV: Sending email to $to: $subject');
///   }
/// }
///
/// @Service()
/// @Profile('production')
/// class ProdEmailService implements EmailService {
///   void sendEmail(String to, String subject, String body) {
///     // Real email sending logic
///   }
/// }
///
/// // Usage with multiple profiles
/// @Profile.multiple(['test', 'integration'])
/// @Service()
/// class TestDatabaseService implements DatabaseService { }
/// ```
class Profile {
  /// Creates a profile annotation with a single profile
  const Profile(this.profile) : profiles = null;

  /// Creates a profile annotation with multiple profiles
  const Profile.multiple(this.profiles) : profile = null;

  /// The profile name for single profile annotations
  final String? profile;

  /// The profile names for multiple profile annotations
  final List<String>? profiles;

  /// Gets all profiles as a list
  List<String> getProfiles() {
    if (profile != null) return [profile!];
    if (profiles != null) return profiles!;
    return [];
  }
}
