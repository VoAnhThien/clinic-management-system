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
  String _selectedPatientId = 'pat-self';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userProfile;
    final relatives = authProvider.familyMembers;

    // Filter medical records based on patient
    // In mock data, records are for self, but we can display different messages
    final records = _selectedPatientId == 'pat-self' 
        ? MockData.medicalRecords 
        : <Map<String, dynamic>>[]; // Empty for relatives in mockup

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
          // Patient selector bar (Self & dependents)
          _buildPatientFilterBar(user, relatives),
          
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_late_outlined, size: 64, color: AppColors.textLight.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có dữ liệu hồ sơ khám bệnh.',
                          style: TextStyle(fontSize: 15, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return _buildRecordCard(context, record);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientFilterBar(Map<String, dynamic>? user, List<Map<String, dynamic>> relatives) {
    return Container(
      color: Colors.white,
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Self button
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedPatientId = 'pat-self';
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedPatientId == 'pat-self' ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  user?['fullName'] ?? 'Bản thân',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _selectedPatientId == 'pat-self' ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
          
          // Family members buttons
          ...relatives.map((rel) {
            final isSelected = _selectedPatientId == rel['id'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPatientId = rel['id'];
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    rel['fullName'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppColors.textDark,
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

  Widget _buildRecordCard(BuildContext context, Map<String, dynamic> record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          record['diagnosis'] ?? 'Khám bệnh',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Bác sĩ: ${record['doctorName']}',
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
            Text(
              'Ngày khám: ${record['date']}',
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
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
                
                // Symptom
                const Text('Triệu chứng chính:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(record['chiefComplaint'] ?? 'Không ghi nhận', style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
                const SizedBox(height: 16),
                
                // Treatment Plan
                const Text('Kế hoạch điều trị:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(record['treatmentPlan'] ?? 'Không ghi nhận', style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
                const SizedBox(height: 20),

                // Prescription Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Đơn thuốc kê toa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showReminderDialog(context, record['prescription']);
                      },
                      icon: const Icon(Icons.alarm, size: 16),
                      label: const Text('Nhắc uống thuốc', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary.withOpacity(0.1),
                        foregroundColor: AppColors.secondary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                
                // Prescription items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: (record['prescription'] as List).length,
                  itemBuilder: (context, idx) {
                    final item = record['prescription'][idx];
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${idx + 1}. ${item['name']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                              ),
                              Text(
                                'SL: ${item['quantity']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Cách dùng: ${item['dosage']}', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                              Text('Uống ${item['duration']}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textLight)),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showReminderDialog(BuildContext context, List<dynamic> prescription) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.alarm, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Nhắc Lịch Uống Thuốc', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hệ thống sẽ gửi thông báo đẩy nhắc nhở uống thuốc theo khung giờ kê đơn:'),
              const SizedBox(height: 16),
              ...prescription.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item['name']} - ${item['dosage']}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bỏ qua', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã thiết lập nhắc nhở uống thuốc tự động thành công!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Kích Hoạt', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }
}
