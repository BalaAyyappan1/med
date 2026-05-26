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
  Timer? _timer;

  SpeechController(this._speechService);

  // Getters
  List<TranscriptionModel> get transcriptions => _transcriptions;
  bool get isRecording => _isRecording;
  bool get isTranscribing => _isTranscribing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get recordDuration => _recordDuration;

  /// Loads previous transcriptions from the backend database.
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

  /// Starts recording audio.
  Future<void> startRecording() async {
    try {
      _errorMessage = null;
      
      // Request and verify microphone permissions
      if (await _audioRecorder.hasPermission()) {
        String? filePath;
        
        // Only run path_provider on mobile/desktop. On Web, record to memory/blob.
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          filePath = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        // Configure recording parameters (standard AAC format)
        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
        );

        // Start recording
        await _audioRecorder.start(config, path: filePath ?? '');
        
        _isRecording = true;
        _recordDuration = 0;
        
        // Start seconds counter timer
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _recordDuration++;
          notifyListeners();
        });

        notifyListeners();
      } else {
        _errorMessage = "Microphone permission is required to record audio.";
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Failed to start recording: ${e.toString()}";
      _isRecording = false;
      _timer?.cancel();
      notifyListeners();
    }
  }

  /// Stops recording audio and automatically triggers file upload to backend.
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _timer?.cancel();
    _isRecording = false;
    _isTranscribing = true;
    notifyListeners();

    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        debugPrint('Recording stopped. File saved to or Blob URL: $path');
        
        TranscriptionModel newTranscription;
        
        // Handle web uploads differently (Blobs) than mobile files
        if (kIsWeb) {
          final bytes = await _speechService.fetchBlobBytes(path);
          newTranscription = await _speechService.uploadAudioBytes(bytes, filename: 'audio.m4a');
        } else {
          newTranscription = await _speechService.uploadAudio(path);
        }
        
        // Add to the top of our local list
        _transcriptions.insert(0, newTranscription);
      } else {
        _errorMessage = "No audio file recorded.";
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error during transcription process: $e');
    } finally {
      _isTranscribing = false;
      _recordDuration = 0;
      notifyListeners();
    }
  }

  /// Helper to format the record duration into MM:SS format.
  String get formattedDuration {
    final minutes = (_recordDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
