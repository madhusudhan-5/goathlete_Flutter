import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_console/main.dart';

void main() {
  testWidgets('Admin console app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: UnifiedAdminConsoleApp()));
    expect(find.byType(UnifiedAdminConsoleApp), findsOneWidget);
  });
}
