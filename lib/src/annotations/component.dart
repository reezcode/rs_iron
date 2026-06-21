import '../core/scope_type.dart';

/// Core component annotation - base for all stereotypes
///
/// This is the base annotation for all component stereotypes like
/// [@Service], [@Repository], [@Controller], etc.
///
/// Example:
/// ```dart
/// @Component()
/// class MyComponent {
///   // Your component logic here
/// }
///
/// // With custom scope
/// @Component(scope: ScopeType.factory)
/// class MyFactoryComponent {
///   // New instance created for each injection
/// }
/// ```
class Component {
  const Component({this.value, this.scope = ScopeType.singleton});

  /// Optional value to specify the component name
  final String? value;

  /// The scope type for the bean (default: singleton)
  final ScopeType scope;
}
