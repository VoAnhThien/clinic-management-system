import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../constants.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appointments = authProvider.appointments;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch Hẹn Của Tôi'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: appointments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_outlined, size: 64, color: AppColors.textLight.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn chưa có lịch hẹn khám nào.',
                    style: TextStyle(fontSize: 15, color: AppColors.textLight),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];
                final bool isConfirmed = appt['status'] == 'CONFIRMED';
                final bool isCompleted = appt['status'] == 'COMPLETED';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mã phiếu: ${appt['code']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppColors.success.withOpacity(0.1)
                                    : (isConfirmed ? AppColors.primary.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isCompleted
                                    ? 'Đã hoàn thành'
                                    : (isConfirmed ? 'Đã xác nhận' : 'Chờ xác nhận'),
                                style: TextStyle(
                                  color: isCompleted
                                      ? AppColors.success
                                      : (isConfirmed ? AppColors.primary : Colors.orange),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          appt['doctorName'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appt['specializationName'] ?? '',
                          style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                appt['clinicName'] ?? '',
                                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              appt['date'] ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                            ),
                            const SizedBox(width: 20),
                            const Icon(Icons.access_time_outlined, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              appt['time'] ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Bệnh nhân: ${appt['patientName']}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (appt['reason'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.description_outlined, color: AppColors.primary, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lý do: ${appt['reason']}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (isConfirmed) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  _showCancelDialog(context, appt['code']);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  minimumSize: const Size(0, 36),
                                ),
                                child: const Text('Hủy Lịch Hẹn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showCancelDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hủy Lịch Hẹn?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Bạn có chắc chắn muốn hủy lịch hẹn khám bệnh có mã phiếu $code không? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay Lại', style: TextStyle(color: AppColors.textLight)),
            ),
            TextButton(
              onPressed: () {
                // Mock cancel action
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã gửi yêu cầu hủy lịch hẹn $code thành công!'), backgroundColor: AppColors.success),
                );
              },
              child: const Text('Đồng Ý Hủy', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
