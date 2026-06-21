/// Utility functions for working with types and reflection
///
/// Provides helper functions for type checking, conversion, and reflection
/// operations used throughout the rs_iron framework.
library;

/// Checks if a type is assignable from another type
bool isAssignableFrom(Type target, Type source) =>
    // Basic type equality check - for more complex inheritance checking,
    // you would need compile-time code generation or manual registration
    target == source || target == Object || target == dynamic;

/// Gets the simple name of a type (without library prefix)
String getTypeName(Type type) {
  final typeString = type.toString();
  final lastDot = typeString.lastIndexOf('.');
  return lastDot != -1 ? typeString.substring(lastDot + 1) : typeString;
}

/// Checks if a type is a primitive type
bool isPrimitiveType(Type type) =>
    type == int ||
    type == double ||
    type == String ||
    type == bool ||
    type == num;

/// Checks if a type is a collection type
bool isCollectionType(Type type) {
  final typeString = type.toString();
  return typeString.contains('List<') ||
      typeString.contains('Set<') ||
      typeString.contains('Map<') ||
      typeString.contains('Iterable<');
}

/// Extracts generic type arguments from a collection type
List<Type> getGenericTypeArguments(Type type) => [];
// In a code generation approach, this would be handled by the generator
// For now, return empty list as generic type extraction requires compile-time generation

/// Converts a string to the appropriate type
T? convertStringToType<T>(String value, Type targetType) {
  if (targetType == String) return value as T?;
  if (targetType == int) return int.tryParse(value) as T?;
  if (targetType == double) return double.tryParse(value) as T?;
  if (targetType == bool) {
    final lower = value.toLowerCase();
    if (lower == 'true') return true as T?;
    if (lower == 'false') return false as T?;
    return null;
  }
  return null;
}

/// Checks if a type is nullable
bool isNullableType(Type type) {
  final typeString = type.toString();
  return typeString.endsWith('?');
}

/// Gets the non-nullable version of a type
Type getNonNullableType(Type type) => type;
// In a code generation approach, this would be handled at compile time
// For runtime, we can only work with the type as-is

/// Checks if two types are equivalent for dependency injection purposes
bool areTypesEquivalent(Type type1, Type type2) =>
    getNonNullableType(type1) == getNonNullableType(type2);

/// Gets a default value for a type
Object? getDefaultValue(Type type) {
  if (type == int) return 0;
  if (type == double) return 0.0;
  if (type == String) return '';
  if (type == bool) return false;
  if (isCollectionType(type)) {
    if (type.toString().contains('List')) return <dynamic>[];
    if (type.toString().contains('Set')) return <dynamic>{};
    if (type.toString().contains('Map')) return <dynamic, dynamic>{};
  }
  return null;
}
