import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:majortaskmp/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    setUp(() async {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        print('Firebase initialization error: $e');
      }
    });

    testWidgets('form validation', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp(testing: true));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com'
      );
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          '12345'
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pump();

      expect(
          find.text('Password must be at least 6 characters long'),
          findsOneWidget
      );
    });

    testWidgets('login, profile navigation, event and gift creation flow', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(const MyApp(testing: true));
        await tester.pumpAndSettle();

        // === Login Flow ===
        expect(find.text('Login'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

        await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            'mazen200@gmail.com'
        );
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Password'),
            'mazen123w'
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await Future.delayed(const Duration(seconds: 2));
        await tester.pump();
        await tester.pumpAndSettle();

        // === Navigate to Profile ===
        final profileIcon = find.byIcon(Icons.account_circle);
        expect(profileIcon, findsOneWidget);
        await tester.tap(profileIcon);
        await tester.pumpAndSettle();

        expect(find.text('Profile'), findsOneWidget);

        // === Navigate to Event List ===
        final myEventsButton = find.text('My Created Events');
        expect(myEventsButton, findsOneWidget);
        await tester.tap(myEventsButton);
        await tester.pumpAndSettle();

        // === Add New Event ===
        final addEventButton = find.byType(FloatingActionButton);
        expect(addEventButton, findsOneWidget);
        await tester.tap(addEventButton);
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBar, 'Add Event'), findsOneWidget);

        await tester.enterText(
            find.widgetWithText(TextFormField, 'Event Name'),
            'Test Event'
        );

        await tester.tap(find.text('Category'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Birthday').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Status'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Upcoming').last);
        await tester.pumpAndSettle();

        await tester.enterText(
            find.widgetWithText(TextFormField, 'Location'),
            'Test Location'
        );
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Description'),
            'Test Description'
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Event'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Event added successfully'), findsOneWidget);

        final eventTile = find.text('Test Event');
        expect(eventTile, findsOneWidget);
        await tester.tap(eventTile);
        await tester.pumpAndSettle();

        expect(find.text('Test Event\'s Gift List'), findsOneWidget);

        final addGiftButton = find.widgetWithText(ElevatedButton, 'Add Gift');
        expect(addGiftButton, findsOneWidget);
        await tester.tap(addGiftButton);
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBar, 'Add Gift'), findsOneWidget);

        await tester.enterText(
            find.widgetWithText(TextFormField, 'Gift Name'),
            'Test Gift'
        );
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Description'),
            'Test Gift Description'
        );
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Category'),
            'Electronics'
        );
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Price'),
            '99.99'
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save Gift'));
        await tester.pumpAndSettle();

        expect(find.text('Test Event\'s Gift List'), findsOneWidget);
        expect(find.text('Test Gift'), findsOneWidget);
      });
    });

    testWidgets('login, add friend, view and pledge gifts flow', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(const MyApp(testing: true));
        await tester.pumpAndSettle();

        // === Login Flow ===
        expect(find.text('Login'), findsOneWidget);

        await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            'mazen2002w@gmail.com'
        );
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Password'),
            'mazen123w'
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('Friends'), findsOneWidget);

        // === Add New Friend ===
        final addFriendFAB = find.byType(FloatingActionButton);
        expect(addFriendFAB, findsOneWidget);
        await tester.tap(addFriendFAB);
        await tester.pumpAndSettle();

        expect(find.text('Add Friend'), findsOneWidget);

        final emailField = find.byType(TextField);
        expect(emailField, findsOneWidget);

        await tester.enterText(emailField, 'mazen200@gmail.com');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Add'));
        await tester.pumpAndSettle();

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(find.text('Friend added successfully!'), findsOneWidget);

        final friendTile = find.widgetWithText(ListTile, 'mazen200@gmail.com');
        expect(friendTile, findsOneWidget);
        await tester.tap(friendTile);
        await tester.pumpAndSettle();

        expect(find.text('mazen200@gmail.com\'s Events'), findsOneWidget);

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Debug prints for available widgets
        print('=== Available Text Widgets ===');
        tester.allWidgets.forEach((widget) {
          if (widget is Text) {
            print('Found Text widget: ${widget.data}');
          }
        });

        final eventFinder = find.text('Test Event');
        expect(eventFinder, findsWidgets, reason: 'No Test Event found on screen');
        await tester.tap(eventFinder.first);

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        print('=== Text Widgets After Navigation ===');
        tester.allWidgets.forEach((widget) {
          if (widget is Text) {
            print('Found Text widget: ${widget.data}');
          }
        });

        expect(find.text('mazen200@gmail.com\'s Gift List'), findsOneWidget);

        final pledgeButton = find.widgetWithText(TextButton, 'Pledge');
        expect(pledgeButton, findsWidgets);

        await tester.tap(pledgeButton.first);
        await tester.pumpAndSettle();

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(find.text('Pledged'), findsWidgets);

        final viewPledgedGiftsButton = find.byIcon(Icons.card_giftcard);
        expect(viewPledgedGiftsButton, findsOneWidget);
        await tester.tap(viewPledgedGiftsButton);
        await tester.pumpAndSettle();

        expect(find.text('My Pledged Gifts'), findsOneWidget);
        expect(find.text('Test Gift'), findsOneWidget);
      });
    });
  });
}