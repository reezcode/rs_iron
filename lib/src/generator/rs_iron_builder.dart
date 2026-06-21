import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

import '../core/scope_type.dart';

/// ComponentInfo
class ComponentInfo {
  ComponentInfo({
    required this.className,
    required this.componentType,
    this.beanName,
    required this.scope,
    required this.profiles,
    this.constructorDependencies = const [],
    this.autowiredFields = const [],
    this.interfaceType,
  });
  final String className;
  final String componentType;
  final String? beanName;
  final ScopeType scope;
  final List<String> profiles;
  final List<DependencyInfo> constructorDependencies;
  final List<FieldDependencyInfo> autowiredFields;
  final String? interfaceType;
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

/// Extended ComponentInfo that includes source file information
class ComponentInfoWithSource extends ComponentInfo {
  ComponentInfoWithSource({
    required super.className,
    required super.componentType,
    super.beanName,
    required super.scope,
    required super.profiles,
    super.constructorDependencies = const [],
    super.autowiredFields = const [],
    super.interfaceType,
    required this.sourceFile,
  });
  final String sourceFile;
}

/// Mirrors-free aggregating builder using only analyzer package
class IronAggregatingBuilder implements Builder {
  const IronAggregatingBuilder();

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.rs_iron.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // First check if this is a file we should skip entirely
    if (_shouldSkipAtAssetLevel(buildStep.inputId)) {
      return;
    }

    // Check if this might be a part file before trying to get the library
    try {
      final content = await buildStep.readAsString(buildStep.inputId);
      if (_isPartFileOrInvalidLibrary(content)) {
        return;
      }
    } catch (e) {
      // If we can't read the file, skip it
      return;
    }

    // Only now try to access the library
    LibraryElement library;
    try {
      library = await buildStep.inputLibrary;
    } catch (e) {
      // If it fails to resolve as a library, skip it silently
      return;
    }

    // Check if this file has @IronEntryPoint annotation
    final hasEntryPoint = await _hasEntryPointAnnotation(library);
    if (!hasEntryPoint) {
      // Skip files without entry point annotation
      return;
    }

    log.info('Found @IronEntryPoint in ${buildStep.inputId.path}');

    // Collect all components from all Dart files in the project
    final allComponents = await _collectAllComponents(buildStep);

    if (allComponents.isEmpty) {
      log.warning('No DI components found in the project');
      return;
    }

    log.info('Found ${allComponents.length} DI components to register');

    // Generate consolidated registration code
    final code = _generateConsolidatedCode(allComponents, buildStep.inputId);

    // Write the consolidated file
    final outputId = buildStep.inputId.changeExtension('.rs_iron.dart');
    await buildStep.writeAsString(outputId, code);

    log.info('Generated consolidated DI file: ${outputId.path}');
  }

  Future<bool> _hasEntryPointAnnotation(LibraryElement library) async {
    for (final element in library.classes) {
      final hasEntryPoint = element.metadata.annotations.any(
        (meta) => meta.element?.displayName == 'IronEntryPoint',
      );
      if (hasEntryPoint) {
        return true;
      }
    }
    return false;
  }

  Future<List<ComponentInfoWithSource>> _collectAllComponents(
    BuildStep buildStep,
  ) async {
    final allComponents = <ComponentInfoWithSource>[];

    // Find all Dart files in the project - both lib and example directories
    // Use more specific patterns to avoid part files
    final dartFilesLib = Glob('lib/**.dart');
    final dartFilesExample = Glob('example/**.dart');

    // Process lib files
    await for (final assetId in buildStep.findAssets(dartFilesLib)) {
      // Skip files that are known to be problematic at the asset level
      if (_shouldSkipAtAssetLevel(assetId)) {
        continue;
      }
      await _processFile(assetId, buildStep, allComponents);
    }

    // Process example files
    await for (final assetId in buildStep.findAssets(dartFilesExample)) {
      // Skip files that are known to be problematic at the asset level
      if (_shouldSkipAtAssetLevel(assetId)) {
        continue;
      }
      await _processFile(assetId, buildStep, allComponents);
    }

    log.info('Total components found: ${allComponents.length}');
    return allComponents;
  }

  /// Skip files at the asset level before any processing
  bool _shouldSkipAtAssetLevel(AssetId assetId) {
    final path = assetId.path;

    // Skip generated files
    if (path.endsWith('.g.dart') ||
        path.endsWith('.freezed.dart') ||
        path.endsWith('.rs_iron.dart') ||
        path.endsWith('.config.dart') ||
        path.endsWith('.chopper.dart') ||
        path.endsWith('.gr.dart') ||
        path.endsWith('.mocks.dart') ||
        path.endsWith('.part.dart')) {
      return true;
    }

    // Skip common BLoC part files by pattern
    if (path.endsWith('_state.dart') || path.endsWith('_event.dart')) {
      return true;
    }

    // Skip files in build directories
    if (path.contains('/build/') || path.contains('\\build\\')) {
      return true;
    }

    return false;
  }

  Future<void> _processFile(
    AssetId assetId,
    BuildStep buildStep,
    List<ComponentInfoWithSource> allComponents,
  ) async {
    try {
      // First level filtering based on file path
      if (_shouldSkipFile(assetId.path)) {
        return;
      }

      // Read file content to perform additional checks BEFORE trying to get library
      String content;
      try {
        content = await buildStep.readAsString(assetId);
      } catch (e) {
        return;
      }

      // Content-based filtering - this must happen BEFORE calling resolver.libraryFor
      if (_isPartFileOrInvalidLibrary(content)) {
        return;
      }

      // Only try to get the library AFTER we've confirmed it's not a part file
      LibraryElement library;
      try {
        library = await buildStep.resolver.libraryFor(assetId);
      } catch (e) {
        // Even with our filtering, some files might still not be valid libraries
        return;
      }

      // Extract components using only analyzer package
      final components = _extractComponentsFromLibrary(library);

      // Add source file information to each component
      final componentsWithSource = components
          .map(
            (c) => ComponentInfoWithSource(
              className: c.className,
              componentType: c.componentType,
              beanName: c.beanName,
              scope: c.scope,
              profiles: c.profiles,
              constructorDependencies: c.constructorDependencies,
              autowiredFields: c.autowiredFields,
              interfaceType: c.interfaceType,
              sourceFile: assetId.path,
            ),
          )
          .toList();

      allComponents.addAll(componentsWithSource);

      if (components.isNotEmpty) {
        log.info('Found ${components.length} components in ${assetId.path}');
        for (final component in components) {
          log.info('  - ${component.className} (${component.componentType})');
        }
      }
    } catch (e) {
      log.warning('Failed to process ${assetId.path}: $e');
    }
  }

  List<ComponentInfo> _extractComponentsFromLibrary(LibraryElement library) {
    final components = <ComponentInfo>[];

    // Scan all classes in the library
    for (final element in library.classes) {
      if (!element.isAbstract) {
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
    String? interfaceType;

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
        case 'UseCase':
          componentType = 'UseCase';
          scope = _extractScopeFromAnnotation(meta) ?? ScopeType.singleton;
          break;
        case 'DataSource':
          componentType = 'DataSource';
          scope = _extractScopeFromAnnotation(meta) ?? ScopeType.singleton;
          break;
        case 'Component':
          componentType = 'Component';
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

    // Detect interface implementation
    // Look for interfaces that this class implements
    for (final interface in element.interfaces) {
      final interfaceName = interface.element.displayName;

      // Skip common Dart interfaces and framework interfaces
      if (!_isFrameworkInterface(interfaceName)) {
        interfaceType = interfaceName;
        break; // Use the first non-framework interface found
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
      interfaceType: interfaceType,
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
    // Extract scope from @Scope annotation
    return ScopeType.singleton; // Default implementation
  }

  /// Extract scope from component annotation (Service, Repository, etc.)
  ScopeType? _extractScopeFromAnnotation(ElementAnnotation meta) {
    try {
      // Get the annotation instance
      final annotationValue = meta.computeConstantValue();
      if (annotationValue == null) {
        return null;
      }

      // Look for scope field in the annotation
      final scopeField = annotationValue.getField('scope');
      if (scopeField == null || scopeField.isNull) {
        return null;
      }

      // Get the enum index
      final scopeIndex = scopeField.getField('index')?.toIntValue();
      if (scopeIndex != null) {
        // Map index to ScopeType
        switch (scopeIndex) {
          case 0:
            return ScopeType.singleton;
          case 1:
            return ScopeType.factory;
          case 2:
            return ScopeType.application;
          default:
            return ScopeType.singleton;
        }
      }

      // Also try to get the name directly
      final scopeName = scopeField.getField('name')?.toStringValue();
      if (scopeName != null) {
        switch (scopeName) {
          case 'singleton':
            return ScopeType.singleton;
          case 'factory':
            return ScopeType.factory;
          case 'application':
            return ScopeType.application;
          default:
            return ScopeType.singleton;
        }
      }

      return null;
    } catch (e) {
      // If extraction fails, return null to use default
      log.warning('Failed to extract scope from annotation: $e');
      return null;
    }
  }

  String? _extractQualifier(FormalParameterElement param) {
    // Check for @Qualifier annotation
    for (final meta in param.metadata.annotations) {
      if (meta.element?.enclosingElement?.displayName == 'Qualifier') {
        // Extract qualifier value
        return null; // Simplified implementation
      }
    }
    return null;
  }

  String _generateConsolidatedCode(
    List<ComponentInfoWithSource> components,
    AssetId inputId,
  ) {
    final buffer = StringBuffer();

    // Generate header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln();
    buffer.writeln(
      '// **************************************************************************',
    );
    buffer.writeln('// RsIron Generator');
    buffer.writeln(
      '// **************************************************************************',
    );
    buffer.writeln();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by rs_iron code generator');
    buffer.writeln('// Entry point: ${inputId.path}');
    buffer.writeln('// Components found: ${components.length}');
    buffer.writeln();

    // Add imports
    buffer.writeln("import 'package:rs_iron/rs_iron.dart';");
    // Add imports for the DI framework
    buffer.writeln();

    // Add imports for all files that contain components
    final importPaths = <String>{};

    // Add source files for all components
    for (final component in components) {
      if (component.sourceFile.isNotEmpty) {
        importPaths.add(component.sourceFile);
      }
    }

    // For interface-based DI, we need to also import interface files
    // Handle multiple patterns for interface/implementation separation:
    // 1. Same directory: user_repository_impl.dart -> user_repository.dart
    // 2. Data/Domain separation: data/repositories/user_repository_impl.dart -> domain/repositories/user_repository.dart
    // 3. Implementation in subdirectory: repositories/impl/user_repository_impl.dart -> repositories/user_repository.dart
    for (final component in components) {
      if (component.interfaceType != null) {
        final interfaceImportPath = _findInterfaceImportPath(
          component,
          components,
        );
        if (interfaceImportPath != null) {
          importPaths.add(interfaceImportPath);
        }
      }
    }

    final sortedImportPaths = importPaths.toList()..sort();

    for (final importPath in sortedImportPaths) {
      // Convert absolute path to relative import
      final relativePath = _makeRelativeImport(inputId.path, importPath);
      buffer.writeln("import '$relativePath';");
    }
    buffer.writeln();

    // Generate extension with all registrations
    buffer.writeln('extension GeneratedDependencies on IronContainer {');
    buffer.writeln(
      '  /// Register all discovered components from the entire project',
    );
    buffer.writeln('  void registerGeneratedDependencies() {');

    // Sort components by dependency order (dependencies first)
    final sortedComponents = _sortComponentsByDependencies(components);

    for (final component in sortedComponents) {
      buffer.writeln('    // Register ${component.className}');
      buffer.writeln(_generateComponentRegistration(component));
      buffer.writeln();
    }

    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();

    // Generate convenience mixin extension with auto-generated getters
    _generateIronConvenienceMixin(buffer, components);

    return buffer.toString();
  }

  /// Generate convenience mixin extension with auto-generated getters for each component
  void _generateIronConvenienceMixin(
    StringBuffer buffer,
    List<ComponentInfoWithSource> components,
  ) {
    buffer.writeln(
      '/// Convenience mixin that provides direct property access to DI components.',
    );
    buffer.writeln(
      '/// Add this mixin to your StatefulWidget states for easy dependency access.',
    );
    buffer.writeln('///');
    buffer.writeln('/// Example:');
    buffer.writeln('/// ```dart');
    buffer.writeln(
      '/// class _MyWidgetState extends State<MyWidget> with IronCore, IronMixin {',
    );
    buffer.writeln('///   @override');
    buffer.writeln('///   Widget build(BuildContext context) {');
    buffer.writeln(
      '///     return Text(userService.getCurrentUser()); // Ironct access!',
    );
    buffer.writeln('///   }');
    buffer.writeln('/// }');
    buffer.writeln('/// ```');
    buffer.writeln('mixin IronMixin {');
    buffer.writeln();

    // Generate getter for each component
    for (final component in components) {
      final registrationType = component.interfaceType ?? component.className;
      final propertyName = _getPropertyName(registrationType);

      buffer.writeln('  /// Get $registrationType instance from DI container');
      buffer.writeln('  $registrationType get $propertyName {');
      buffer.writeln('    if (this is IronCore) {');
      buffer.writeln(
        '      return (this as IronCore).get<$registrationType>();',
      );
      buffer.writeln('    }');
      buffer.writeln('    throw StateError(');
      buffer.writeln('      \'IronMixin must be used with IronCore. \'');
      buffer.writeln(
        '      \'Add "with IronCore, IronMixin" to your class.\',',
      );
      buffer.writeln('    );');
      buffer.writeln('  }');
      buffer.writeln();

      // Also generate async getter
      buffer.writeln(
        '  /// Get $registrationType instance from DI container (async)',
      );
      buffer.writeln(
        '  Future<$registrationType> get ${propertyName}Async async {',
      );
      buffer.writeln('    if (this is IronCore) {');
      buffer.writeln(
        '      return (this as IronCore).getAsync<$registrationType>();',
      );
      buffer.writeln('    }');
      buffer.writeln('    throw StateError(');
      buffer.writeln('      \'IronMixin must be used with IronCore. \'');
      buffer.writeln(
        '      \'Add "with IronCore, IronMixin" to your class.\',',
      );
      buffer.writeln('    );');
      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('}');
  }

  /// Finds the import path for an interface given a component implementation
  String? _findInterfaceImportPath(
    ComponentInfoWithSource component,
    List<ComponentInfoWithSource> allComponents,
  ) {
    if (component.interfaceType == null) return null;

    final interfaceName = component.interfaceType!;
    final implPath = component.sourceFile;
    final implFileName = implPath.split('/').last;

    // Try multiple strategies to find the interface file

    // Strategy 1: Look for another component that has the same name as the interface
    // This handles cases where the interface itself might be annotated
    for (final otherComponent in allComponents) {
      if (otherComponent.className == interfaceName) {
        return otherComponent.sourceFile;
      }
    }

    // Strategy 2: Same directory pattern - remove _impl suffix
    if (implFileName.contains('_impl.dart')) {
      final interfaceFileName = implFileName.replaceAll('_impl.dart', '.dart');
      final interfacePath = implPath.replaceAll(
        implFileName,
        interfaceFileName,
      );
      return interfacePath;
    }

    // Strategy 3: Data/Domain separation patterns
    if (implPath.contains('/data/')) {
      // Pattern: lib/data/repositories/user_repository_impl.dart -> lib/domain/repositories/user_repository.dart
      var interfacePath = implPath.replaceAll('/data/', '/domain/');
      if (implFileName.contains('_impl.dart')) {
        final interfaceFileName = implFileName.replaceAll(
          '_impl.dart',
          '.dart',
        );
        interfacePath = interfacePath.replaceAll(
          implFileName,
          interfaceFileName,
        );
      }
      return interfacePath;
    }

    // Strategy 4: Implementation in subdirectory pattern
    if (implPath.contains('/impl/')) {
      // Pattern: lib/repositories/impl/user_repository_impl.dart -> lib/repositories/user_repository.dart
      var interfacePath = implPath.replaceAll('/impl/', '/');
      if (implFileName.contains('_impl.dart')) {
        final interfaceFileName = implFileName.replaceAll(
          '_impl.dart',
          '.dart',
        );
        interfacePath = interfacePath.replaceAll(
          implFileName,
          interfaceFileName,
        );
      }
      return interfacePath;
    }

    // Strategy 5: Convert class name pattern to file name
    // UserRepositoryImpl -> user_repository.dart (assuming snake_case file naming)
    if (component.className.endsWith('Impl')) {
      final baseClassName = component.className.replaceAll('Impl', '');
      final interfaceFileName = _camelToSnakeCase(baseClassName) + '.dart';
      final interfacePath = implPath.replaceAll(
        implFileName,
        interfaceFileName,
      );
      return interfacePath;
    }

    // Strategy 6: Just use the interface name converted to snake_case
    final interfaceFileName = _camelToSnakeCase(interfaceName) + '.dart';
    final interfacePath = implPath.replaceAll(implFileName, interfaceFileName);
    return interfacePath;
  }

  /// Converts CamelCase to snake_case
  String _camelToSnakeCase(String camelCase) {
    return camelCase
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), ''); // Remove leading underscore
  }

  String _getPropertyName(String className) {
    if (className.isEmpty) return className;
    return className[0].toLowerCase() + className.substring(1);
  }

  String _makeRelativeImport(String fromPath, String toPath) {
    // Convert absolute path to relative import
    // Both fromPath and toPath should start with 'example/' or 'lib/'

    // Remove common prefix if both are in same directory structure
    if (fromPath.startsWith('example/') && toPath.startsWith('example/')) {
      // Both in example directory
      final toParts = toPath.split('/');

      // Remove common 'example/' prefix
      final relativeToPath = toParts.skip(1).join('/');
      return relativeToPath;
    } else if (fromPath.startsWith('lib/') && toPath.startsWith('lib/')) {
      // Both in lib directory
      final toParts = toPath.split('/');

      // Remove common 'lib/' prefix
      final relativeToPath = toParts.skip(1).join('/');
      return relativeToPath;
    } else {
      // Cross-directory reference, use relative path
      if (toPath.startsWith('lib/')) {
        return '../${toPath.substring(4)}'; // Remove 'lib/' and add '../'
      }
      return toPath;
    }
  }

  List<ComponentInfoWithSource> _sortComponentsByDependencies(
    List<ComponentInfoWithSource> components,
  ) {
    // Simple topological sort based on constructor dependencies
    final sorted = <ComponentInfoWithSource>[];
    final visited = <String>{};
    final visiting = <String>{};

    void visit(ComponentInfoWithSource component) {
      if (visiting.contains(component.className)) {
        // Circular dependency detected, but we'll handle it
        return;
      }
      if (visited.contains(component.className)) {
        return;
      }

      visiting.add(component.className);

      // Visit dependencies first
      for (final dep in component.constructorDependencies) {
        final depComponent = components.firstWhere(
          (c) => c.className == dep.type,
          orElse: () => ComponentInfoWithSource(
            className: '',
            componentType: '',
            scope: ScopeType.singleton,
            profiles: [],
            interfaceType: null,
            sourceFile: '',
          ),
        );
        if (depComponent.className.isNotEmpty) {
          visit(depComponent);
        }
      }

      visiting.remove(component.className);
      visited.add(component.className);
      sorted.add(component);
    }

    for (final component in components) {
      visit(component);
    }

    return sorted;
  }

  String _generateComponentRegistration(ComponentInfoWithSource component) {
    final buffer = StringBuffer();

    // Determine the registration type - use interface if available, otherwise class name
    final registrationType = component.interfaceType ?? component.className;

    // Start registration
    buffer.write('    register<$registrationType>(');
    buffer.writeln();
    buffer.write('      () ');

    // Generate constructor call and field injection
    if (component.constructorDependencies.isEmpty &&
        component.autowiredFields.isEmpty) {
      // Simple case: no dependencies
      buffer.write('=> ${component.className}(),');
    } else {
      // Complex case: has dependencies
      buffer.writeln('{');

      if (component.constructorDependencies.isNotEmpty) {
        // Constructor injection
        buffer.write('        final instance = ${component.className}(');
        final constructorArgs = component.constructorDependencies
            .map((dep) => 'get<${dep.type}>()')
            .join(', ');
        buffer.write(constructorArgs);
        buffer.writeln(');');
      } else {
        // No constructor dependencies
        buffer.writeln('        final instance = ${component.className}();');
      }

      // Field injection
      for (final field in component.autowiredFields) {
        buffer.writeln(
          '        instance.${field.fieldName} = get<${field.type}>();',
        );
      }

      buffer.writeln('        return instance;');
      buffer.write('      },');
    }

    buffer.writeln();
    buffer.write('      scope: ScopeType.${component.scope.name},');
    buffer.writeln();
    buffer.write('    );');

    return buffer.toString();
  }

  /// Checks if the given interface name is a framework interface that should be ignored
  bool _isFrameworkInterface(String interfaceName) {
    // List of common Dart and framework interfaces to ignore
    const frameworkInterfaces = {
      'Comparable',
      'Iterator',
      'Iterable',
      'Stream',
      'Future',
      'List',
      'Map',
      'Set',
      'Object',
      'Function',
      'Exception',
      'Error',
      'StackTrace',
      'Type',
      'Symbol',
      'RegExp',
      'Match',
      'Uri',
      'DateTime',
      'Duration',
      'Stopwatch',
      'Random',
      'num',
      'int',
      'double',
      'bool',
      'String',
      'StringSink',
      'StringBuffer',
      'Pattern',
      // Flutter interfaces
      'Widget',
      'StatefulWidget',
      'StatelessWidget',
      'InheritedWidget',
      'PreferredSizeWidget',
      'SingleChildRenderObjectWidget',
      'MultiChildRenderObjectWidget',
      'RenderObjectWidget',
      'Element',
      'RenderObject',
      'State',
      'ChangeNotifier',
      'ValueNotifier',
      'Listenable',
      'ValueListenable',
      // Common third-party interfaces
      'Equatable',
      'Serializable',
      'Copyable',
    };

    return frameworkInterfaces.contains(interfaceName);
  }

  /// Determines if a file should be skipped based on its path
  bool _shouldSkipFile(String path) {
    // Skip generated files
    final generatedFilePatterns = [
      '.g.dart',
      '.rs_iron.dart',
      '.freezed.dart',
      '.config.dart',
      '.chopper.dart',
      '.gr.dart',
      '.mocks.dart',
      '.part.dart',
    ];

    for (final pattern in generatedFilePatterns) {
      if (path.contains(pattern)) {
        return true;
      }
    }

    // Skip common BLoC state/event files that are typically part files
    // BUT do NOT skip the main BLoC files themselves (_bloc.dart files should be processed for DI)
    if (path.endsWith('_state.dart') || path.endsWith('_event.dart')) {
      return true;
    }

    // Skip specific problematic file patterns from the error (but not _bloc.dart files)
    if (path.contains('/bloc/') &&
        (path.contains('_state.dart') || path.contains('_event.dart'))) {
      return true;
    }

    // Skip model files in specific patterns that are likely generated
    if ((path.contains('/models/') || path.contains('/data/')) &&
        (path.endsWith('.g.dart') || path.endsWith('.freezed.dart'))) {
      return true;
    }

    // Skip config files that are typically generated
    if (path.contains('/config/') && path.endsWith('.g.dart')) {
      return true;
    }

    // Skip files in build directories
    if (path.contains('/build/') || path.contains('\\build\\')) {
      return true;
    }

    return false;
  }

  /// Checks if the file content indicates it's a part file or invalid library
  bool _isPartFileOrInvalidLibrary(String content) {
    if (content.trim().isEmpty) {
      return true; // Empty files are not valid libraries
    }

    final contentTrimmed = content.trim();

    // Quick check for part files - look at the very beginning of the file
    if (contentTrimmed.startsWith('part of ')) {
      return true;
    }

    final lines = content.split('\n').take(10).toList();

    // Check the first non-empty, non-comment line
    for (final line in lines) {
      final trimmedLine = line.trim();

      // Skip empty lines and comments
      if (trimmedLine.isEmpty ||
          trimmedLine.startsWith('//') ||
          trimmedLine.startsWith('/*') ||
          trimmedLine.startsWith('*')) {
        continue;
      }

      // If the first meaningful line is a part directive, it's a part file
      if (trimmedLine.startsWith('part of ') ||
          (trimmedLine.startsWith('part ') && trimmedLine.contains('.dart'))) {
        return true;
      }

      // If we find valid library content first, it's not a part file
      if (trimmedLine.startsWith('import ') ||
          trimmedLine.startsWith('export ') ||
          trimmedLine.startsWith('library ') ||
          trimmedLine.startsWith('@') ||
          trimmedLine.startsWith('class ') ||
          trimmedLine.startsWith('abstract class ') ||
          trimmedLine.startsWith('abstract ') ||
          trimmedLine.startsWith('mixin ') ||
          trimmedLine.startsWith('enum ') ||
          trimmedLine.startsWith('typedef ') ||
          trimmedLine.startsWith('extension ') ||
          trimmedLine.startsWith('void ') ||
          trimmedLine.startsWith('String ') ||
          trimmedLine.startsWith('int ') ||
          trimmedLine.startsWith('double ') ||
          trimmedLine.startsWith('bool ') ||
          trimmedLine.startsWith('final ') ||
          trimmedLine.startsWith('const ') ||
          trimmedLine.contains('main(')) {
        return false;
      }

      // If we encounter anything else as the first line, break and do more analysis
      break;
    }

    // Additional check - if content contains "part of" anywhere in the first few lines
    final firstFewLines = content.split('\n').take(5).join('\n').toLowerCase();
    if (firstFewLines.contains('part of ')) {
      return true;
    }

    return false;
  }
}
