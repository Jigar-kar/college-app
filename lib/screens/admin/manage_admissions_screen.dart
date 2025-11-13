import 'package:bca_c/services/admission_service.dart';
import 'package:bca_c/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageAdmissionsScreen extends StatefulWidget {
  const ManageAdmissionsScreen({super.key});

  @override
  State<ManageAdmissionsScreen> createState() => _ManageAdmissionsScreenState();
}

class _ManageAdmissionsScreenState extends State<ManageAdmissionsScreen>
    with SingleTickerProviderStateMixin {
  final AdmissionService _admissionService = AdmissionService();
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _admissions = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdmissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmissions() async {
    setState(() => _isLoading = true);
    try {
      final admissions = await _admissionService.getAllAdmissions();
      setState(() {
        _admissions = admissions.map((admission) {
          return {
            'id': admission['id'],
            'name': admission['name'],
            'email': admission['email'],
            'phone': admission['phone'],
            'stream': admission['stream'],
            'category': admission['category'],
            'percentage10th': admission['percentage10th'],
            'percentage12th': admission['percentage12th'],
            'status': admission['status'] ?? 'pending',
            'remarks': admission['remarks'],
            'documentUrls': admission['documentUrls'] ?? [],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading admissions: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String? admissionId, String status,
      Map<String, dynamic> admission) async {
    if (admissionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid admission ID')),
      );
      return;
    }

    try {
      String remarks = '';
      if (status == 'rejected') {
        remarks = await _showRemarksDialog() ?? '';
        if (!mounted) return;
        if (remarks.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please provide rejection remarks')),
          );
          return;
        }
      }

      await _admissionService.updateAdmissionStatus(
          admissionId, status, remarks);

      if (status == 'approved') {
        await _admissionService.createStudentFromAdmission(admission);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application $status successfully')),
      );
      _loadAdmissions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<String?> _showRemarksDialog() => showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rejection Remarks'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Enter reason for rejection',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _controller.text.isEmpty
                      ? null
                      : _controller.text, // Handle empty case
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      );

  Future<void> _viewDocuments(List<String> urls) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Documents'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: urls
                .map((url) => ListTile(
                      leading: const Icon(Icons.file_present),
                      title: Text(url.split('/').last),
                      onTap: () => launchUrl(Uri.parse(url)),
                    ))
                .toList(),
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

  Widget _buildAdmissionCard(Map<String, dynamic> admission) {
    final status = admission['status'] as String? ?? 'pending';
    final isRejected = status == 'rejected';
    final isPending = status == 'pending';
    final admissionId = admission['id'] as String?;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor.withOpacity(0.1),
                      Colors.white,
                    ],
                  ),
                ),
                child: ExpansionTile(
                  title: Text(
                    admission['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Status: ${status.toUpperCase()}',
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Email', admission['email'] ?? 'N/A'),
                          _buildInfoRow('Phone', admission['phone'] ?? 'N/A'),
                          _buildInfoRow('Stream', admission['stream'] ?? 'N/A'),
                          _buildInfoRow(
                              'Category', admission['category'] ?? 'N/A'),
                          _buildInfoRow(
                              '10th %',
                              (admission['percentage10th']?.toString() ??
                                  'N/A')),
                          _buildInfoRow(
                              '12th %',
                              (admission['percentage12th']?.toString() ??
                                  'N/A')),
                          if (isRejected)
                            _buildInfoRow(
                                'Remarks', admission['remarks'] ?? 'N/A'),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                width: 150,
                                child: ElevatedButton.icon(
                                  onPressed: () => _viewDocuments(
                                    List<String>.from(
                                        admission['documentUrls'] ?? []),
                                  ),
                                  icon: const Icon(Icons.file_present),
                                  label: const Text('View Documents'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              if (isPending) ...[
                                SizedBox(
                                  width: 120,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _updateStatus(
                                      admissionId,
                                      'approved',
                                      admission,
                                    ),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _updateStatus(
                                      admissionId,
                                      'rejected',
                                      admission,
                                    ),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Reject'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.error;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
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
                            'Manage Admissions',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Review and process admission applications',
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
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primaryColor,
                  tabs: const [
                    Tab(text: 'Pending'),
                    Tab(text: 'Approved'),
                    Tab(text: 'Rejected'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children:
                              ['pending', 'approved', 'rejected'].map((status) {
                            final filteredAdmissions = _admissions
                                .where((a) => a['status'] == status)
                                .toList();
                            return filteredAdmissions.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.folder_open,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No $status applications',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(top: 16),
                                    itemCount: filteredAdmissions.length,
                                    itemBuilder: (context, index) =>
                                        _buildAdmissionCard(
                                            filteredAdmissions[index]),
                                  );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAdmissions,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
