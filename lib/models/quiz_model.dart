class QuizModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final String difficulty;
  final String topic;

  QuizModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.difficulty,
    required this.topic,
  });

  factory QuizModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return QuizModel(
      id: id,
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
      difficulty: map['difficulty'] ?? 'Easy',
      topic: map['topic'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'difficulty': difficulty,
      'topic': topic,
    };
  }
}