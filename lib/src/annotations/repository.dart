import '../core/scope_type.dart';
import 'component.dart';

/// Repository layer annotation - indicates data access layer components
///
/// This annotation is a specialization of [@Component] for classes that
/// provide data access functionality, typically interacting with databases
/// or external data sources.
///
/// Example:
/// ```dart
/// @Repository()
/// class UserRepository {
///   Future<User?> findById(int id) async {
///     // Database access logic here
///   }
///
///   Future<void> save(User user) async {
///     // Save logic here
///   }
/// }
///
/// // With custom scope
/// @Repository(scope: ScopeType.factory)
/// class ConnectionSpecificRepository {
///   // New instance for each injection
/// }
/// ```
class Repository extends Component {
  const Repository({String? value, ScopeType scope = ScopeType.singleton})
      : super(value: value, scope: scope);
}
