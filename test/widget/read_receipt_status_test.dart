import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapshap/features/auth/domain/models/app_user.dart';
import 'package:gapshap/features/auth/presentation/providers/auth_provider.dart';
import 'package:gapshap/features/chat/domain/models/message.dart';
import 'package:gapshap/features/chat/presentation/providers/chat_provider.dart';
import 'package:gapshap/features/chat/presentation/screens/chat_screen.dart';

class TestProfileNotifier extends ProfileNotifier {
  TestProfileNotifier(super.ref) : super(autoLoad: false) {
    state = AsyncValue.data(
      const AppProfile(id: 'user-1', username: 'me', displayName: 'Me'),
    );
  }
}

class TestMessagesNotifier extends MessagesNotifier {
  TestMessagesNotifier(super.ref, super.conversationId) : super(autoLoad: false) {
    state = AsyncValue.data([
      Message(
        id: 'msg-1',
        conversationId: conversationId,
        senderId: 'user-1',
        type: MessageType.text,
        content: 'Seen by the other user',
        status: MessageStatus.read,
        createdAt: DateTime.now(),
        senderName: 'Me',
      ),
    ]);
  }
}

class TestTypingNotifier extends TypingNotifier {
  TestTypingNotifier(super.ref, super.conversationId)
    : super(enableRealtime: false) {
    state = {};
  }
}

void main() {
  testWidgets(
    'read receipt status shows in outgoing message bubble',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            currentProfileProvider.overrideWith(
              (ref) => TestProfileNotifier(ref),
            ),
            conversationDetailsProvider('conv1').overrideWith((ref) async {
              return {
                'id': 'conv1',
                'members': [
                  {'user_id': 'user-1'},
                  {
                    'user_id': 'user-2',
                    'user': {
                      'display_name': 'Jane',
                      'username': 'jane',
                      'avatar_url': null,
                      'is_online': true,
                    },
                  },
                ],
              };
            }),
            messagesProvider(
              'conv1',
            ).overrideWith((ref) => TestMessagesNotifier(ref, 'conv1')),
            typingProvider(
              'conv1',
            ).overrideWith((ref) => TestTypingNotifier(ref, 'conv1')),
          ],
          child: const MaterialApp(home: ChatScreen(conversationId: 'conv1')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Seen by the other user'), findsOneWidget);
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
