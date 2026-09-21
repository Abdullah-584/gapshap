import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapshap/features/auth/presentation/providers/auth_provider.dart';
import 'package:gapshap/features/chat/presentation/providers/chat_provider.dart';

class TestTypingNotifier extends TypingNotifier {
  TestTypingNotifier(super.ref, super.conversationId)
      : super(enableRealtime: false) {
    state = {'user-2'};
  }
}

void main() {
  test('typing provider tracks active typing users without a live realtime connection', () {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        typingProvider('conv1').overrideWith(
          (ref) => TestTypingNotifier(ref, 'conv1'),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(typingProvider('conv1')), {'user-2'});
  });
}
