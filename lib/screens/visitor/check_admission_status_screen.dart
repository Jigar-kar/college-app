import 'package:flutter/material.dart';
import 'package:bca_c/services/admission_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckAdmissionStatusScreen extends StatefulWidget {
  const CheckAdmissionStatusScreen({super.key});

  @override
  State<CheckAdmissionStatusScreen> createState() =>
      _CheckAdmissionStatusScreenState();
}

class _CheckAdmissionStatusScreenState extends State<CheckAdmissionStatusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _admissionService = AdmissionService();
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      _applications = await _admissionService.getUserAdmissions(_emailController.text);
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewDocuments(List<String> urls) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Documents'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: urls.map((url) => ListTile(
              leading: const Icon(Icons.file_present),
              title: Text(url.split('/').last),
              onTap: () => launchUrl(Uri.parse(url)),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final status = application['status'] as String;
    final statusColor = {
      'pending': Colors.orange,
      'approved': Colors.green,
      'rejected': Colors.red,
    }[status] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Application ID: ${application['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Submitted on: ${application['submittedAt'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Stream: ${application['stream']}'),
            if (status == 'rejected') ...[
              const SizedBox(height: 16),
              const Text(
                'Remarks:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(application['remarks'] ?? 'No remarks provided'),
            ],
            if (status == 'approved') ...[
              const SizedBox(height: 16),
              const Text(
                'Congratulations! Your application has been approved.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Please visit the college with your original documents for admission.',
                style: TextStyle(color: Colors.green),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _viewDocuments(
                  List<String>.from(application['documentUrls'] ?? []),
                ),
                icon: const Icon(Icons.file_present),
                label: const Text('View Submitted Documents'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Admission Status'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter your email';
                          }
                          if (!value!.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _checkStatus,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Check Status'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_applications.isNotEmpty)
              ...(_applications.map(_buildApplicationCard).toList())
            else if (!_isLoading && _emailController.text.isNotEmpty)
              const Center(
                child: Text(
                  'No applications found for this email',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
