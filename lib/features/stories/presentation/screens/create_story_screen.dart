import '../../../../core/extensions/context_extensions.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../providers/stories_provider.dart';
import '../../domain/models/story.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  StoryType _selectedType = StoryType.text;
  String? _mediaPath;
  
  final _captionController = TextEditingController();
  final _textController = TextEditingController();
  String _backgroundColor = '#1A1A1A';
  bool _isUploading = false;

  final List<String> _backgroundColors = [
    '#1A1A1A',
    '#2D1F1F',
    '#1F2D1F',
    '#1F1F2D',
    '#2D2D1F',
    '#2D1F2D',
    '#0D0D0D',
    '#333333',
  ];

  @override
  void dispose() {
    _captionController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, StoryType type) async {
    final picker = ImagePicker();

    if (type == StoryType.image) {
      final image = await picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        setState(() {
          _mediaPath = image.path;
          _selectedType = StoryType.image;
        });
      }
    } else if (type == StoryType.video) {
      final video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 30),
      );
      if (video != null) {
        setState(() {
          _mediaPath = video.path;
          _selectedType = StoryType.video;
        });
      }
    }
  }

  Future<String?> _uploadMedia() async {
    if (_mediaPath == null) return null;

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final ext = _mediaPath!.split('.').last;
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bucket = _selectedType == StoryType.video
        ? AppConfig.storyMediaBucket
        : AppConfig.storyMediaBucket;

    try {
      await client.storage.from(bucket).upload(
            path,
            File(_mediaPath!),
            fileOptions: const FileOptions(upsert: false),
          );

      final url = client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> _publishStory() async {
    if (_selectedType == StoryType.text && _textController.text.isEmpty) {
      context.showErrorSnackBar('Please enter some text');
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? mediaUrl;
      if (_mediaPath != null) {
        mediaUrl = await _uploadMedia();
      }

      await ref.read(storiesProvider.notifier).createStory(
            type: _selectedType,
            content: _selectedType == StoryType.text ? _textController.text : null,
            mediaUrl: mediaUrl,
            caption: _captionController.text.isNotEmpty
                ? _captionController.text
                : null,
            backgroundColor: _backgroundColor,
          );

      if (mounted) {
        context.showSuccessSnackBar('Story published!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to publish story');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Create Story'),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _publishStory,
              child: const Text(
                'Publish',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildTypeChip(StoryType.image, Icons.image, 'Photo'),
                  const SizedBox(width: 8),
                  _buildTypeChip(StoryType.video, Icons.videocam, 'Video'),
                  const SizedBox(width: 8),
                  _buildTypeChip(StoryType.text, Icons.text_fields, 'Text'),
                ],
              ),
            ),

            // Content area
            if (_selectedType == StoryType.text)
              _buildTextStoryEditor()
            else
              _buildMediaPreview(),

            // Caption
            if (_selectedType != StoryType.text || _mediaPath != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _captionController,
                  decoration: const InputDecoration(
                    hintText: 'Add a caption...',
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                ),
              ),

            // Color picker for text stories
            if (_selectedType == StoryType.text)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: _backgroundColors.map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => _backgroundColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(
                              int.parse(color.replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _backgroundColor == color
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(StoryType type, IconData icon, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        if (type != StoryType.text) {
          _pickMedia(
            type == StoryType.video ? ImageSource.gallery : ImageSource.gallery,
            type,
          );
        }
        setState(() => _selectedType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondaryDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextStoryEditor() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(int.parse(_backgroundColor.replaceFirst('#', '0xFF'))),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: TextField(
            controller: _textController,
            textAlign: TextAlign.center,
            maxLines: null,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              hintText: 'Type your story...',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_mediaPath == null) {
      return GestureDetector(
        onTap: () => _pickMedia(
          _selectedType == StoryType.video
              ? ImageSource.gallery
              : ImageSource.gallery,
          _selectedType,
        ),
        child: Container(
          height: 300,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate,
                    size: 48, color: AppColors.textSecondaryDark),
                SizedBox(height: 12),
                Text('Tap to select media',
                    style: TextStyle(color: AppColors.textSecondaryDark)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: FileImage(File(_mediaPath!)),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
