import '../core/scope_type.dart';
import 'component.dart';

/// Controller annotation for marking controller and handler components.
/// Controllers typically handle user interactions, events, or coordinate UI logic.
///
/// Example:
/// ```dart
/// @Controller()
/// class UserController {
///   final UserService userService;
///
///   UserController(this.userService);
/// }
///
/// // With custom scope
/// @Controller(scope: ScopeType.factory)
/// class EventScopedController {
///   // New instance for each event or interaction
/// }
/// ```
class Controller extends Component {
  const Controller({super.value, super.scope = ScopeType.singleton});
}
