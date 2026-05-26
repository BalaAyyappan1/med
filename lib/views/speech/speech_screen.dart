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
            color: const Color(0xFF6366F1).withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          // Action Label / Recording Status
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
            const SizedBox(height: 8),
            Text(
              controller.formattedDuration,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                fontSize: 32,
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
            const SizedBox(height: 12),
            const SizedBox(
              height: 28,
              width: 28,
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
            const SizedBox(height: 8),
            const Text(
              'Ready for speech to text',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Sound Wave Micro-Animation
          SoundWaveIndicator(isRecording: controller.isRecording),

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
          
          if (controller.isTranscribing) ...[
            const SizedBox(height: 16),
            const Text(
              'Whisper is processing your audio...',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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
  const SoundWaveIndicator({super.key, required this.isRecording});

  @override
  State<SoundWaveIndicator> createState() => _SoundWaveIndicatorState();
}

class _SoundWaveIndicatorState extends State<SoundWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    if (widget.isRecording) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SoundWaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(9, (index) {
            double value = 4.0;
            if (widget.isRecording) {
              // Formula creates a staggered sine wave for organic feel
              final double waveVal = math.sin((_controller.value * 2 * math.pi) + (index * 0.7));
              value = (waveVal.abs() * 32.0) + 6.0;
            }
            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 5,
              height: value,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isRecording
                      ? [const Color(0xFF818CF8), const Color(0xFF6366F1)]
                      : [const Color(0xFF475569), const Color(0xFF475569)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}
