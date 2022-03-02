abstract class ApiCodec {
  dynamic encode(dynamic value);
  T decode<T>(dynamic value);
}
