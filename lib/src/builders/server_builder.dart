import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';

import 'generators/api_endpoint_generator.dart';
import 'imports_builder.dart';
import 'utils.dart';

class ServerApiBuilder {
  /// Main generation handler for server code
  Future<String> generateServers(
      List<LibraryElement> libraries, BuildStep buildStep) async {
    var imports = ImportsBuilder(buildStep.inputId)
      ..add(Uri.parse('dart:async'))
      ..add(buildStep.inputId.uri)
      ..add(Uri.parse('package:api_agent/server.dart'));

    var exports = ImportsBuilder(buildStep.inputId, 'export')
      ..add(buildStep.inputId.uri);

    Set<String> endpoints = {};

    var output = StringBuffer();

    await for (var library in buildStep.resolver.libraries) {
      if (library.isInSdk) continue;

      for (var element in library.units.expand((u) => u.classes)) {
        if (annotationChecker.hasAnnotationOf(element)) {
          ApiEndpointGenerator(element, null)
              .generate(output, endpoints, imports);
        }
      }
    }

    return DartFormatter().format('${imports.write()}\n'
        '${exports.write()}\n'
        '${output.toString()}');
  }
}
