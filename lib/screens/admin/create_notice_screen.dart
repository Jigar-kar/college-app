import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color gradientStart = Color(0xFF303F9F);
  static const Color gradientEnd = Color(0xFF1976D2);
  static const Color cardBg = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color error = Colors.red;
  static const Color success = Colors.green;
}

class CreateNoticeScreen extends StatefulWidget {
  const CreateNoticeScreen({super.key});

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _priority = 'medium';
  bool _isLoading = false;

  Future<void> _submitNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('admin_notices').add({
        'title': _titleController.text,
        'content': _contentController.text,
        'priority': _priority,
        'postedBy': 'admin',
        'postedDate': Timestamp.now(),
        'isActive': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notice posted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting notice: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInputContainer({required Widget child}) {
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: child,
      ),
    );
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Create Notice",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Post a new notice for students",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
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
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInputContainer(
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Notice Title',
                                labelStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.title,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Title is required' : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInputContainer(
                            child: DropdownButtonFormField<String>(
                              value: _priority,
                              decoration: const InputDecoration(
                                labelText: 'Priority Level',
                                labelStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.priority_high,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'high',
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_upward,
                                          color: Colors.red[700], size: 20),
                                      const SizedBox(width: 8),
                                      Text('HIGH',
                                          style:
                                              TextStyle(color: Colors.red[700])),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'medium',
                                  child: Row(
                                    children: [
                                      Icon(Icons.remove,
                                          color: Colors.orange[700], size: 20),
                                      const SizedBox(width: 8),
                                      Text('MEDIUM',
                                          style: TextStyle(
                                              color: Colors.orange[700])),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'low',
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_downward,
                                          color: Colors.green[700], size: 20),
                                      const SizedBox(width: 8),
                                      Text('LOW',
                                          style: TextStyle(
                                              color: Colors.green[700])),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _priority = value!),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInputContainer(
                            child: TextFormField(
                              controller: _contentController,
                              decoration: const InputDecoration(
                                labelText: 'Notice Content',
                                labelStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.description,
                                  color: AppColors.primaryColor,
                                ),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 5,
                              validator: (v) => v?.isEmpty == true
                                  ? 'Content is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitNotice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Post Notice',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
}
