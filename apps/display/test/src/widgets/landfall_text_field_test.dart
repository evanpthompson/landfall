import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:display/src/widgets/landfall_text_field.dart';

void main() {
  group('LandfallTextField', () {
    testWidgets(
      'invokes TextInput.show when the field gains focus',
      (tester) async {
        // Fire TV regression: a focused TextField does not summon the
        // Amazon IME automatically. We force the show via the platform
        // channel so the wizard is completable from the remote.
        final calls = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.textInput,
          (call) async {
            calls.add(call);
            return null;
          },
        );

        final node = FocusNode();
        addTearDown(node.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LandfallTextField(focusNode: node),
            ),
          ),
        );

        node.requestFocus();
        await tester.pump();

        expect(
          calls.any((c) => c.method == 'TextInput.show'),
          isTrue,
          reason: 'TextInput.show must be invoked when focus is gained.',
        );
      },
    );

    testWidgets(
      'does not invoke TextInput.show when not focused',
      (tester) async {
        final calls = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.textInput,
          (call) async {
            calls.add(call);
            return null;
          },
        );

        final node = FocusNode();
        addTearDown(node.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LandfallTextField(focusNode: node),
            ),
          ),
        );
        await tester.pump();

        expect(
          calls.any((c) => c.method == 'TextInput.show'),
          isFalse,
        );
      },
    );
  });
}
