class Student {
  final String id;
  final String name;
  final String rollNo;
  final String email;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.email,
  });

  factory Student.fromFirestore(Map<String, dynamic> data, String id) {
    return Student(
      id: id,
      name: data['name'] ?? '',
      rollNo: data['rollNo'] ?? '',
      email: data['email'] ?? '',
    );
  }
}
