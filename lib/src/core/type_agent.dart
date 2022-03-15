import 'package:type_plus/type_plus.dart';

class TypeAgent<T> {
  bool isA<U>() => T.base == U;

  T mapAs<U>(U Function() fn) => fn() as T;
  T mapAs1<U>(U Function<V>() fn) {
    return T.args.single.provideTo<U>(fn) as T;
  }
}

Type typeOf<T>() => T;
