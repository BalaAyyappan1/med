class TranscriptionModel {
  final int id;
  final String text;
  final String? audioFilePath;
  final DateTime createdAt;

  TranscriptionModel({
    required this.id,
    required this.text,
    this.audioFilePath,
    required this.createdAt,
  });

  factory TranscriptionModel.fromJson(Map<String, dynamic> json) {
    return TranscriptionModel(
      id: json['id'] as int,
      text: json['text'] as String,
      audioFilePath: json['audio_file_path'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'audio_file_path': audioFilePath,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
