import 'package:bca_c/services/ranker_service.dart';
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

class AdminRankerScreen extends StatefulWidget {
  const AdminRankerScreen({super.key});

  @override
  State<AdminRankerScreen> createState() => _AdminRankerScreenState();
}

class _AdminRankerScreenState extends State<AdminRankerScreen> {
  final RankerService _rankerService = RankerService();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _percentageController = TextEditingController();

  String selectedClass = 'FY';
  String selectedRank = '1st';
  bool isLoading = false;

  final List<String> classes = ['FY', 'SY', 'TY'];
  final List<String> ranks = ['1st', '2nd', '3rd'];

  Future<void> _fetchTopPerformer() async {
    if (_yearController.text.trim().isEmpty) return;
    
    setState(() => isLoading = true);
    try {
      final topPerformer = await _rankerService.getTopPerformer(
        selectedClass,
        _yearController.text.trim(),
      );

      if (topPerformer != null) {
        setState(() {
          _rollNoController.text = topPerformer['rollNo'];
          _percentageController.text = topPerformer['percentage'].toString();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching top performer: $e"),
          backgroundColor: AppColors.absentColor,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _addRanker() async {
    final String className = selectedClass;
    final String year = _yearController.text.trim();
    final String rollNo = _rollNoController.text.trim();
    final double? percentage =
        double.tryParse(_percentageController.text.trim());

    // Rank is now passed as String from dropdown
    final String rank = selectedRank;

    if (year.isEmpty || rollNo.isEmpty || percentage == null || rank.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields correctly"),
          backgroundColor: AppColors.absentColor,
        ),
      );
      return;
    }

    try {
      await _rankerService.addRanker(
        className: className,
        year: year,
        rollNo: rollNo,
        percentage: percentage,
        rank: rank, // Pass rank as String
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ranker added successfully!"),
          backgroundColor: AppColors.presentColor,
        ),
      );
      _clearInputs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: AppColors.absentColor,
        ),
      );
    }
  }

  void _clearInputs() {
    _yearController.clear();
    _rollNoController.clear();
    _percentageController.clear();
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
                      "Add Rankers",
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextFieldCard(
                            controller: _yearController,
                            title: 'Year',
                            keyboardType: TextInputType.number,
                            icon: Icons.calendar_today,
                            onChanged: (value) {
                              if (value.isNotEmpty && selectedClass.isNotEmpty) {
                                _fetchTopPerformer();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownCard(
                            title: 'Select Class',
                            value: selectedClass,
                            items: classes,
                            onChanged: (value) {
                              setState(() {
                                selectedClass = value!;
                              });
                              if (_yearController.text.isNotEmpty) {
                                _fetchTopPerformer();
                              }
                            },
                            icon: Icons.class_,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownCard(
                            title: 'Select Rank',
                            value: selectedRank,
                            items: ranks,
                            onChanged: (value) {
                              setState(() {
                                selectedRank = value!;
                              });
                            },
                            icon: Icons.emoji_events,
                          ),
                          const SizedBox(height: 16),
                          _buildTextFieldCard(
                            controller: _rollNoController,
                            title: 'Roll Number',
                            keyboardType: TextInputType.number,
                            icon: Icons.numbers,
                          ),
                          const SizedBox(height: 16),
                          _buildTextFieldCard(
                            controller: _percentageController,
                            title: 'Percentage',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            icon: Icons.percent,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _addRanker,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.presentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Add Ranker',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
    required String value,
    required List<String> items,
    required void Function(String?)? onChanged,
    required IconData icon,
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
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  hint: Text(title),
                  isExpanded: true,
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
                ),
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
    required TextInputType keyboardType,
    required IconData icon,
    void Function(String)? onChanged,
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
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
