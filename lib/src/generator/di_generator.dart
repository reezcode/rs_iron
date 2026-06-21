import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../core/scope_type.dart';

/// Code generator that scans for DI annotations and generates registration code
class DiGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final components = extractComponentsFromLibrary(library);

    if (components.isEmpty) {
      return '';
    }

    return _generateRegistrationCode(components, buildStep);
  }

  /// Extracts component information from a library - exposed for use by aggregating builder
  List<ComponentInfo> extractComponentsFromLibrary(LibraryReader library) {
    final components = <ComponentInfo>[];

    // Scan all classes in the library
    for (final element in library.allElements) {
      if (element is ClassElement && !element.isAbstract) {
        if (_hasComponentAnnotation(element)) {
          final info = _extractComponentInfo(element);
          components.add(info);
        }
      }
    }

    return components;
  }

  bool _hasComponentAnnotation(ClassElement element) =>
      element.metadata.annotations.any((meta) {
        final annotationName = meta.element?.displayName;
        return annotationName == 'Service' ||
            annotationName == 'Repository' ||
            annotationName == 'Controller' ||
            annotationName == 'Component' ||
            annotationName == 'DataSource' ||
            annotationName == 'UseCase';
      });

  ComponentInfo _extractComponentInfo(ClassElement element) {
    String componentType = 'Component';
    String? beanName;
    ScopeType scope = ScopeType.singleton; // Default scope
    final List<String> profiles = [];

    // Extract annotation information
    for (final meta in element.metadata.annotations) {
      final annotationType = meta.element?.displayName;

      switch (annotationType) {
        case 'Service':
          componentType = 'Service';
          scope = _extractScopeFromAnnotation(meta) ?? ScopeType.singleton;
          break;
        case 'Repository':
          componentType = 'Repository';
          scope = _extractScopeFromAnnotation(meta) ?? ScopeType.singleton;
          break;
        case 'Controller':
          componentType = 'Controller';
          scope = _extractScopeFromAnnotation(meta) ?? ScopeType.singleton;
          break;
        case 'Component':
          componentType = 'Component';
          scope = _extractScopeFromAnnotation(meta) ?? ScopeType.singleton;
          break;
        case 'DataSource':
          componentType = 'DataSource';
          scope = _extractScopeFromAnnotation(meta) ?? ScopeType.singleton;
          break;
        case 'UseCase':
          componentType = 'UseCase';
          scope = _extractScopeFromAnnotation(meta) ?? ScopeType.singleton;
          break;
        case 'Scope':
          scope = _extractScope(meta);
          break;
        case 'Qualifier':
          beanName = _extractQualifierValue(meta);
          break;
      }
    }

    // Extract constructor dependencies
    final constructorDeps = _extractConstructorDependencies(element);

    // Extract autowired field dependencies
    final fieldDeps = _extractAutowiredFields(element);

    return ComponentInfo(
      className: element.displayName,
      componentType: componentType,
      beanName: beanName,
      scope: scope,
      profiles: profiles,
      constructorDependencies: constructorDeps,
      autowiredFields: fieldDeps,
    );
  }

  List<DependencyInfo> _extractConstructorDependencies(ClassElement element) {
    final dependencies = <DependencyInfo>[];

    // Find the constructor
    final constructor =
        element.constructors
            .where(
              (c) => c.displayName.isEmpty, // Default constructor
            )
            .firstOrNull ??
        (element.constructors.isNotEmpty ? element.constructors.first : null);

    if (constructor != null) {
      // Extract constructor parameters as dependencies
      for (final param in constructor.formalParameters) {
        dependencies.add(
          DependencyInfo(
            type: param.type.getDisplayString(withNullability: false),
            name: param.displayName,
            isRequired: param.isRequired,
            qualifier: _extractQualifier(param),
          ),
        );
      }
    }

    return dependencies;
  }

  List<FieldDependencyInfo> _extractAutowiredFields(ClassElement element) {
    final fields = <FieldDependencyInfo>[];

    for (final field in element.fields) {
      // Check if field has @Autowired annotation
      final hasAutowired = field.metadata.annotations.any(
        (meta) => meta.element?.enclosingElement?.displayName == 'Autowired',
      );

      if (hasAutowired) {
        final qualifier = _extractFieldQualifier(field);
        fields.add(
          FieldDependencyInfo(
            fieldName: field.displayName,
            type: field.type.getDisplayString(withNullability: false),
            qualifier: qualifier,
            isNullable: field.type
                .getDisplayString(withNullability: true)
                .endsWith('?'),
          ),
        );
      }
    }

    return fields;
  }

  String? _extractFieldQualifier(FieldElement field) {
    for (final meta in field.metadata.annotations) {
      if (meta.element?.enclosingElement?.displayName == 'Qualifier') {
        // Extract qualifier value
        return 'primary'; // Simplified implementation
      }
    }
    return null;
  }

  String? _extractQualifierValue(ElementAnnotation meta) {
    // Extract qualifier value from annotation
    return null; // Simplified implementation
  }

  ScopeType _extractScope(ElementAnnotation meta) {
    // Extract scope from annotation value
    return ScopeType.singleton; // Default implementation
  }

  /// Extract scope from component annotation (Service, Repository, etc.)
  ScopeType? _extractScopeFromAnnotation(ElementAnnotation meta) {
    try {
      // Get the annotation instance
      final annotationValue = meta.computeConstantValue();
      if (annotationValue == null) return null;

      // Look for scope field in the annotation
      final scopeField = annotationValue.getField('scope');
      if (scopeField == null) return null;

      // Get the scope value
      final scopeIndex = scopeField.getField('index')?.toIntValue();
      if (scopeIndex == null) return null;

      // Map index to ScopeType
      if (scopeIndex >= 0 && scopeIndex < ScopeType.values.length) {
        return ScopeType.values[scopeIndex];
      }
      return ScopeType.singleton;
    } catch (e) {
      // If extraction fails, return null to use default
      return null;
    }
  }

  String? _extractQualifier(Element param) {
    // Check for @Qualifier annotation
    for (final meta in param.metadata.annotations) {
      if (meta.element?.enclosingElement?.displayName == 'Qualifier') {
        // Extract qualifier value
        return null; // Simplified implementation
      }
    }
    return null;
  }

  String _generateRegistrationCode(
    List<ComponentInfo> components,
    BuildStep buildStep,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by rs_iron code generator');
    buffer.writeln();
    buffer.writeln('import \'package:rs_iron/rs_iron.dart\';');

    // Import the source file
    final sourceFileName = buildStep.inputId.path.split('/').last;
    buffer.writeln('import \'$sourceFileName\';');

    buffer.writeln();
    buffer.writeln('extension GeneratedDependencies on IronContainer {');
    buffer.writeln('  /// Register all discovered components');
    buffer.writeln('  void registerGeneratedDependencies() {');

    for (final component in components) {
      _generateComponentRegistration(buffer, component);
    }

    buffer.writeln('    // Initialize eager singletons');
    buffer.writeln('    initializeSingletons();');

    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  void _generateComponentRegistration(
    StringBuffer buffer,
    ComponentInfo component,
  ) {
    buffer.writeln('    // Register ${component.className}');
    buffer.writeln('    register<${component.className}>(');

    // Generate factory function
    if (component.constructorDependencies.isNotEmpty ||
        component.autowiredFields.isNotEmpty) {
      buffer.writeln('      () {');

      // Constructor injection
      if (component.constructorDependencies.isNotEmpty) {
        final args = component.constructorDependencies
            .map((dep) {
              if (dep.qualifier != null) {
                return 'get<${dep.type}>(\'${dep.qualifier}\')';
              }
              return 'get<${dep.type}>()';
            })
            .join(', ');
        buffer.writeln(
          '        final instance = ${component.className}($args);',
        );
      } else {
        buffer.writeln('        final instance = ${component.className}();');
      }

      // Handle autowired fields
      for (final field in component.autowiredFields) {
        if (field.qualifier != null) {
          buffer.writeln(
            '        instance.${field.fieldName} = get<${field.type}>(\'${field.qualifier}\');',
          );
        } else {
          buffer.writeln(
            '        instance.${field.fieldName} = get<${field.type}>();',
          );
        }
      }

      buffer.writeln('        return instance;');
      buffer.writeln('      },');
    } else {
      buffer.writeln('      () => ${component.className}(),');
    }

    if (component.beanName != null) {
      buffer.writeln('      name: \'${component.beanName}\',');
    }
    buffer.writeln('      scope: ScopeType.${component.scope.name},');
    buffer.writeln('    );');
    buffer.writeln();
  }
}

class ComponentInfo {
  ComponentInfo({
    required this.className,
    required this.componentType,
    this.beanName,
    required this.scope,
    required this.profiles,
    this.dependencies = const [],
    this.constructorDependencies = const [],
    this.autowiredFields = const [],
  });
  final String className;
  final String componentType;
  final String? beanName;
  final ScopeType scope;
  final List<String> profiles;
  final List<DependencyInfo> dependencies;
  final List<DependencyInfo> constructorDependencies;
  final List<FieldDependencyInfo> autowiredFields;
}

class DependencyInfo {
  DependencyInfo({
    required this.type,
    required this.name,
    required this.isRequired,
    this.qualifier,
  });
  final String type;
  final String name;
  final bool isRequired;
  final String? qualifier;
}

class FieldDependencyInfo {
  FieldDependencyInfo({
    required this.fieldName,
    required this.type,
    this.qualifier,
    required this.isNullable,
  });
  final String fieldName;
  final String type;
  final String? qualifier;
  final bool isNullable;
}
