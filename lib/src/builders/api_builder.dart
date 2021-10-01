import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../../dart_api_gen.dart';
import 'imports_builder.dart';

const annotationChecker = TypeChecker.fromRuntime(ApiDefinition);

/// The main builder used for code generation
class ApiBuilder implements Builder {
  /// The global options defined in the 'build.yaml' file
  late BuilderOptions options;

  ApiBuilder(this.options);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var resolver = buildStep.resolver;
    var inputId = buildStep.inputId;
    var visibleLibraries = await resolver.libraries.toList();

    var clientId = inputId.changeExtension('.client.dart');
    var clientSource = await generateClients(visibleLibraries, buildStep);
    await buildStep.writeAsString(clientId, clientSource);

    var serverId = inputId.changeExtension('.server.dart');
    var serverSource = await generateServers(visibleLibraries, buildStep);
    await buildStep.writeAsString(serverId, serverSource);
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.client.dart', '.server.dart']
      };

  /// Main generation handler for client code
  Future<String> generateClients(
      List<LibraryElement> libraries, BuildStep buildStep) async {
    var imports = ImportsBuilder(buildStep.inputId)
      ..add(buildStep.inputId.uri)
      ..add(Uri.parse('package:dart_api_gen/client.dart'));

    List<String> clients = [];

    await for (var library in buildStep.resolver.libraries) {
      if (library.isInSdk) continue;

      for (var element in library.units.expand((u) => u.classes)) {
        if (annotationChecker.hasAnnotationOf(element)) {
          clients.add(generateClient(element, imports));
        }
      }
    }

    var output = StringBuffer();

    output.writeln(imports.write());
    output.writeAll(clients, '\n');

    return output.toString();
  }

  String generateClient(ClassElement element, ImportsBuilder imports) {
    var annotation = annotationChecker.firstAnnotationOf(element)!;

    var output = StringBuffer();

    output.writeln(
        'abstract class ${element.name}ClientBase extends ${element.name} with ApiClient {');

    if (!annotation.getField('codec')!.isNull) {
      var codec = getAnnotationCode(element, ApiDefinition, 'codec');
      output.writeln('  ApiCodec get codec => $codec;');
      var uri =
          annotation.getField('codec')!.type?.element?.library?.source.uri;
      if (uri != null) imports.add(uri);
    }

    for (var method in element.methods) {
      if (method.isAbstract) {
        output.writeln('\n  /// [${element.name}.${method.name}]');
        output.write('  ${method.getDisplayString(withNullability: true)} => ');
        output.writeln('request(\'${element.name}.${method.name}\', {');

        for (var param in method.parameters) {
          output.writeln("    '${param.name}': ${param.name},");
        }

        output.writeln('  });');

        imports.addAll(method.getImports());
      }
    }

    output.writeln('}');

    return output.toString();
  }

  /// Main generation handler for server code
  Future<String> generateServers(
      List<LibraryElement> libraries, BuildStep buildStep) async {
    var imports = ImportsBuilder(buildStep.inputId)
      ..add(Uri.parse('dart:async'))
      ..add(buildStep.inputId.uri)
      ..add(Uri.parse('package:dart_api_gen/server.dart'));

    List<String> routers = [];

    await for (var library in buildStep.resolver.libraries) {
      if (library.isInSdk) continue;

      for (var element in library.units.expand((u) => u.classes)) {
        if (annotationChecker.hasAnnotationOf(element)) {
          routers.add(generateServer(element, imports));
        }
      }
    }

    var output = StringBuffer();

    output.writeln(imports.write());
    output.writeAll(routers, '\n');

    return output.toString();
  }

  String generateServer(ClassElement element, ImportsBuilder imports) {
    var annotation = annotationChecker.firstAnnotationOf(element)!;

    var output = StringBuffer();

    output.writeln(
        'abstract class ${element.name}RouterBase extends ApiRouter {');

    if (!annotation.getField('codec')!.isNull) {
      var codec = getAnnotationCode(element, ApiDefinition, 'codec', imports);
      output.writeln('  ApiCodec get codec => $codec;');
      var uri =
          annotation.getField('codec')!.type?.element?.library?.source.uri;
      if (uri != null) imports.add(uri);
    }

    for (var method in element.methods) {
      if (method.isAbstract) {
        output.writeln('\n  /// [${element.name}.${method.name}]');

        output.write(
            '  ${method.returnType.getDisplayString(withNullability: true)} ${method.name}(');

        var params = <String>[];

        for (var param
            in method.parameters.where((p) => p.isRequiredPositional)) {
          params.add(
              '${param.type.getDisplayString(withNullability: true)} ${param.name}');
        }
        params.add('ApiRequest request');

        var opt = method.parameters.where((p) => p.isOptionalPositional);
        if (opt.isNotEmpty) {
          var optParams = <String>[];
          for (var param in opt) {
            var str =
                '${param.type.getDisplayString(withNullability: true)} ${param.name}';
            if (param.hasDefaultValue) {
              str += ' = ${param.defaultValueCode}';
            }
            optParams.add(str);
          }
          params.add('[${optParams.join(', ')}]');
        }

        var named = method.parameters.where((p) => p.isNamed);
        if (named.isNotEmpty) {
          var namedParams = <String>[];
          for (var param in named) {
            var str = '';
            if (param.isRequiredNamed) {
              str += 'required ';
            }
            str +=
                '${param.type.getDisplayString(withNullability: true)} ${param.name}';
            if (param.hasDefaultValue) {
              str += ' = ${param.defaultValueCode}';
            }
            namedParams.add(str);
          }
          params.add('{${namedParams.join(', ')}}');
        }

        output.write(params.join(', '));

        output.writeln(');');

        imports.addAll(method.getImports());
      }
    }

    output.writeln('\n'
        '  @override\n'
        '  dynamic handle(ApiRequest r) {\n'
        '    switch (r.method) {');

    for (var method in element.methods) {
      if (method.isAbstract) {
        output.write("      case '${element.name}.${method.name}': ");
        output.write('return wrap((r) => ${method.name}(\n        ');

        var hasContext = false;
        for (var param in method.parameters) {
          if (!param.isRequiredPositional && !hasContext) {
            output.write('r, ');
            hasContext = true;
          }

          if (param.isNamed) {
            output.write('${param.name}: ');
          }
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
        if (!hasContext) {
          output.write('r, ');
        }
        output.writeln('\n      ), r);');
      }
    }

    output
        .writeln('      default: throw ApiException.methodNotFound(r.method);\n'
            '    }\n'
            '  }');

    output.writeln('}');

    return output.toString();
  }

  String? getAnnotationCode(
      Element annotatedElement, Type annotationType, String property,
      [ImportsBuilder? imports]) {
    var node = annotatedElement.getNode();

    NodeList<Annotation> annotations;

    if (node is VariableDeclaration) {
      var parent = node.parent?.parent;
      if (parent is FieldDeclaration) {
        annotations = parent.metadata;
      } else {
        return null;
      }
    } else if (node is Declaration) {
      annotations = node.metadata;
    } else {
      return null;
    }

    for (var annotation in annotations) {
      if (annotation.name.name == annotationType.toString()) {
        var props = annotation.arguments!.arguments
            .whereType<NamedExpression>()
            .where((e) => e.name.label.name == property);

        if (props.isNotEmpty) {
          var exp = props.first.expression;

          return exp.toSource();
        }
      }
    }
  }
}

extension GetNode on Element {
  AstNode? getNode() {
    return (session?.getParsedLibraryByElement2(library!)
            as ParsedLibraryResult?)
        ?.getElementDeclaration(this)
        ?.node;
  }
}

extension MethodImports on MethodElement {
  List<Uri> getImports() {
    return [
      ...returnType.getImports(),
      ...parameters.expand((p) => p.type.getImports())
    ];
  }
}

extension TypeImports on DartType {
  List<Uri> getImports() {
    var uri = element?.library?.source.uri;
    return uri != null ? [uri] : [];
  }
}

extension InterfaceTypeImports on InterfaceType {
  List<Uri> getImports() {
    return [
      element.library.source.uri,
      ...typeArguments.expand((t) => t.getImports()),
    ];
  }
}
