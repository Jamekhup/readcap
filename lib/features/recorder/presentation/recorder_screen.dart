import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/permissions.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/slider_control.dart';
import '../../editor/preview_screen.dart';

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _showCountdown = false;
  int _countdown = 3;
  bool _isInitializingCamera = false;
  String? _cameraError;
  bool _isStartingRecording = false;

  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  String _scriptText =
      'Welcome to Readcap. Paste your script here, set the pace, and record.';
  double _fontSize = 18;
  double _scrollSpeed = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _scrollTimer?.cancel();
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    _scrollController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializingCamera) {
      return;
    }
    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
      _isCameraReady = false;
    });
    try {
      final granted = await Permissions.requestCameraAndMic();
      if (!granted) {
        setState(() {
          _cameraError = 'Camera or microphone permission denied.';
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No camera found on this device.';
        });
        return;
      }
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
      });
    } catch (error) {
      setState(() {
        _cameraError = 'Camera failed to start: $error';
      });
    } finally {
      setState(() {
        _isInitializingCamera = false;
      });
    }
  }

  void _startCountdown() {
    if (_isRecording || !_isCameraReady) {
      if (_cameraError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_cameraError!)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera is not ready yet.')),
        );
      }
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _countdown = 3;
      _showCountdown = true;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() {
          _showCountdown = false;
          _isStartingRecording = true;
        });
        _startRecording();
      } else {
        setState(() {
          _countdown -= 1;
        });
      }
    });
  }

  Future<void> _startRecording() async {
    if (_cameraController == null) {
      return;
    }
    try {
      await WakelockPlus.enable();
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingDuration = Duration.zero;
        _isStartingRecording = false;
      });
      _startRecordingTimer();
      _startTeleprompter();
    } catch (error) {
      setState(() {
        _isStartingRecording = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Recording failed: $error')));
    }
  }

  Future<void> _pauseRecording() async {
    if (_cameraController == null || !_isRecording || _isPaused) {
      return;
    }
    await _cameraController!.pauseVideoRecording();
    setState(() {
      _isPaused = true;
    });
    _stopRecordingTimer();
    _stopTeleprompter();
  }

  Future<void> _resumeRecording() async {
    if (_cameraController == null || !_isRecording || !_isPaused) {
      return;
    }
    await _cameraController!.resumeVideoRecording();
    setState(() {
      _isPaused = false;
    });
    _startRecordingTimer();
    _startTeleprompter();
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_isRecording) {
      return;
    }
    final file = await _cameraController!.stopVideoRecording();
    _stopTeleprompter();
    _stopRecordingTimer();
    await WakelockPlus.disable();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _isStartingRecording = false;
    });
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PreviewScreen(videoPath: file.path)),
    );
  }

  void _startTeleprompter() {
    _scrollTimer?.cancel();
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTeleprompter());
      return;
    }
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (_scrollController.offset >= maxExtent) {
        return;
      }
      final delta = _scrollSpeed / 60;
      _scrollController.jumpTo(
        (_scrollController.offset + delta).clamp(0, maxExtent),
      );
    });
  }

  void _stopTeleprompter() {
    _scrollTimer?.cancel();
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRecording || _isPaused) {
        return;
      }
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_showCountdown) {
      content = _buildCountdownView(context);
    } else if (_isRecording || _isStartingRecording) {
      content = _buildRecordingView(context);
    } else {
      content = _buildSetupView(context);
    }
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: SafeArea(child: content),
        ),
      ),
    );
  }

  Widget _buildSetupView(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Image.asset(
            'assets/logo.png',
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                TextField(
                  maxLines: 12,
                  minLines: 6,
                  textInputAction: TextInputAction.newline,
                  onChanged: (value) => setState(() => _scriptText = value),
                  decoration: const InputDecoration(
                    hintText: 'Paste your teleprompter script here...',
                  ),
                ),
                const SizedBox(height: 16),
                SliderControl(
                  label: 'Font size',
                  value: _fontSize,
                  min: 14,
                  max: 54,
                  onChanged: (value) => setState(() => _fontSize = value),
                ),
                const SizedBox(height: 8),
                SliderControl(
                  label: 'Scroll speed',
                  value: _scrollSpeed,
                  min: 10,
                  max: 120,
                  suffix: ' px/s',
                  onChanged: (value) => setState(() => _scrollSpeed = value),
                ),
                const SizedBox(height: 24),
                if (_cameraError != null)
                  Column(
                    children: [
                      Text(
                        _cameraError!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.coolGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: Permissions.openSettings,
                        child: const Text('Open Settings'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Start',
                    icon: Icons.play_arrow,
                    onPressed: _startCountdown,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownView(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(_countdown),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.accentGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.neonPink.withOpacity(0.4),
                blurRadius: 24,
              ),
            ],
          ),
          child: Text(
            '$_countdown',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 72,
              color: AppColors.softWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingView(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _isCameraReady && _cameraController != null
              ? CameraPreview(_cameraController!)
              : Container(
                  color: AppColors.deepSpace,
                  alignment: Alignment.center,
                  child: _isInitializingCamera
                      ? const CircularProgressIndicator()
                      : const Icon(
                          Icons.videocam_off,
                          color: AppColors.coolGray,
                          size: 48,
                        ),
                ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 72),
              decoration: const BoxDecoration(color: AppColors.darkGlass),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Text(
                  _scriptText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: _fontSize,
                    height: 1.4,
                    color: AppColors.softWhite,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.darkGlass,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDuration(_recordingDuration),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.darkGlass,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.neonOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'REC',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.neonOrange),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: _isPaused ? 'Resume' : 'Pause',
                    icon: _isPaused ? Icons.play_arrow : Icons.pause,
                    isFilled: false,
                    onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Finish',
                    icon: Icons.stop,
                    onPressed: _stopRecording,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
