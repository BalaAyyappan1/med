import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/speech_controller.dart';
import 'widgets/record_button.dart';
import 'widgets/transcription_card.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  @override
  void initState() {
    super.initState();
    // Load history when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpeechController>().loadTranscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SpeechController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep slate background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Whisper Transcribe MVP',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              
              // Error Banner
              if (controller.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF991B1B), // Dark red
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          controller.errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 16),
                        onPressed: controller.clearError,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

              // Recording Control Center
              _buildControlCenter(controller),

              const SizedBox(height: 24),

              // History Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transcription History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF818CF8)),
                    onPressed: controller.loadTranscriptions,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // History List / Loader / Empty Placeholder
              Expanded(
                child: _buildHistorySection(controller),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlCenter(SpeechController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate-800
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF334155), // Slate-700
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 30,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          // Action Label / Recording Status
          // Fixed height container for top status section to avoid height shifts
          SizedBox(
            height: 64,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (controller.isRecording) ...[
                    const Text(
                      'RECORDING AUDIO',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        fontSize: 28,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ] else if (controller.isTranscribing) ...[
                    const Text(
                      'TRANSCRIBING',
                      style: TextStyle(
                        color: Color(0xFFF59E0B), // Amber-500
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Color(0xFFF59E0B),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'TAP MIC TO RECORD',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready for speech to text',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sound Wave Micro-Animation (connected to real-time voice amplitude)
          SoundWaveIndicator(
            isRecording: controller.isRecording,
            volumeStream: controller.volumeStream,
          ),

          const SizedBox(height: 28),

          // Record Trigger Button
          RecordButton(
            isRecording: controller.isRecording,
            onTap: () {
              if (controller.isRecording) {
                controller.stopRecording();
              } else {
                controller.startRecording();
              }
            },
          ),
          
          // Fixed slot for transcribing text to prevent the main card from jumping or resizing
          Opacity(
            opacity: controller.isTranscribing ? 1.0 : 0.0,
            child: const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Whisper is processing your audio...',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(SpeechController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      );
    }

    if (controller.transcriptions.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic_none_outlined,
                size: 64,
                color: const Color(0xFF475569), // Slate-600
              ),
              const SizedBox(height: 16),
              const Text(
                'No recordings yet',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your transcribed text will appear here.',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: controller.transcriptions.length,
      itemBuilder: (context, index) {
        return TranscriptionCard(
          transcription: controller.transcriptions[index],
        );
      },
    );
  }
}

class SoundWaveIndicator extends StatefulWidget {
  final bool isRecording;
  final Stream<double> volumeStream;

  const SoundWaveIndicator({
    super.key,
    required this.isRecording,
    required this.volumeStream,
  });

  @override
  State<SoundWaveIndicator> createState() => _SoundWaveIndicatorState();
}

class _SoundWaveIndicatorState extends State<SoundWaveIndicator>
    with SingleTickerProviderStateMixin {
  // Drives the wave SHAPE — always looping when recording.
  late AnimationController _waveController;
  // Drives the wave SCALE from the real microphone amplitude.
  double _amplitude = 0.0;
  StreamSubscription<double>? _sub;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isRecording) _waveController.repeat();
    _listenToVolume();
  }

  @override
  void didUpdateWidget(covariant SoundWaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start/stop the wave animation controller.
    if (widget.isRecording && !oldWidget.isRecording) {
      _waveController.repeat();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _waveController.stop();
      _waveController.reset();
      // Collapse amplitude immediately.
      setState(() => _amplitude = 0.0);
    }

    // Re-subscribe if the stream reference changes.
    if (widget.volumeStream != oldWidget.volumeStream) {
      _sub?.cancel();
      _listenToVolume();
    }
  }

  void _listenToVolume() {
    _sub = widget.volumeStream.listen((vol) {
      if (!mounted) return;
      setState(() => _amplitude = vol);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(9, (i) {
              double barHeight;
              if (widget.isRecording) {
                // Each bar uses its own sine phase so bars look like a wave.
                // Idle amplitude (0.12) ensures bars always breathe slightly.
                final double phase =
                    (_waveController.value * 2 * 3.1415926) + (i * 0.75);
                final double sine = (math.sin(phase) + 1) / 2; // 0.0 – 1.0
                final double effectiveAmp = 0.12 + (_amplitude * 0.88);
                barHeight = (effectiveAmp * 40.0 * sine) + 4.0;
              } else {
                barHeight = 4.0;
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 5,
                height: barHeight.clamp(4.0, 48.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isRecording
                        ? [const Color(0xFFA5B4FC), const Color(0xFF6366F1)]
                        : [const Color(0xFF334155), const Color(0xFF334155)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
