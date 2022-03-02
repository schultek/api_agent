import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import '../../core/case_style.dart';
import '../imports_builder.dart';
import '../utils.dart';
import 'endpoint_generator.dart';

class MethodEndpointGenerator extends EndpointGenerator {
  final MethodElement method;
  final Set<String> endpoints;

  MethodEndpointGenerator(this.method, this.endpoints);

  @override
  late String endpointClassName = _getEndpointClassName();

  String _getEndpointClassName() {
    var name = CaseStyle.pascalCase.transform(method.name);
    var endpointName = name + 'Endpoint';

    if (endpoints.contains(endpointName)) {
      endpointName = method.enclosingElement.name! + endpointName;
    }

    if (endpoints.contains(endpointName)) {
      throw Exception('Duplicate endpoint $endpointName');
    }

    endpoints.add(endpointName);
    return endpointName;
  }

  @override
  late String propertyName = method.name;

  late String methodDefinition = getHandlerDefinition();

  @override
  late String abstractMemberDefinition = '$methodDefinition;';

  @override
  late String constructedEndpoint = '$endpointClassName.from($propertyName)';

  late String handlerDefinition = getHandlerDefinition(false);

  String getHandlerDefinition([bool useName = true]) {
    var output = StringBuffer();
    if (method.returnType.isDartAsyncFuture) {
      var t = (method.returnType as InterfaceType).typeArguments.first;
      output.write('FutureOr<${t.getDisplayString(withNullability: true)}>');
    } else {
      output.write(method.returnType.getDisplayString(withNullability: true));
    }

    output.write(' ${useName ? method.name : 'Function'}(');

    for (var param in method.parameters) {
      output.write('${param.type.getDisplayString(withNullability: true)} '
          '${param.name}, ');
    }

    output.write('${useName ? 'covariant ' : ''}ApiRequest request)');
    return output.toString();
  }

  @override
  void generate(
      StringBuffer output, Set<String> endpoints, ImportsBuilder imports) {
    output.write(
        'abstract class $endpointClassName implements ApiEndpoint<$endpointClassName> {\n'
        '  $endpointClassName();\n'
        '  factory $endpointClassName.from($handlerDefinition handler) = _$endpointClassName;\n'
        '  $abstractMemberDefinition\n'
        '  @override\n'
        '  void build(ApiBuilder builder) {\n'
        '    builder.handle(\'${method.name}\', (r) => ${method.name}(');

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
    output.writeln('}\n}\n');

    output.write('class _$endpointClassName extends $endpointClassName {\n'
        '  _$endpointClassName(this.handler);\n\n'
        '  final $handlerDefinition handler;\n\n'
        '  @override\n'
        '  $methodDefinition {\n'
        '    return handler(');

    for (var param in method.parameters) {
      output.write('${param.name}, ');
    }

    output.writeln('request);\n'
        '  }\n'
        '}');

    imports.addAll(method.getImports());
  }
}
