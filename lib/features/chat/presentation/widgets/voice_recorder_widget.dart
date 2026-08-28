import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// Voice recorder widget
class VoiceRecorderWidget extends StatefulWidget {
  final Function(File file, Duration duration) onRecordComplete;
  final VoidCallback? onCancel;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordComplete,
    this.onCancel,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _duration = Duration.zero;
  Timer? _timer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        setState(() => _isRecording = true);
        _startTimer();
      }
    } catch (e) {
      widget.onCancel?.call();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration = Duration(seconds: _duration.inSeconds + 1);
      });
    });
  }

  Future<void> _pauseRecording() async {
    if (_isRecording && !_isPaused) {
      await _recorder.pause();
      _timer?.cancel();
      setState(() => _isPaused = true);
    }
  }

  Future<void> _resumeRecording() async {
    if (_isRecording && _isPaused) {
      await _recorder.resume();
      _startTimer();
      setState(() => _isPaused = false);
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();

    if (path != null && mounted) {
      final file = File(path);
      widget.onRecordComplete(file, _duration);
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();

    if (path != null) {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    }

    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          GestureDetector(
            onTap: _cancelRecording,
            child: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 24),
          ),
          const SizedBox(width: 12),

          // Waveform visualization
          Expanded(
            child: Row(
              children: [
                // Recording indicator
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: 10,
                      height: 10 + (_animationController.value * 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording && !_isPaused
                            ? AppColors.error
                            : AppColors.textSecondaryDark,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),

                // Timer
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isRecording && !_isPaused
                        ? AppColors.error
                        : AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(width: 12),

                // Waveform bars
                Expanded(
                  child: _buildWaveform(),
                ),
              ],
            ),
          ),

          // Pause/Resume
          GestureDetector(
            onTap: _isPaused ? _resumeRecording : _pauseRecording,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceDark,
              ),
              child: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: AppColors.textPrimaryDark,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Send
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(Icons.send,
                  color: AppColors.textOnPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(40, (index) {
        final height = (4 + (index % 5) * 2.0 + (index % 3) * 1.5);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 2,
          height: _isRecording && !_isPaused ? height : 2,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  String _formatDuration(Duration duration) {
    final mins = duration.inMinutes.toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

/// Voice message player widget
class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final Duration? duration;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    this.duration,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.textOnPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform
                Row(
                  children: List.generate(25, (i) {
                    return Container(
                      width: 2,
                      height: (3 + (i % 4) * 2).toDouble(),
                      margin: const EdgeInsets.symmetric(horizontal: 0.8),
                      decoration: BoxDecoration(
                        color: i < 12
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(_currentPosition)} / ${_formatTime(widget.duration ?? Duration.zero)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _togglePlayback() {
    setState(() => _isPlaying = !_isPlaying);
    // In production, use audioplayers package to play the audio
  }

  String _formatTime(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
