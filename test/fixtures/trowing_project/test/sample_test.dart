import 'package:test/test.dart';

void main() {
  bool? nullable;
  bool error = nullable!;

  test('always fails', () {
    expect(error, equals(nullable));
  });
}
