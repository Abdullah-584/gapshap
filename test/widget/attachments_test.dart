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
    state = const AsyncValue.data([]);
  }

  @override
  Future<void> sendImageMessage({
    required String attachmentUrl,
    String? content,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
  }) async {
    final current = state.valueOrNull ?? [];
    final optimistic = Message.optimistic(
      conversationId: conversationId,
      senderId: 'user-1',
      type: MessageType.image,
      content: content ?? 'Image',
      attachmentUrl: attachmentUrl,
      senderName: 'Me',
    );
    state = AsyncValue.data([...current, optimistic]);
  }

  @override
  Future<void> sendFileMessage({
    required String attachmentUrl,
    required String attachmentName,
    String? attachmentMimeType,
    int? attachmentSize,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
  }) async {
    final current = state.valueOrNull ?? [];
    final optimistic = Message.optimistic(
      conversationId: conversationId,
      senderId: 'user-1',
      type: MessageType.file,
      content: attachmentName,
      attachmentUrl: attachmentUrl,
      senderName: 'Me',
    );
    state = AsyncValue.data([...current, optimistic]);
  }
}

void main() {
  testWidgets('image attachment appears in chat', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        currentProfileProvider.overrideWith((ref) => TestProfileNotifier(ref)),
        conversationDetailsProvider('conv1').overrideWith(
          (ref) async => {
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
          },
        ),
        typingProvider('conv1').overrideWith(
          (ref) => TypingNotifier(ref, 'conv1', enableRealtime: false),
        ),
        messagesProvider(
          'conv1',
        ).overrideWith((ref) => TestMessagesNotifier(ref, 'conv1')),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChatScreen(conversationId: 'conv1')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Send image (via notifier directly)
    await container
        .read(messagesProvider('conv1').notifier)
        .sendImageMessage(
          attachmentUrl: 'http://example.com/image.jpg',
          content: 'Photo1',
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Photo1'), findsOneWidget);
  });

  testWidgets('file attachment appears in chat', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        currentProfileProvider.overrideWith((ref) => TestProfileNotifier(ref)),
        conversationDetailsProvider('conv1').overrideWith(
          (ref) async => {
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
          },
        ),
        typingProvider('conv1').overrideWith(
          (ref) => TypingNotifier(ref, 'conv1', enableRealtime: false),
        ),
        messagesProvider(
          'conv1',
        ).overrideWith((ref) => TestMessagesNotifier(ref, 'conv1')),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChatScreen(conversationId: 'conv1')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await container
        .read(messagesProvider('conv1').notifier)
        .sendFileMessage(
          attachmentUrl: 'http://example.com/file.pdf',
          attachmentName: 'file.pdf',
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('file.pdf'), findsOneWidget);
  });
}
