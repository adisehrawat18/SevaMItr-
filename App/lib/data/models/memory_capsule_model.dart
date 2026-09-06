/// Memory Capsule Model for Personalized Family Reminiscence
class MemoryCapsule {
  final int? id;
  final String title; // e.g. "Rohan's College Convocation"
  final String relationTag; // e.g. "Grandson Rohan (নাতি ৰোহণ)"
  final String photoAssetPath; // Placeholder asset or local file URI
  final String audioStoryText; // Narration text spoken by TTS or recorded voice
  final String audioStoryTextRegional; // Regional language narration
  final String recordedDateFormatted; // "15 August 2026"
  final String quizQuestion; // "Who is in this picture with you?"
  final String quizQuestionRegional; // "আপোনাৰ লগত এইখন ছবিত কোন আছে?"
  final List<String>
      quizOptions; // ["Rohan (Grandson)", "Dr. Sharma", "Neighbor Barun"]
  final int correctOptionIndex; // 0

  const MemoryCapsule({
    this.id,
    required this.title,
    required this.relationTag,
    required this.photoAssetPath,
    required this.audioStoryText,
    required this.audioStoryTextRegional,
    required this.recordedDateFormatted,
    required this.quizQuestion,
    required this.quizQuestionRegional,
    required this.quizOptions,
    required this.correctOptionIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'relationTag': relationTag,
      'photoAssetPath': photoAssetPath,
      'audioStoryText': audioStoryText,
      'audioStoryTextRegional': audioStoryTextRegional,
      'recordedDateFormatted': recordedDateFormatted,
      'quizQuestion': quizQuestion,
      'quizQuestionRegional': quizQuestionRegional,
      'quizOptions': quizOptions.join('|'),
      'correctOptionIndex': correctOptionIndex,
    };
  }

  factory MemoryCapsule.fromMap(Map<String, dynamic> map) {
    return MemoryCapsule(
      id: map['id'] as int?,
      title: map['title'] as String,
      relationTag: map['relationTag'] as String,
      photoAssetPath: map['photoAssetPath'] as String,
      audioStoryText: map['audioStoryText'] as String,
      audioStoryTextRegional: map['audioStoryTextRegional'] as String,
      recordedDateFormatted: map['recordedDateFormatted'] as String,
      quizQuestion: map['quizQuestion'] as String,
      quizQuestionRegional: map['quizQuestionRegional'] as String,
      quizOptions: (map['quizOptions'] as String).split('|'),
      correctOptionIndex: map['correctOptionIndex'] as int,
    );
  }
}
