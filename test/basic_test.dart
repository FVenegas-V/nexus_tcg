import 'package:flutter_test/flutter_test.dart';

/// Test básico para verificar que el framework de testing funciona
void main() {
  test('Test framework funciona correctamente', () {
    expect(1 + 1, equals(2));
    expect('hello', isA<String>());
    expect([1, 2, 3], hasLength(3));

    print('✅ Test framework funcionando');
  });

  test('Matemáticas básicas', () {
    final result = 5 * 10;
    expect(result, equals(50));

    final list = <String>['a', 'b', 'c'];
    expect(list, contains('b'));

    print('✅ Tests básicos pasando');
  });
}
