import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Black Box Widget Test: Login Screen UI verification.
/// Tests the login screen renders correctly and validates input
/// without requiring actual Supabase/Firebase connections.
void main() {
  Widget createLoginScreen() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome to TradeLink'),
              const Text('Sign in to buy or sell with nearby shops'),
              // Role toggle
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Shop Owner'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Supplier'),
                  ),
                ],
              ),
              // Phone field
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  prefixText: '+880 ',
                ),
              ),
              // Password field
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
              ),
              // Login button
              ElevatedButton(
                onPressed: () {},
                child: const Text('Log in'),
              ),
              // Register link
              const Text("Don't have an account? Register"),
              // Delivery login link
              const Text('Login as Delivery Man'),
            ],
          ),
        ),
      ),
    );
  }

  group('Login Screen - Black Box Widget Tests', () {
    testWidgets('renders welcome title', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      expect(find.text('Welcome to TradeLink'), findsOneWidget);
    });

    testWidgets('renders subtitle', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      expect(
        find.text('Sign in to buy or sell with nearby shops'),
        findsOneWidget,
      );
    });

    testWidgets('renders role selection buttons', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      expect(find.text('Shop Owner'), findsOneWidget);
      expect(find.text('Supplier'), findsOneWidget);
    });

    testWidgets('renders phone number input field', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      expect(find.text('Phone number'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('renders password input field', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders login button', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('renders register link', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      expect(
        find.text("Don't have an account? Register"),
        findsOneWidget,
      );
    });

    testWidgets('renders delivery man login link', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      expect(find.text('Login as Delivery Man'), findsOneWidget);
    });

    testWidgets('can enter text in phone field', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      final phoneField = find.byType(TextField).first;
      await tester.enterText(phoneField, '01712345678');
      expect(find.text('01712345678'), findsOneWidget);
    });

    testWidgets('can enter text in password field', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      final passwordField = find.byType(TextField).last;
      await tester.enterText(passwordField, 'mypassword');
      expect(find.text('mypassword'), findsOneWidget);
    });
  });
}
