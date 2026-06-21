import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'di_generator.dart';
import 'rs_iron_builder.dart';

Builder diMirrorsFreeBuilder(BuilderOptions options) =>
    const IronAggregatingBuilder();

Builder diLegacyBuilder(BuilderOptions options) =>
    LibraryBuilder(DiGenerator(), generatedExtension: '.rs_iron.dart');
