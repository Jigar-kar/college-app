class AdmissionForm {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String gender;
  final DateTime dateOfBirth;
  final String fatherName;
  final String motherName;
  final String lastSchool;
  final String board;
  final double percentage10th;
  final double percentage12th;
  final List<String> documents;
  final String category;
  final String stream;

  AdmissionForm({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.gender,
    required this.dateOfBirth,
    required this.fatherName,
    required this.motherName,
    required this.lastSchool,
    required this.board,
    required this.percentage10th,
    required this.percentage12th,
    required this.documents,
    required this.category,
    required this.stream,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'gender': gender,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'fatherName': fatherName,
      'motherName': motherName,
      'lastSchool': lastSchool,
      'board': board,
      'percentage10th': percentage10th,
      'percentage12th': percentage12th,
      'documents': documents,
      'category': category,
      'stream': stream,
      'status': 'pending',
      'submittedAt': DateTime.now().toIso8601String(),
    };
  }

  factory AdmissionForm.fromJson(Map<String, dynamic> json) {
    return AdmissionForm(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      gender: json['gender'] ?? '',
      dateOfBirth: DateTime.parse(json['dateOfBirth'] ?? DateTime.now().toIso8601String()),
      fatherName: json['fatherName'] ?? '',
      motherName: json['motherName'] ?? '',
      lastSchool: json['lastSchool'] ?? '',
      board: json['board'] ?? '',
      percentage10th: json['percentage10th']?.toDouble() ?? 0.0,
      percentage12th: json['percentage12th']?.toDouble() ?? 0.0,
      documents: List<String>.from(json['documents'] ?? []),
      category: json['category'] ?? '',
      stream: json['stream'] ?? '',
    );
  }
}
