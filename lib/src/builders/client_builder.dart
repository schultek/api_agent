import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';

import 'imports_builder.dart';
import 'utils.dart';

class ClientApiBuilder {
  /// Main generation handler for client code
  Future<String> generateClients(
      List<LibraryElement> libraries, BuildStep buildStep) async {
    var imports = ImportsBuilder(buildStep.inputId)
      ..add(buildStep.inputId.uri)
      ..add(Uri.parse('package:api_agent/client.dart'));
    var exports = ImportsBuilder(buildStep.inputId, 'export')
      ..add(buildStep.inputId.uri);

    Map<String, String> clients = {};

    await for (var library in buildStep.resolver.libraries) {
      if (library.isInSdk) continue;

      for (var element in library.units.expand((u) => u.classes)) {
        if (annotationChecker.hasAnnotationOf(element)) {
          generateClient(element, clients, imports);
        }
      }
    }

    return DartFormatter().format('${imports.write()}\n'
        '${exports.write()}\n'
        '${clients.values.join('\n')}');
  }

  void generateClient(ClassElement element, Map<String, String> clients,
      ImportsBuilder imports) {
    if (clients.containsKey(element.name)) return;
    clients[element.name] = '';

    var annotation = annotationChecker.firstAnnotationOf(element);

    var output = StringBuffer();

    output.write('class ${element.name}Client extends RelayApiClient {\n'
        '  ${element.name}Client(ApiClient client) '
        ': super(\'${element.name}\', client');

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
        output.write('\n'
            '  ${method.getDisplayString(withNullability: true)} => \n'
            '    request(\'${method.name}\', {');

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
        output.writeln('\n'
            '  late final ${elem.name}Client ${accessor.name} = '
            '${elem.name}Client(this);');
        generateClient(elem, clients, imports);
      }
    }

    output.writeln('}');

    clients[element.name] = output.toString();
  }
}
