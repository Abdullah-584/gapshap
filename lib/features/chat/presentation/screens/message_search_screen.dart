import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'dart:async';
import '../../../../core/theme/app_colors.dart';



class MessageSearchScreen extends StatefulWidget {
  final String conversationId;
  const MessageSearchScreen({super.key, required this.conversationId});

  @override
  State<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends State<MessageSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _search(query);
      } else {
        setState(() {
          _results = [];
          _hasSearched = false;
        });
      }
    });
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('*, sender:profiles!messages_sender_id_fkey(display_name, avatar_url)')
          .eq('conversation_id', widget.conversationId)
          .ilike('content', '%$query%')
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _results = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search messages...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.textSecondaryDark),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (v) {
            if (v.isNotEmpty) _search(v);
          },
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _results.isEmpty && _hasSearched
              ? const Center(
                  child: Text('No messages found',
                      style: TextStyle(color: AppColors.textSecondaryDark)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final msg = _results[index];
                    final sender = msg['sender'] as Map<String, dynamic>?;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceDark,
                        ),
                        child: sender?['avatar_url'] != null
                            ? ClipOval(
                                child: Image.network(sender!['avatar_url'],
                                    fit: BoxFit.cover),
                              )
                            : const Icon(Icons.person,
                                color: AppColors.textSecondaryDark, size: 20),
                      ),
                      title: Text(
                        msg['content'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${sender?['display_name'] ?? ''} • ${msg['created_at'] != null ? timeago.format(DateTime.parse(msg['created_at'])) : ''}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryDark),
                      ),
                    );
                  },
                ),
    );
  }
}
