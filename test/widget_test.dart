import 'package:flutter_test/flutter_test.dart';
import 'package:dorduncu/main.dart';

void main() {
  testWidgets('DorduncuApp smoke test', (WidgetTester tester) async {
    // Uygulamayı başlat
    await tester.pumpWidget(const DorduncuApp());

    // Uygulamanın çalıştığını doğrula
    expect(find.byType(DorduncuApp), findsOneWidget);
  });
}