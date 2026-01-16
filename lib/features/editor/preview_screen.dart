import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/permissions.dart';
import '../../shared/widgets/primary_button.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.videoPath});

  final String videoPath;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late final VideoPlayerController _controller;
  bool _isSaving = false;

  double _trimStart = 0;
  double _trimEnd = 1;
  


  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {
          _trimEnd = _controller.value.duration.inMilliseconds.toDouble();
        });
        _controller.addListener(_handlePlayback);
      });
  }

  @override
  void dispose() {
    _controller.removeListener(_handlePlayback);
    _controller.dispose();
    super.dispose();
  }

  void _handlePlayback() {
    final position = _controller.value.position.inMilliseconds.toDouble();
    if (position >= _trimEnd && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  Future<void> _togglePlayback() async {
    if (!_controller.value.isInitialized) {
      return;
    }
    final start = Duration(milliseconds: _trimStart.toInt());
    final end = Duration(milliseconds: _trimEnd.toInt());
    if (_controller.value.position < start ||
        _controller.value.position > end) {
      await _controller.seekTo(start);
    }
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
    setState(() {});
  }

  Future<void> _saveVideo() async {
    if (_isSaving) {
      return;
    }
    final granted = await Permissions.requestStorage();
    if (!granted) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final file = await FileUtils.copyToExports(widget.videoPath);
      await GallerySaver.saveVideo(file.path);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to gallery')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview & Edit'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: AppColors.deepSpace,
                      child: _controller.value.isInitialized
                          ? GestureDetector(
                              onTap: _togglePlayback,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Colors.transparent,
                                      BlendMode.srcOver,
                                    ),
                                    child: AspectRatio(
                                      aspectRatio:
                                          _controller.value.aspectRatio,
                                      child: VideoPlayer(_controller),
                                    ),
                                  ),
                                  if (!_controller.value.isPlaying)
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkGlass,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: AppColors.softWhite,
                                        size: 32,
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : const Center(
                              child: CircularProgressIndicator(),
                            ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trim range',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    RangeSlider(
                      values: RangeValues(_trimStart, _trimEnd),
                      min: 0,
                      max: _controller.value.isInitialized
                          ? _controller.value.duration.inMilliseconds.toDouble()
                          : 1,
                      onChanged: _controller.value.isInitialized
                          ? (values) {
                              setState(() {
                                _trimStart = values.start;
                                _trimEnd = values.end;
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: _isSaving ? 'Saving...' : 'Save clip',
                            icon: Icons.download_rounded,
                            onPressed: _isSaving ? null : _saveVideo,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            label: _controller.value.isPlaying
                                ? 'Pause'
                                : 'Play',
                            icon: _controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            isFilled: false,
                            onPressed: _togglePlayback,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
