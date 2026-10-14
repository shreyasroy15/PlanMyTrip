class AiRequestModel {
  final String id;
  final String userId;
  final String prompt;
  final String status; // 'pending', 'completed', 'failed'
  final String responseText;
  final DateTime createdAt;

  AiRequestModel({
    required this.id,
    required this.userId,
    required this.prompt,
    this.status = 'pending',
    this.responseText = '',
    required this.createdAt,
  });

  factory AiRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return AiRequestModel(
      id: id,
      userId: map['userId'] ?? '',
      prompt: map['prompt'] ?? '',
      status: map['status'] ?? 'pending',
      responseText: map['responseText'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'prompt': prompt,
      'status': status,
      'responseText': responseText,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
