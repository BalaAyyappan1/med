import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transcription_model.dart';

class TranscriptionCard extends StatelessWidget {
  final TranscriptionModel transcription;

  const TranscriptionCard({
    super.key,
    required this.transcription,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(transcription.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate-800
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF334155), // Slate-700
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header: Icon + Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF312E81), // Indigo-900/100
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.keyboard_voice_rounded,
                          color: Color(0xFF818CF8), // Indigo-400
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Voice Entry #${transcription.id}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8), // Slate-400
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Card Body: Text
              SelectableText(
                transcription.text,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9), // Slate-100
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              // Footer: Audio File info if present
              if (transcription.audioFilePath != null) ...[
                const SizedBox(height: 12),
                Divider(color: const Color(0xFF334155), thickness: 0.5),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.audiotrack_rounded,
                      color: Color(0xFF10B981), // Emerald-500
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        transcription.audioFilePath!.split('/').last,
                        style: const TextStyle(
                          color: Color(0xFF64748B), // Slate-500
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
