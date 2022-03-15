import 'package:dart_mappable/internals.dart';

import 'models.dart';


// === ALL STATICALLY REGISTERED MAPPERS ===

var _mappers = <BaseMapper>{
  // class mappers
  DataMapper._(),
  ValueMapper._(),
  // enum mappers
  // custom mappers
};


// === GENERATED CLASS MAPPERS AND EXTENSIONS ===

class DataMapper extends BaseMapper<Data> {
  DataMapper._();

  @override Function get decoder => decode;
  Data decode(dynamic v) => checked(v, (Map<String, dynamic> map) => fromMap(map));
  Data fromMap(Map<String, dynamic> map) => Data(map.get('greeting'));

  @override Function get encoder => (Data v) => encode(v);
  dynamic encode(Data v) => toMap(v);
  Map<String, dynamic> toMap(Data d) => {'greeting': Mapper.toValue(d.greeting)};

  @override String? stringify(Data self) => 'Data(greeting: ${Mapper.asString(self.greeting)})';
  @override int? hash(Data self) => Mapper.hash(self.greeting);
  @override bool? equals(Data self, Data other) => Mapper.isEqual(self.greeting, other.greeting);

  @override Function get typeFactory => (f) => f<Data>();
}

extension DataMapperExtension  on Data {
  String toJson() => Mapper.toJson(this);
  Map<String, dynamic> toMap() => Mapper.toMap(this);
  DataCopyWith<Data> get copyWith => DataCopyWith(this, $identity);
}

abstract class DataCopyWith<$R> {
  factory DataCopyWith(Data value, Then<Data, $R> then) = _DataCopyWithImpl<$R>;
  $R call({String? greeting});
  $R apply(Data Function(Data) transform);
}

class _DataCopyWithImpl<$R> extends BaseCopyWith<Data, $R> implements DataCopyWith<$R> {
  _DataCopyWithImpl(Data value, Then<Data, $R> then) : super(value, then);

  @override $R call({String? greeting}) => $then(Data(greeting ?? $value.greeting));
}

class ValueMapper extends BaseMapper<Value> {
  ValueMapper._();

  @override Function get decoder => decode;
  Value<T> decode<T>(dynamic v) => checked(v, (Map<String, dynamic> map) => fromMap<T>(map));
  Value<T> fromMap<T>(Map<String, dynamic> map) => Value(map.get('data'));

  @override Function get encoder => (Value v) => encode(v);
  dynamic encode(Value v) => toMap(v);
  Map<String, dynamic> toMap(Value v) => {'data': Mapper.toValue(v.data)};

  @override String? stringify(Value self) => 'Value(data: ${Mapper.asString(self.data)})';
  @override int? hash(Value self) => Mapper.hash(self.data);
  @override bool? equals(Value self, Value other) => Mapper.isEqual(self.data, other.data);

  @override Function get typeFactory => <T>(f) => f<Value<T>>();
}

extension ValueMapperExtension <T> on Value<T> {
  String toJson() => Mapper.toJson(this);
  Map<String, dynamic> toMap() => Mapper.toMap(this);
  ValueCopyWith<Value<T>, T> get copyWith => ValueCopyWith(this, $identity);
}

abstract class ValueCopyWith<$R, T> {
  factory ValueCopyWith(Value<T> value, Then<Value<T>, $R> then) = _ValueCopyWithImpl<$R, T>;
  $R call({T? data});
  $R apply(Value<T> Function(Value<T>) transform);
}

class _ValueCopyWithImpl<$R, T> extends BaseCopyWith<Value<T>, $R> implements ValueCopyWith<$R, T> {
  _ValueCopyWithImpl(Value<T> value, Then<Value<T>, $R> then) : super(value, then);

  @override $R call({T? data}) => $then(Value(data ?? $value.data));
}


// === GENERATED ENUM MAPPERS AND EXTENSIONS ===




// === GENERATED UTILITY CODE ===

class Mapper {
  Mapper._();

  static late MapperContainer i = MapperContainer(_mappers);

  static T fromValue<T>(dynamic value) => i.fromValue<T>(value);
  static T fromMap<T>(Map<String, dynamic> map) => i.fromMap<T>(map);
  static T fromIterable<T>(Iterable<dynamic> iterable) => i.fromIterable<T>(iterable);
  static T fromJson<T>(String json) => i.fromJson<T>(json);

  static dynamic toValue(dynamic value) => i.toValue(value);
  static Map<String, dynamic> toMap(dynamic object) => i.toMap(object);
  static Iterable<dynamic> toIterable(dynamic object) => i.toIterable(object);
  static String toJson(dynamic object) => i.toJson(object);

  static bool isEqual(dynamic value, Object? other) => i.isEqual(value, other);
  static int hash(dynamic value) => i.hash(value);
  static String asString(dynamic value) => i.asString(value);

  static void use<T>(BaseMapper<T> mapper) => i.use<T>(mapper);
  static BaseMapper<T>? unuse<T>() => i.unuse<T>();
  static void useAll(List<BaseMapper> mappers) => i.useAll(mappers);

  static BaseMapper<T>? get<T>([Type? type]) => i.get<T>(type);
  static List<BaseMapper> getAll() => i.getAll();
}

mixin Mappable {
  BaseMapper? get _mapper => Mapper.get(runtimeType);

  String toJson() => Mapper.toJson(this);
  Map<String, dynamic> toMap() => Mapper.toMap(this);

  @override String toString() => _mapper?.stringify(this) ?? super.toString();
  @override bool operator ==(Object other) => identical(this, other) ||
      (runtimeType == other.runtimeType && (_mapper?.equals(this, other) 
      ?? super == other));
  @override int get hashCode => _mapper?.hash(this) ?? super.hashCode;
}

extension MapGet on Map<String, dynamic> {
  T get<T>(String key, {MappingHooks? hooks}) => _getOr(
      key, hooks, () => throw MapperException('Parameter $key is required.'));

  T? getOpt<T>(String key, {MappingHooks? hooks}) =>
      _getOr(key, hooks, () => null);

  T _getOr<T>(String key, MappingHooks? hooks, T Function() or) =>
      hooks.decode(this[key], (v) => v == null ? or() : Mapper.fromValue<T>(v));
}
