import 'package:build/build.dart';

import 'src/generator/builder.dart' as gen;

/// Main DI builder
Builder diMirrorsFreeBuilder(BuilderOptions options) =>
    gen.diMirrorsFreeBuilder(options);

/// Legacy builder
Builder diLegacyBuilder(BuilderOptions options) => gen.diLegacyBuilder(options);
