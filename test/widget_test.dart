import 'package:flutter_test/flutter_test.dart';
import 'package:sparkedu/main.dart';

void main() {
  testWidgets('SparkEdu launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SparkEduApp());

    expect(find.text('SparkEdu'), findsWidgets);
  });
}