abstract class ApiCodec {
  const ApiCodec();

  dynamic encode(dynamic value);
  T decode<T>(dynamic value);
}
