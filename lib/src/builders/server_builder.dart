import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';

import '../case_style.dart';
import 'imports_builder.dart';
import 'utils.dart';

class ServerApiBuilder {
  /// Main generation handler for server code
  Future<String> generateServers(
      List<LibraryElement> libraries, BuildStep buildStep) async {
    var imports = ImportsBuilder(buildStep.inputId)
      ..add(Uri.parse('dart:async'))
      ..add(buildStep.inputId.uri)
      ..add(Uri.parse('package:dart_api_gen/server.dart'));

    Map<String, String> handlers = {};

    await for (var library in buildStep.resolver.libraries) {
      if (library.isInSdk) continue;

      for (var element in library.units.expand((u) => u.classes)) {
        if (annotationChecker.hasAnnotationOf(element)) {
          generateServer(element, handlers, imports);
        }
      }
    }

    var output = StringBuffer();

    output.writeln(imports.write());
    output.writeAll(handlers.values, '\n');

    return output.toString();
  }

  void generateServer(ClassElement element, Map<String, String> handlers,
      ImportsBuilder imports) {
    if (handlers.containsKey(element.name)) return;
    handlers[element.name] = '';

    var annotation = annotationChecker.firstAnnotationOf(element);

    var output = StringBuffer();

    output.writeln(
        'class ${element.name}Handler implements ApiHandler<${element.name}Handler> {');

    output.writeln('  ${element.name}Handler({');

    var endpoints = <String>[];

    for (var method in element.methods) {
      if (method.isAbstract) {
        var handlerName = generateEndpoint(method, element, handlers, imports);
        output.writeln('    required ApiHandler<$handlerName> ${method.name},');
        endpoints.add(method.name);
      }
    }

    for (var accessor in element.accessors) {
      if (accessor.isAbstract && accessor.isGetter) {
        var elem = accessor.type.returnType.element;
        if (elem == null || elem is! ClassElement) continue;
        output.writeln(
            '    required ApiHandler<${elem.name}Handler> ${accessor.name},');
        endpoints.add(accessor.name);
        generateServer(elem, handlers, imports);
      }
    }

    output.writeln('  }) : endpoints = [${endpoints.join(', ')}];');

    output.writeln('\n  final List<ApiHandler> endpoints;');

    output.writeln('\n  @override\n  void visit(ApiVisitor visitor) =>');
    output.write("    visitor.mount('${element.name}', endpoints");

    if (annotation != null && !annotation.getField('codec')!.isNull) {
      var codec = getMetaProperty(element, 'codec', imports);
      output.write('.withCodec($codec)');
      var uri =
          annotation.getField('codec')!.type?.element?.library?.source.uri;
      if (uri != null) imports.add(uri);
    }

    output.writeln(');');

    output.writeln('}');

    handlers[element.name] = output.toString();
  }

  String generateEndpoint(MethodElement method, ClassElement element,
      Map<String, String> handlers, ImportsBuilder imports) {
    var name = CaseStyle.pascalCase.transform(method.name) + 'Handler';

    if (handlers.containsKey(name)) {
      name = element.name + name;
    }

    if (handlers.containsKey(name)) {
      throw Exception('Duplicate endpoint handler $name');
    }

    handlers[name] = '';

    var output = StringBuffer();

    output.writeln('abstract class $name implements ApiHandler<$name> {');

    output.write(
        '  ${method.returnType.getDisplayString(withNullability: true)} ${method.name}(');

    for (var param in method.parameters) {
      output.write(
          '${param.type.getDisplayString(withNullability: true)} ${param.name}, ');
    }
    output.writeln('ApiRequest request);');

    output.writeln('\n  @override\n  void visit(ApiVisitor visitor) =>');
    output.write("    visitor.handle('${method.name}', (r) => ${method.name}(");

    for (var param in method.parameters) {
      output.write('r.get');
      if (param.hasDefaultValue ||
          param.type.nullabilitySuffix == NullabilitySuffix.question) {
        output.write('Opt');
      }
      output.write("('${param.name}')");
      if (param.hasDefaultValue) {
        output.write(' ?? ${param.defaultValueCode}');
      }
      output.write(', ');
    }
    output.writeln('r));');
    output.writeln('}');

    imports.addAll(method.getImports());

    handlers[name] = output.toString();

    return name;
  }
}
