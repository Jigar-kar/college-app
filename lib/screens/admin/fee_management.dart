import 'package:bca_c/components/loader.dart';
import 'package:bca_c/services/user_service.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color presentColor = Color(0xFF4CAF50);
  static const Color absentColor = Color(0xFFE53935);
  static const Color cardBg = Color(0xFFFAFAFA);
}

class FeeManagement extends StatefulWidget {
  const FeeManagement({super.key});

  @override
  _FeeManagementState createState() => _FeeManagementState();
}

class _FeeManagementState extends State<FeeManagement> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  String rollNo = '';
  double feeAmount = 0.0;
  String feeStatus = 'paid'; // Default status
  String selectedClass = 'FY';
  bool isLoading = false;

  // Method to handle fee addition
  void _addFee() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        await _userService.addFee(rollNo, feeAmount, feeStatus, selectedClass);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fee added successfully!'),
            backgroundColor: AppColors.presentColor,
          ),
        );

        setState(() {
          rollNo = '';
          feeAmount = 0.0;
          feeStatus = 'paid'; // Reset to default status
          selectedClass = 'FY';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding fee: $e'),
            backgroundColor: AppColors.absentColor,
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Fee Management",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextFieldCard(
                              controller: TextEditingController(text: rollNo),
                              title: 'Roll No',
                              icon: Icons.person,
                              validator: (val) => val!.isEmpty ? 'Enter roll number' : null,
                              onChanged: (val) => rollNo = val,
                            ),
                            const SizedBox(height: 16),
                            _buildTextFieldCard(
                              controller: TextEditingController(text: feeAmount.toString()),
                              title: 'Fee Amount',
                              icon: Icons.monetization_on,
                              validator: (val) => val!.isEmpty ? 'Enter fee amount' : null,
                              onChanged: (val) => feeAmount = double.tryParse(val) ?? 0.0,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownCard(
                              title: 'Class',
                              value: selectedClass,
                              items: ['FY', 'SY', 'TY'],
                              onChanged: (val) {
                                setState(() {
                                  selectedClass = val!;
                                });
                              },
                              icon: Icons.class_,
                              validator: (val) => val == null ? 'Select a class' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownCard(
                              title: 'Fee Status',
                              value: feeStatus,
                              items: ['paid', 'unpaid', 'overdue'],
                              onChanged: (val) {
                                setState(() {
                                  feeStatus = val!;
                                });
                              },
                              icon: Icons.payment,
                              validator: (val) => val == null ? 'Select fee status' : null,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: isLoading ? null : _addFee,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.presentColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              child: isLoading
                                  ? const Loader()
                                  : const Text(
                                      "Add Fee",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownCard({
    required String title,
    required dynamic value,
    required List<String> items,
    required void Function(String?)? onChanged,
    required IconData icon,
    required String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: value,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                hint: Text(title),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                dropdownColor: Colors.white,
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
                validator: validator,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldCard({
    required TextEditingController controller,
    required String title,
    required IconData icon,
    required String? Function(String?)? validator,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: title,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                validator: validator,
                onChanged: onChanged,
                keyboardType: keyboardType,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
