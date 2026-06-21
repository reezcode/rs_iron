import 'package:rs_iron/rs_iron.dart';
import 'package:test/test.dart';

class _Service {
  _Service(this.value);
  final String value;
}

void main() {
  group('IronContainer', () {
    test('throws when resolving before scan', () {
      final container = IronContainer();

      expect(
        () => container.get<_Service>(),
        throwsA(isA<ContainerInitializationException>()),
      );
    });

    test('resolves singleton registrations as same instance', () async {
      final container = IronContainer();
      var created = 0;

      container.register<_Service>(() {
        created += 1;
        return _Service('singleton');
      });

      await container.scan();

      final first = container.get<_Service>();
      final second = container.get<_Service>();

      expect(identical(first, second), isTrue);
      expect(created, 1);
      expect(first.value, 'singleton');
    });

    test('resolves factory registrations as new instances', () async {
      final container = IronContainer();
      var created = 0;

      container.register<_Service>(() {
        created += 1;
        return _Service('factory-$created');
      }, scope: ScopeType.factory);

      await container.scan();

      final first = container.get<_Service>();
      final second = container.get<_Service>();

      expect(identical(first, second), isFalse);
      expect(created, 2);
      expect(first.value, isNot(second.value));
    });

    test('resolves qualified beans by qualifier and by name', () async {
      final container = IronContainer();

      await (container
            ..register<_Service>(
              () => _Service('primary'),
              qualifier: 'primary',
            )
            ..register<_Service>(
              () => _Service('secondary'),
              qualifier: 'secondary',
            ))
          .scan();

      final primary = container.get<_Service>('primary');
      final secondary = container.getByName('secondary') as _Service;

      expect(primary.value, 'primary');
      expect(secondary.value, 'secondary');
    });

    test('throws multiple-bean exception when no primary is set', () async {
      final container = IronContainer();

      await (container
            ..register<_Service>(() => _Service('one'), name: 'one')
            ..register<_Service>(() => _Service('two'), name: 'two'))
          .scan();

      expect(
        () => container.get<_Service>(),
        throwsA(isA<MultipleBeanFoundException>()),
      );
    });

    test('resolves the primary bean when multiple candidates exist', () async {
      final container = IronContainer();

      await (container
            ..register<_Service>(() => _Service('one'), name: 'one')
            ..register<_Service>(
              () => _Service('primary'),
              name: 'primary',
              isPrimary: true,
            ))
          .scan();

      final service = container.get<_Service>();

      expect(service.value, 'primary');
    });

    test('registers profile-based beans only for active profiles', () async {
      final container = IronContainer(activeProfiles: ['dev']);

      await (container
            ..register<_Service>(
              () => _Service('dev-only'),
              qualifier: 'dev',
              profiles: const ['dev'],
            )
            ..register<_Service>(
              () => _Service('prod-only'),
              qualifier: 'prod',
              profiles: const ['prod'],
            ))
          .scan();

      expect(container.contains<_Service>('dev'), isTrue);
      expect(container.contains<_Service>('prod'), isFalse);
    });
  });

  group('IronEntryPoint', () {
    test('stores optional output file name', () {
      const annotation = IronEntryPoint(outputFileName: 'custom.rs_iron.dart');

      expect(annotation.outputFileName, 'custom.rs_iron.dart');
    });
  });
}
