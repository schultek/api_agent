import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

import 'imports_builder.dart';
import 'utils.dart';

class ClientApiBuilder {
  /// Main generation handler for client code
  Future<String> generateClients(
      List<LibraryElement> libraries, BuildStep buildStep) async {
    var imports = ImportsBuilder(buildStep.inputId)
      ..add(buildStep.inputId.uri)
      ..add(Uri.parse('package:dart_api_gen/client.dart'));

    Map<String, String> clients = {};

    await for (var library in buildStep.resolver.libraries) {
      if (library.isInSdk) continue;

      for (var element in library.units.expand((u) => u.classes)) {
        if (annotationChecker.hasAnnotationOf(element)) {
          generateClient(element, clients, imports);
        }
      }
    }

    var output = StringBuffer();

    output.writeln(imports.write());
    output.writeAll(clients.values, '\n');

    return output.toString();
  }

  void generateClient(ClassElement element, Map<String, String> clients,
      ImportsBuilder imports) {
    if (clients.containsKey(element.name)) return;
    clients[element.name] = '';

    var annotation = annotationChecker.firstAnnotationOf(element);

    var output = StringBuffer();

    output.writeln('class ${element.name}Service extends ApiService {');

    output.write(
        "  ${element.name}Service(ApiClient client) : super('${element.name}', client");

    if (annotation != null && !annotation.getField('codec')!.isNull) {
      var codec = getMetaProperty(element, 'codec');
      output.write(', $codec');
      var uri =
          annotation.getField('codec')!.type?.element?.library?.source.uri;
      if (uri != null) imports.add(uri);
    }

    output.writeln(');');

    for (var method in element.methods) {
      if (method.isAbstract) {
        output.writeln(
            '\n  ${method.getDisplayString(withNullability: true)} => ');
        output.write('    request(\'${method.name}\', {');

        for (var param in method.parameters) {
          if (method.parameters.first != param) {
            output.write(', ');
          }
          output.write("'${param.name}': ${param.name}");
        }

        output.writeln('});');

        imports.addAll(method.getImports());
      }
    }

    for (var accessor in element.accessors) {
      if (accessor.isAbstract && accessor.isGetter) {
        var elem = accessor.type.returnType.element;
        if (elem == null || elem is! ClassElement) continue;
        output.writeln(
            '\n  ${elem.name}Service get ${accessor.name} => ${elem.name}Service(client);');
        generateClient(elem, clients, imports);
      }
    }

    output.writeln('}');

    clients[element.name] = output.toString();
  }
}
