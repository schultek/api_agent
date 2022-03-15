import 'package:type_plus/type_plus.dart';

void useType<T>(String id, [Function? factory]) {
  if (factory != null) {
    TypePlus.addFactory(factory, id: id);
  } else {
    TypePlus.add<T>(id: id);
  }
}
