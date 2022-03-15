import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';

class UseTypesGenerator {
  final typesOutput = StringBuffer();

  final visitedTypes = <DartType>{};

  void addFromAnnotation(DartObject? annotation) {
    var useTypes = annotation
        ?.getField('useTypes')
        ?.toListValue()
        ?.map((t) => t.toTypeValue())
        .whereType<DartType>();
    add(useTypes?.toList() ?? []);
  }

  void add(List<DartType> types) {
    while (types.isNotEmpty) {
      var type = types.removeLast();
      if (visitedTypes.contains(type)) continue;
      visitedTypes.add(type);
      if (type is! InterfaceType) continue;
      if (!type.element.library.isInSdk) {
        var t = type.element.name;
        if (type.typeArguments.isNotEmpty) {
          var args = List.generate(type.typeArguments.length,
              (index) => String.fromCharCode(65 + index)).join(', ');
          typesOutput.writeln('useType(\'$t\', <$args>(f) => f<$t<$args>>());');
        } else {
          typesOutput.writeln('useType(\'$t\', (f) => f<$t>());');
        }
      }
      types.addAll(type.typeArguments);
    }
  }

  String generate() {
    return typesOutput.toString();
  }
}
