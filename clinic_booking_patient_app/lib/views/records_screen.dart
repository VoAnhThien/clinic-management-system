import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../constants.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  Map<String, dynamic>? _selectedProfile; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecords();
    });
  }

  Future<void> _loadRecords() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.fetchMedicalRecords(
        patientId: _selectedProfile?['id']?.toString());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userProfile;
    final relatives = authProvider.familyMembers;
    final records = authProvider.medicalRecords;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hồ Sơ Sức Khỏe'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildPatientFilterBar(user, relatives),
          Expanded(
            child: authProvider.isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_late_outlined,
                                size: 64,
                                color: AppColors.textLight.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'Chưa có dữ liệu hồ sơ khám bệnh.',
                              style: TextStyle(
                                  fontSize: 15, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: records.length,
                          itemBuilder: (context, index) =>
                              _buildRecordCard(context, records[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientFilterBar(
      Map<String, dynamic>? user,
      List<Map<String, dynamic>> relatives) {
    return Container(
      color: Colors.white,
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Self
          GestureDetector(
            onTap: () async {
              setState(() => _selectedProfile = null);
              await _loadRecords();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedProfile == null
                    ? AppColors.primary
                    : AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  user?['fullName'] ?? 'Bản thân',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _selectedProfile == null
                        ? Colors.white
                        : AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
          // Family members
          ...relatives.map((rel) {
            final isSelected =
                _selectedProfile?['id'] == rel['id'];
            return GestureDetector(
              onTap: () async {
                setState(() => _selectedProfile = rel);
                await _loadRecords();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    rel['fullName'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecordCard(
      BuildContext context, Map<String, dynamic> record) {
    // Handle both mock and real API field names
    final doctorName = record['doctorName'] ??
        record['doctor']?['fullName'] ?? '';
    final date = record['date'] ??
        record['visitDate'] ??
        record['createdAt']?.toString().substring(0, 10) ?? '';
    final diagnosis = record['diagnosis'] ?? record['diagnose'] ?? 'Khám bệnh';
    final chiefComplaint =
        record['chiefComplaint'] ?? record['symptoms'] ?? 'Không ghi nhận';
    final treatmentPlan =
        record['treatmentPlan'] ?? record['treatment'] ?? 'Không ghi nhận';
    final prescription =
        record['prescription'] ?? record['prescriptions'] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          diagnosis,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textDark),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Bác sĩ: $doctorName',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textLight)),
            Text('Ngày khám: $date',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textLight)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 16),
                _buildSection('Triệu chứng chính:', chiefComplaint),
                const SizedBox(height: 16),
                _buildSection('Kế hoạch điều trị:', treatmentPlan),
                if (prescription is List && prescription.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đơn thuốc kê toa:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primary)),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showReminderDialog(context, prescription),
                        icon: const Icon(Icons.alarm, size: 16),
                        label: const Text('Nhắc uống thuốc',
                            style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.secondary.withOpacity(0.1),
                          foregroundColor: AppColors.secondary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          minimumSize: const Size(0, 30),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: prescription.length,
                    itemBuilder: (context, idx) {
                      final item = prescription[idx];
                      final medName = item['name'] ??
                          item['medicineName'] ??
                          item['drugName'] ?? '';
                      final quantity =
                          item['quantity'] ?? item['amount'] ?? '';
                      final dosage = item['dosage'] ??
                          item['instruction'] ??
                          item['usage'] ?? '';
                      final duration =
                          item['duration'] ?? item['days'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${idx + 1}. $medName',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.textDark),
                                  ),
                                ),
                                if (quantity.toString().isNotEmpty)
                                  Text(
                                    'SL: $quantity',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppColors.textLight),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (dosage.isNotEmpty)
                              Text('Cách dùng: $dosage',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textLight)),
                            if (duration.toString().isNotEmpty)
                              Text('Thời gian: $duration',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textLight)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textDark)),
        const SizedBox(height: 4),
        Text(content,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textLight)),
      ],
    );
  }

  void _showReminderDialog(
      BuildContext context, List<dynamic> prescription) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.alarm, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Nhắc Lịch Uống Thuốc',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Hệ thống sẽ gửi thông báo đẩy nhắc nhở uống thuốc theo khung giờ kê đơn:'),
              const SizedBox(height: 16),
              ...prescription.map((item) {
                final medName = item['name'] ??
                    item['medicineName'] ??
                    item['drugName'] ?? '';
                final dosage = item['dosage'] ??
                    item['instruction'] ??
                    item['usage'] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$medName${dosage.isNotEmpty ? ' - $dosage' : ''}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bỏ qua',
                  style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Đã thiết lập nhắc nhở uống thuốc tự động thành công!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: const Text('Kích Hoạt',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}