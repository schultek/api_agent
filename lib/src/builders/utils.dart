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
  return null;
}

extension GetNode on Element {
  AstNode? getNode() {
    var result = session?.getParsedLibraryByElement(library!);
    if (result is ParsedLibraryResult) {
      return result.getElementDeclaration(this)?.node;
    } else {
      return null;
    }
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
    if (element?.library?.isInSdk ?? false) return [];
    var uri = element?.library?.source.uri;
    return uri != null ? [uri] : [];
  }
}

extension InterfaceTypeImports on InterfaceType {
  List<Uri> getImports() {
    return [
      if (!element.library.isInSdk) element.library.source.uri,
      ...typeArguments.expand((t) => t.getImports()),
    ];
  }
}
