/// Base exception class for all rs_iron related exceptions
abstract class IronException implements Exception {
  const IronException(this.message);
  final String message;

  @override
  String toString() => 'IronException: $message';
}

/// Exception thrown when a required bean cannot be found
class BeanNotFoundException extends IronException {
  BeanNotFoundException(this.type, {this.qualifier})
    : super(_createMessage(type, qualifier));
  final Type type;
  final String? qualifier;

  static String _createMessage(Type type, String? qualifier) {
    final qualifierPart = qualifier != null
        ? ' with qualifier \'$qualifier\''
        : '';
    return 'No bean of type \'$type\'$qualifierPart found';
  }
}

/// Exception thrown when multiple beans are found and no primary is specified
class MultipleBeanFoundException extends IronException {
  MultipleBeanFoundException(this.type, this.beanNames, {this.qualifier})
    : super(_createMessage(type, beanNames, qualifier));
  final Type type;
  final String? qualifier;
  final List<String> beanNames;

  static String _createMessage(
    Type type,
    List<String> beanNames,
    String? qualifier,
  ) {
    final qualifierPart = qualifier != null
        ? ' with qualifier \'$qualifier\''
        : '';
    return 'Multiple beans of type \'$type\'$qualifierPart found: ${beanNames.join(', ')}. '
        'Consider using @Primary or @Qualifier to disambiguate.';
  }
}

/// Exception thrown when circular dependencies are detected
class CircularDependencyException extends IronException {
  CircularDependencyException(this.dependencyChain)
    : super(_createMessage(dependencyChain));
  final List<Type> dependencyChain;

  static String _createMessage(List<Type> chain) =>
      'Circular dependency detected: ${chain.join(' -> ')}';
}

/// Exception thrown when bean creation fails
class BeanCreationException extends IronException {
  BeanCreationException(this.type, String message, {this.beanName, this.cause})
    : super(_createMessage(type, message, beanName));
  final Type type;
  final String? beanName;
  final Object? cause;

  static String _createMessage(Type type, String message, String? beanName) {
    final namePart = beanName != null ? ' (\'$beanName\')' : '';
    return 'Failed to create bean of type \'$type\'$namePart: $message';
  }
}

/// Exception thrown when dependency injection fails
class InjectionException extends IronException {
  InjectionException(
    this.targetType,
    this.fieldName,
    String message, {
    this.cause,
  }) : super(_createMessage(targetType, fieldName, message));
  final Type targetType;
  final String fieldName;
  final Object? cause;

  static String _createMessage(
    Type targetType,
    String fieldName,
    String message,
  ) => 'Failed to inject field \'$fieldName\' in \'$targetType\': $message';
}

/// Exception thrown when bean configuration is invalid
class InvalidBeanConfigurationException extends IronException {
  InvalidBeanConfigurationException(this.type, String message, {this.beanName})
    : super(_createMessage(type, message, beanName));
  final Type type;
  final String? beanName;

  static String _createMessage(Type type, String message, String? beanName) {
    final namePart = beanName != null ? ' (\'$beanName\')' : '';
    return 'Invalid configuration for bean of type \'$type\'$namePart: $message';
  }
}

/// Exception thrown when conditional evaluation fails
class ConditionalEvaluationException extends IronException {
  ConditionalEvaluationException(this.type, this.conditionType, String message)
    : super(
        'Failed to evaluate condition \'$conditionType\' for bean \'$type\': $message',
      );
  final Type type;
  final String conditionType;
}

/// Exception thrown when container initialization fails
class ContainerInitializationException extends IronException {
  ContainerInitializationException(super.message, {this.cause});
  final Object? cause;
}
