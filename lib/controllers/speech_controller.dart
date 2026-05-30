import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../models/transcription_model.dart';
import '../services/speech_service.dart';

class SpeechController extends ChangeNotifier {
  final SpeechService _speechService;
  final AudioRecorder _audioRecorder = AudioRecorder();

  List<TranscriptionModel> _transcriptions = [];
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _recordDuration = 0;
  Timer? _secondsTimer;
  Timer? _amplitudeTimer;

  // Broadcast stream: every subscriber always gets the latest amplitude events.
  final StreamController<double> _volumeStreamController =
      StreamController<double>.broadcast();

  SpeechController(this._speechService);

  // ── Getters ──────────────────────────────────────────────────────────────
  List<TranscriptionModel> get transcriptions => _transcriptions;
  bool get isRecording => _isRecording;
  bool get isTranscribing => _isTranscribing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get recordDuration => _recordDuration;

  /// Normalized volume stream [0.0 – 1.0].
  Stream<double> get volumeStream => _volumeStreamController.stream;

  // ── Transcription history ─────────────────────────────────────────────────
  Future<void> loadTranscriptions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _transcriptions = await _speechService.getTranscriptions();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading transcriptions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Recording ─────────────────────────────────────────────────────────────
  Future<void> startRecording() async {
    try {
      _errorMessage = null;

      if (await _audioRecorder.hasPermission()) {
        String? filePath;
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          filePath =
              '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
        );

        await _audioRecorder.start(config, path: filePath ?? '');

        _isRecording = true;
        _recordDuration = 0;

        // ── Seconds counter ───────────────────────────────────────────────
        _secondsTimer?.cancel();
        _secondsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _recordDuration++;
          notifyListeners();
        });

        // ── Amplitude polling (100ms) ─────────────────────────────────────
        // Timer-based polling is more reliable cross-platform than
        // onAmplitudeChanged which can be silent on some Windows configurations.
        _amplitudeTimer?.cancel();
        _amplitudeTimer =
            Timer.periodic(const Duration(milliseconds: 100), (_) async {
          if (!_isRecording) return;
          try {
            final amp = await _audioRecorder.getAmplitude();
            final double raw = amp.current; // dBFS, typically -160..0

            // Wide window: -80 dB silence floor → 0 dB ceiling.
            const double floor = -80.0;
            const double ceiling = 0.0;
            double normalized = 0.0;
            if (raw > floor) {
              normalized = (raw - floor) / (ceiling - floor);
              normalized = normalized.clamp(0.0, 1.0);
            }

            // Apply sqrt curve so quieter sounds are still visible.
            final double boosted = normalized <= 0 ? 0.0 : normalized;

            debugPrint(
                '[Amp] raw=${raw.toStringAsFixed(1)} dB  norm=${normalized.toStringAsFixed(2)}  boosted=${boosted.toStringAsFixed(2)}');

            if (!_volumeStreamController.isClosed) {
              _volumeStreamController.add(boosted);
            }
          } catch (e) {
            debugPrint('Amplitude error: $e');
          }
        });

        notifyListeners();
      } else {
        _errorMessage = 'Microphone permission is required to record audio.';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to start recording: ${e.toString()}';
      _isRecording = false;
      _secondsTimer?.cancel();
      _amplitudeTimer?.cancel();
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _secondsTimer?.cancel();
    _amplitudeTimer?.cancel();
    _isRecording = false;
    _isTranscribing = true;

    // Signal zero so the waveform collapses.
    if (!_volumeStreamController.isClosed) {
      _volumeStreamController.add(0.0);
    }

    notifyListeners();

    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        debugPrint('Recording saved to: $path');
        TranscriptionModel newTranscription;
        if (kIsWeb) {
          final bytes = await _speechService.fetchBlobBytes(path);
          newTranscription =
              await _speechService.uploadAudioBytes(bytes, filename: 'audio.m4a');
        } else {
          newTranscription = await _speechService.uploadAudio(path);
        }
        _transcriptions.insert(0, newTranscription);
      } else {
        _errorMessage = 'No audio file recorded.';
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Transcription error: $e');
    } finally {
      _isTranscribing = false;
      _recordDuration = 0;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get formattedDuration {
    final m = (_recordDuration ~/ 60).toString().padLeft(2, '0');
    final s = (_recordDuration % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _secondsTimer?.cancel();
    _amplitudeTimer?.cancel();
    _volumeStreamController.close();
    _audioRecorder.dispose();
    super.dispose();
  }
}
