import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../../domain/models/message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _showEmojiPicker = false;
  Message? _replyingTo;
  Message? _editingMessage;
  String? _otherUserName;
  String? _otherUserAvatar;
  bool _otherUserOnline = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadConversationDetails();
  }

  void _loadConversationDetails() async {
    final details =
        await ref.read(conversationDetailsProvider(widget.conversationId).future);
    if (details != null && mounted) {
      final members = details['members'] as List?;
      final userId = ref.read(currentUserIdProvider);
      final otherMember = members?.firstWhere(
        (m) => m['user_id'] != userId,
        orElse: () => null,
      );
      if (otherMember != null) {
        final user = otherMember['user'] as Map<String, dynamic>?;
        setState(() {
          _otherUserName = user?['display_name'] ?? user?['username'] ?? 'Chat';
          _otherUserAvatar = user?['avatar_url'];
          _otherUserOnline = user?['is_online'] ?? false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Reached top - load more messages
      ref.read(messagesProvider(widget.conversationId).notifier).loadMore();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_editingMessage != null) {
      ref.read(messagesProvider(widget.conversationId).notifier).editMessage(
            _editingMessage!.id,
            text,
          );
      setState(() => _editingMessage = null);
    } else {
      ref.read(messagesProvider(widget.conversationId).notifier).sendTextMessage(
            content: text,
            replyToMessageId: _replyingTo?.id,
            replyToContent: _replyingTo?.content,
            replyToSenderName: _replyingTo?.senderName,
            replyToType: _replyingTo?.type,
          );
    }

    _messageController.clear();
    setState(() {
      _replyingTo = null;
      _showEmojiPicker = false;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTypingIndicator() {
    ref.read(typingProvider(widget.conversationId).notifier).sendTypingIndicator();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.conversationId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final typingUsers = ref.watch(typingProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceDark,
              ),
              child: _otherUserAvatar != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _otherUserAvatar!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Icon(Icons.person,
                            color: AppColors.textSecondaryDark, size: 20),
                        errorWidget: (_, __, ___) => const Icon(Icons.person,
                            color: AppColors.textSecondaryDark, size: 20),
                      ),
                    )
                  : const Icon(Icons.person,
                      color: AppColors.textSecondaryDark, size: 20),
            ),
            const SizedBox(width: 12),
            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUserName ?? 'Chat',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (typingUsers.isNotEmpty)
                    const Text(
                      'typing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.typing,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else
                    Text(
                      _otherUserOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: _otherUserOnline
                            ? AppColors.online
                            : AppColors.textSecondaryDark,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: () => context.push('/chat/${widget.conversationId}/search'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 22),
            color: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'info':
                  context.push('/chat/${widget.conversationId}/details');
                  break;
                case 'search':
                  context.push('/chat/${widget.conversationId}/search');
                  break;
                case 'clear':
                  _showClearChatDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'info', child: Text('Chat Info')),
              const PopupMenuItem(value: 'search', child: Text('Search')),
              const PopupMenuItem(value: 'clear', child: Text('Clear Chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: messages.when(
              data: (list) {
                if (list.isEmpty) {
                  return _buildEmptyChat();
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final message = list[index];
                    final isMe = message.senderId == currentUserId;
                    final showDateSeparator = index == 0 ||
                        !_isSameDay(
                          list[index - 1].createdAt,
                          message.createdAt,
                        );

                    return Column(
                      children: [
                        if (showDateSeparator) _buildDateSeparator(message.createdAt),
                        _MessageBubble(
                          message: message,
                          isMe: isMe,
                          onReply: () => setState(() => _replyingTo = message),
                          onReact: (emoji) => ref
                              .read(messagesProvider(widget.conversationId).notifier)
                              .addReaction(message.id, emoji),
                          onEdit: message.type == MessageType.text && isMe
                              ? () => _startEditing(message)
                              : null,
                          onDelete: () => _showDeleteDialog(message, isMe),
                          onSave: () => ref
                              .read(savedMessagesProvider.notifier)
                              .saveMessage(message.id),
                          onForward: () => context.push(
                            '/forward-message?messageId=${message.id}&content=${message.content ?? ''}',
                          ),
                          onRetry: message.status == MessageStatus.failed
                              ? () => ref
                                  .read(messagesProvider(widget.conversationId).notifier)
                                  .retryMessage(message)
                              : null,
                          onTapReplyPreview: message.replyToMessageId != null
                              ? () => _scrollToMessage(message.replyToMessageId!)
                              : null,
                        ),
                        const SizedBox(height: 2),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    const Text('Failed to load messages'),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(messagesProvider(widget.conversationId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Reply preview
          if (_replyingTo != null) _buildReplyPreview(),

          // Edit preview
          if (_editingMessage != null) _buildEditPreview(),

          // Composer
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to begin chatting',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime? date) {
    if (date == null) return const SizedBox.shrink();
    final now = DateTime.now();
    String text;
    if (_isSameDay(date, now)) {
      text = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      text = 'Yesterday';
    } else {
      text = DateFormat('MMM d, y').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.backgroundDark,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyingTo!.senderName ?? 'Reply',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingTo!.content ?? 'Attachment',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.backgroundDark,
      child: Row(
        children: [
          const Icon(Icons.edit, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editing message',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _editingMessage!.content ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _editingMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file, size: 22),
            onPressed: _showAttachmentOptions,
            color: AppColors.textSecondaryDark,
          ),
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                onChanged: (value) {
                  setState(() {});
                  // Send typing indicator with debounce
                  _typingTimer?.cancel();
                  _sendTypingIndicator();
                  _typingTimer = Timer(const Duration(seconds: 2), () {});
                },
                decoration: InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, size: 22),
                    onPressed: () {
                      setState(() => _showEmojiPicker = !_showEmojiPicker);
                      if (_showEmojiPicker) {
                        _focusNode.unfocus();
                      }
                    },
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send / Mic button
          GestureDetector(
            onTap: _messageController.text.trim().isNotEmpty
                ? _sendMessage
                : _showAttachmentOptions,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: _messageController.text.trim().isNotEmpty
                  ? const Icon(Icons.send,
                      color: AppColors.textOnPrimary, size: 20)
                  : const Icon(Icons.mic,
                      color: AppColors.textOnPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _startEditing(Message message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.content ?? '';
    });
  }

  void _scrollToMessage(String messageId) {
    final messages = ref.read(messagesProvider(widget.conversationId)).valueOrNull;
    if (messages == null) return;

    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    // Approximate scroll position
    final position = index * 80.0; // Approximate message height
    _scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _attachmentOption(
                Icons.camera_alt,
                'Camera',
                () => _pickImage(ImageSource.camera),
              ),
              _attachmentOption(
                Icons.photo_library,
                'Gallery',
                () => _pickImage(ImageSource.gallery),
              ),
              _attachmentOption(
                Icons.insert_drive_file,
                'File',
                () => _pickFile(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      // TODO: Upload image and send as message
      // For now, send as text with file path
      // In production, upload to Supabase Storage first
    }
  }

  Future<void> _pickFile() async {
    // TODO: Implement file picker
  }

  void _showDeleteDialog(Message message, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete for me'),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(messagesProvider(widget.conversationId).notifier)
                      .deleteMessageForMe(message.id);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppColors.error),
                  title: const Text('Delete for everyone'),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(messagesProvider(widget.conversationId).notifier)
                        .deleteMessage(message.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('This will delete all messages in this chat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear chat
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ═══════════════════════════════════════════════
// Message Bubble Widget
// ═══════════════════════════════════════════════

class _MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback onReply;
  final Function(String) onReact;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final VoidCallback onForward;
  final VoidCallback? onRetry;
  final VoidCallback? onTapReplyPreview;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.onReact,
    this.onEdit,
    required this.onDelete,
    required this.onSave,
    required this.onForward,
    this.onRetry,
    this.onTapReplyPreview,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {


  @override
  Widget build(BuildContext context) {
    final msg = widget.message;

    if (msg.isDeleted) {
      return _buildDeletedMessage();
    }

    return GestureDetector(
      onLongPress: _showContextMenu,
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment:
                widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Reply preview
              if (msg.replyToMessageId != null) _buildReplyPreview(msg),
              // Bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.isMe
                      ? AppColors.outgoingBubbleLight
                      : AppColors.incomingBubbleLight,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                    bottomRight: Radius.circular(widget.isMe ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text content
                    if (msg.content != null)
                      Text(
                        msg.content!,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: widget.isMe
                              ? AppColors.textOnPrimary
                              : AppColors.textPrimaryLight,
                          height: 1.35,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Time and status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (msg.isEdited)
                          Text(
                            'edited  ',
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.isMe
                                  ? AppColors.textOnPrimary.withValues(alpha: 0.6)
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        Text(
                          msg.createdAt != null
                              ? DateFormat('HH:mm').format(msg.createdAt!)
                              : '',
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isMe
                                ? AppColors.textOnPrimary.withValues(alpha: 0.6)
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        if (widget.isMe) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(msg.status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Reactions
              if (msg.reactions.isNotEmpty) _buildReactions(msg),
              // Retry button for failed messages
              if (msg.status == MessageStatus.failed && widget.onRetry != null)
                GestureDetector(
                  onTap: widget.onRetry,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 14, color: AppColors.error),
                        SizedBox(width: 4),
                        Text(
                          'Failed. Tap to retry.',
                          style: TextStyle(fontSize: 11, color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedMessage() {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 14, color: AppColors.textSecondaryDark),
            const SizedBox(width: 6),
            Text(
              'Message deleted',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(Message msg) {
    return GestureDetector(
      onTap: widget.onTapReplyPreview,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isMe
              ? AppColors.primaryDark.withValues(alpha: 0.3)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.replyToSenderName ?? '',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              msg.replyToContent ?? 'Attachment',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white54,
          ),
        );
      case MessageStatus.sent:
        return Icon(Icons.check, size: 14,
            color: AppColors.textOnPrimary.withValues(alpha: 0.6));
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 14,
            color: AppColors.textOnPrimary.withValues(alpha: 0.6));
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: AppColors.error);
    }
  }

  Widget _buildReactions(Message msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: msg.reactions.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.divider,
                width: 0.5,
              ),
            ),
            child: Text(
              '${entry.key} ${entry.value.length}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showContextMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reactions
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: AppConstants.defaultReactions.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onReact(emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.reply, size: 22),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                widget.onReply();
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward, size: 22),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                widget.onForward();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, size: 22),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(
                    ClipboardData(text: widget.message.content ?? ''));
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add, size: 22),
              title: const Text('Save'),
              onTap: () {
                Navigator.pop(context);
                widget.onSave();
              },
            ),
            if (widget.onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit, size: 22),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, size: 22,
                  color: AppColors.error),
              title: const Text('Delete',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
