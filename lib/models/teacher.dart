class Teacher {
  final String id;
  final String name;
  final List<String> courses;

  Teacher({
    required this.id,
    required this.name,
    required this.courses,
  });

  // Convert Firestore data to Teacher object
  factory Teacher.fromFirestore(Map<String, dynamic> data, String id) {
    return Teacher(
      id: id,
      name: data['name'] ?? '',
      courses: List<String>.from(data['courses'] ?? []),
    );
  }
}
