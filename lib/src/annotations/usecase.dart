import '../core/scope_type.dart';
import 'component.dart';

/// UseCase layer annotation - indicates application use case components
///
/// This annotation is a specialization of [@Component] for classes that
/// contain specific business use cases or application logic, following
/// Clean Architecture principles.
///
/// Use cases encapsulate application-specific business rules and orchestrate
/// the flow of data to and from entities and repositories.
///
/// Example:
/// ```dart
/// @UseCase()
/// class GetUserUseCase {
///   @Autowired()
///   late UserRepository userRepository;
///
///   Future<User?> execute(String userId) async {
///     return await userRepository.findById(userId);
///   }
/// }
///
/// // With custom scope
/// @UseCase(scope: ScopeType.factory)
/// class StatefulUseCase {
///   // New instance for each execution
/// }
/// ```
class UseCase extends Component {
  const UseCase({String? value, ScopeType scope = ScopeType.singleton})
      : super(value: value, scope: scope);
}
