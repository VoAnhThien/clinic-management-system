import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../constants.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchAppointments();
    });
  }

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
      body: authProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 64,
                          color: AppColors.textLight.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'Bạn chưa có lịch hẹn khám nào.',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textLight),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => authProvider.fetchAppointments(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appt = appointments[index];
                      return _buildAppointmentCard(
                          context, appt, authProvider);
                    },
                  ),
                ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context,
      Map<String, dynamic> appt, AuthProvider authProvider) {
    final status = appt['status'] ?? '';
    final bool isConfirmed = status == 'CONFIRMED';
    final bool isCompleted = status == 'COMPLETED';
    final bool isCancelled = status == 'CANCELLED';

    // Handle both mock and real API field names
    final doctorName = appt['doctorName'] ??
        appt['doctor']?['fullName'] ?? '';
    final specName = appt['specializationName'] ??
        appt['doctor']?['specializationName'] ??
        appt['doctor']?['specialization']?['name'] ?? '';
    final clinicName = appt['clinicName'] ??
        appt['clinic']?['name'] ?? '';
    final date = appt['date'] ?? appt['appointmentDate'] ?? '';
    final time = appt['time'] ??
        '${appt['timeSlot']?['startTime'] ?? ''}'
            '${appt['timeSlot']?['endTime'] != null ? ' - ${appt['timeSlot']['endTime']}' : ''}';
    final patientName = appt['patientName'] ??
        appt['patient']?['fullName'] ?? '';
    final reason = appt['reason'] ?? '';
    final code = appt['code'] ?? appt['appointmentCode'] ?? '';
    final apptId = appt['id']?.toString() ?? '';

    Color statusColor;
    String statusLabel;
    if (isCompleted) {
      statusColor = AppColors.success;
      statusLabel = 'Đã hoàn thành';
    } else if (isConfirmed) {
      statusColor = AppColors.primary;
      statusLabel = 'Đã xác nhận';
    } else if (isCancelled) {
      statusColor = AppColors.danger;
      statusLabel = 'Đã hủy';
    } else {
      statusColor = Colors.orange;
      statusLabel = 'Chờ xác nhận';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  code.isNotEmpty ? 'Mã phiếu: $code' : 'ID: $apptId',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textLight),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              doctorName,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(specName,
                style: const TextStyle(
                    color: AppColors.textLight, fontSize: 13)),
            const SizedBox(height: 12),
            if (clinicName.isNotEmpty)
              _buildInfoRow(Icons.location_on_outlined, clinicName),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textDark)),
                  if (time.isNotEmpty) ...[
                    const SizedBox(width: 20),
                    const Icon(Icons.access_time_outlined,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textDark)),
                  ],
                ],
              ),
            ],
            if (patientName.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.person_outline,
                  'Bệnh nhân: $patientName',
                  bold: true),
            ],
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.description_outlined, 'Lý do: $reason',
                  isLight: true),
            ],
            if (isConfirmed) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        _showCancelDialog(context, apptId, authProvider),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Hủy Lịch Hẹn',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text,
      {bool bold = false, bool isLight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isLight ? AppColors.textLight : AppColors.textDark,
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context, String apptId,
      AuthProvider authProvider) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hủy Lịch Hẹn?',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Bạn có chắc chắn muốn hủy lịch hẹn này? Hành động này không thể hoàn tác.'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'Lý do hủy (tùy chọn)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Quay Lại',
                  style: TextStyle(color: AppColors.textLight)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await authProvider.cancelAppointment(
                  apptId,
                  reasonController.text.isNotEmpty
                      ? reasonController.text
                      : 'Bệnh nhân hủy lịch',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Đã hủy lịch hẹn thành công!'
                          : 'Hủy lịch thất bại. Vui lòng thử lại.'),
                      backgroundColor:
                          success ? AppColors.success : AppColors.danger,
                    ),
                  );
                }
              },
              child: const Text('Đồng Ý Hủy',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}