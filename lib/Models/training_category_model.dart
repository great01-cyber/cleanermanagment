class TrainingCategory {
  final String id;
  final String name;
  final String description;
  final String iconUrl;         // Firebase Storage URL
  final int videoCount;
  final bool isActive;

  TrainingCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    this.videoCount = 0,
    this.isActive = true,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'videoCount': videoCount,
      'isActive': isActive,
    };
  }

  // Create from Firestore document
  factory TrainingCategory.fromMap(Map<String, dynamic> map) {
    return TrainingCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconUrl: map['iconUrl'] ?? '',
      videoCount: map['videoCount'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  // Create a copy with updated fields
  TrainingCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    int? videoCount,
    bool? isActive,
  }) {
    return TrainingCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      videoCount: videoCount ?? this.videoCount,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'TrainingCategory(id: $id, name: $name, videoCount: $videoCount, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrainingCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
