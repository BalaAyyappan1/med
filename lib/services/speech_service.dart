import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/transcription_model.dart';

class SpeechService {
  final ApiClient _apiClient;

  SpeechService(this._apiClient);

  /// Uploads an audio file for transcription and returns the created database record (Mobile/Desktop).
  Future<TranscriptionModel> uploadAudio(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        '/transcribe',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> json = response.data;
        return TranscriptionModel.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to transcribe audio. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while transcribing audio: $e');
    }
  }

  /// Uploads raw audio bytes (Web compatibility).
  Future<TranscriptionModel> uploadAudioBytes(List<int> bytes, {required String filename}) async {
    try {
      final formData = FormData.fromMap({
        'audio': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
      });

      final response = await _apiClient.dio.post(
        '/transcribe',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> json = response.data;
        return TranscriptionModel.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to transcribe audio. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while transcribing audio bytes: $e');
    }
  }

  /// Fetches raw bytes from a browser blob URL (Web compatibility).
  Future<List<int>> fetchBlobBytes(String blobUrl) async {
    try {
      final response = await Dio().get<List<int>>(
        blobUrl,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );
      if (response.data != null) {
        return response.data!;
      }
      throw Exception('Failed to read blob bytes');
    } catch (e) {
      throw Exception('Error resolving Web audio blob: $e');
    }
  }

  /// Fetches the transcription history.
  Future<List<TranscriptionModel>> getTranscriptions() async {
    try {
      final response = await _apiClient.dio.get('/transcriptions');

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = response.data;
        final List<dynamic> data = json['data'] as List<dynamic>;
        
        return data
            .map((item) => TranscriptionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch transcriptions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while fetching transcriptions: $e');
    }
  }
}
