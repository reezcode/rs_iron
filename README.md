# rs_iron

rs_iron is a code-generation-first dependency injection package for Dart and Flutter, optimized for mobile app development.

It provides annotation-based registration, constructor-based dependency resolution, and Flutter-friendly APIs without relying on dart:mirrors.

## Install

Add to your pubspec:

```yaml
dependencies:
  rs_iron: ^latest_package

dev_dependencies:
  build_runner: ^2.4.13
```

## Import

Use the new entry file:

```dart
import 'package:rs_iron/rs_iron.dart';
```

## Quick Start

### 1. Annotate your classes

```dart
import 'package:rs_iron/rs_iron.dart';

@Repository()
class UserRepository {
  Future<String> getUserName() async => 'Jane';
}

@Service()
class UserService {
  final UserRepository repository;
  UserService(this.repository);

  Future<String> loadName() => repository.getUserName();
}
```

### 2. Add an entry point

```dart
import 'package:rs_iron/rs_iron.dart';

@IronEntryPoint()
class AppModule {}
```

### 3. Generate

```bash
dart run build_runner build
```

This creates a generated file next to your entry point, for example:

app_module.rs_iron.dart

### 4. Initialize and resolve

```dart
import 'package:rs_iron/rs_iron.dart';
import 'app_module.rs_iron.dart';

Future<void> main() async {
  final container = IronContainer();
  await container.scan();
  container.registerGeneratedDependencies();

  final userService = container.get<UserService>();
  print(await userService.loadName());
}
```

## Flutter Usage

Use IronCore for lifecycle/access helpers and IronMixin for generated shortcut properties.

```dart
import 'package:flutter/material.dart';
import 'package:rs_iron/rs_iron.dart';
import 'app_module.rs_iron.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IronCore.initialize((container) {
    container.registerGeneratedDependencies();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with IronCore, IronMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('rs_iron example')),
      body: FutureBuilder<String>(
        future: userService.loadName(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(child: Text(snapshot.data!));
        },
      ),
    );
  }
}
```

## Common Commands

```bash
dart run build_runner build
dart run build_runner watch
dart run build_runner clean
```

## Notes

- Prefer constructor injection for better testability and compile-time safety.
- **Singleton scope** (default) - Use for services, repositories, and shared resources that persist throughout the app lifecycle. Initialized eagerly at startup.
- **Lazy Singleton scope** - Use for singletons that should only be instantiated when first requested, saving startup time and memory.
- **Factory scope** - Use for stateful widgets, view models, or when you need fresh instances for each injection.
- Re-run code generation after adding or renaming annotated classes.
- Keep one `@IronEntryPoint()` annotation per app module.
