import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../../api_agent.dart';
import 'imports_builder.dart';

const annotationChecker = TypeChecker.fromRuntime(ApiDefinition);

String? getMetaProperty(Element annotatedElement, String property,
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
    if (annotation.name.name == (ApiDefinition).toString()) {
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
    if (this is InterfaceType) return (this as InterfaceType).getImports();
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
