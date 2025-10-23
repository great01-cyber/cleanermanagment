class TrainingVideo {
  final String id;
  final String title;
  final String description;
  final String category;
  final String videoUrl;// Firebase Storage URL
  final String thumbnailUrl;    // Firebase Storage URL
  final String duration;        // "45 seconds"
  final String uploadedBy;     // Admin/Supervisor ID
  final String uploadedByName; // Admin/Supervisor name
  final DateTime uploadedAt;
  final bool isActive;
  final int viewCount;
  final String categoryId;



  TrainingVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.uploadedAt,
    this.isActive = true,
    this.viewCount = 0,
    required this.categoryId,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'categoryId': categoryId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'uploadedAt': uploadedAt,
      'isActive': isActive,
      'viewCount': viewCount,
    };
  }

  // Create from Firestore document
  factory TrainingVideo.fromMap(Map<String, dynamic> map) {
    return TrainingVideo(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      categoryId: map['categoryId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      duration: map['duration'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedByName: map['uploadedByName'] ?? '',
      uploadedAt: map['uploadedAt']?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      viewCount: map['viewCount'] ?? 0,
    );
  }

  // Create a copy with updated fields
  TrainingVideo copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? videoUrl,
    String? thumbnailUrl,
    String? duration,
    String? uploadedBy,
    String? uploadedByName,
    DateTime? uploadedAt,
    bool? isActive,
    int? viewCount,
  }) {
    return TrainingVideo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,

      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isActive: isActive ?? this.isActive,
      viewCount: viewCount ?? this.viewCount, categoryId: '',
    );
  }

  @override
  String toString() {
    return 'TrainingVideo(id: $id, title: $title, category: $category, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrainingVideo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
