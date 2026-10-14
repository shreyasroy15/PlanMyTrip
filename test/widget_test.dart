import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planmytrip/app/app.dart';
import 'package:planmytrip/providers/auth_provider.dart';

class AuthNotifierMock extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState(isLoading: false);
  }
}

void main() {
  testWidgets('PlanMyTripApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(AuthNotifierMock.new),
        ],
        child: const PlanMyTripApp(),
      ),
    );

    expect(find.byType(PlanMyTripApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
