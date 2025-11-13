// ignore_for_file: file_names

import 'package:bca_c/services/user_service.dart'; // Import UserService for fee-related functionality

class FeeService {
  final UserService _userService = UserService();

  Future<List<Map<String, dynamic>>> getFees() async {
    return await _userService.getFees();
  }
  
}
