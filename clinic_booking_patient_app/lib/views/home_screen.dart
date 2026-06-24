import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../constants.dart';
import 'booking_screen.dart';
import 'doctors_screen.dart';
import 'main_navigation.dart';
import 'payments_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Fetch home data if not loaded yet
    if (authProvider.isLoggedIn && !authProvider.homeDataLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        authProvider.fetchHomeData();
      });
    }

    final user = authProvider.userProfile;
    final nextAppt = authProvider.appointments.isNotEmpty
        ? authProvider.appointments.first
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => authProvider.fetchHomeData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, user),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    if (nextAppt != null) ...[
                      _buildActiveAppointmentCard(context, nextAppt),
                      const SizedBox(height: 24),
                    ],
                    _buildHealthTrackers(),
                    const SizedBox(height: 24),
                    _buildFeaturedDoctors(context, authProvider),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic>? user) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding:
          const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chào mừng bạn,',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        user?['fullName'] ?? 'Bệnh nhân',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_none_outlined,
                        color: Colors.white, size: 28),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child:
                            const SizedBox(width: 4, height: 4),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Không có thông báo mới.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DoctorsScreen()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Tìm bác sĩ, chuyên khoa, phòng khám...',
                    hintStyle: TextStyle(
                        color: AppColors.textLight, fontSize: 14),
                    prefixIcon: Icon(Icons.search,
                        color: AppColors.textLight),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dịch vụ của tôi',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionItem(
                context,
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                label: 'Đặt lịch khám',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (context) => const BookingScreen())),
              ),
              _buildActionItem(
                context,
                icon: Icons.assignment_outlined,
                color: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF10B981),
                label: 'Hồ sơ bệnh án',
                onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const MainNavigation(initialTab: 2))),
              ),
              _buildActionItem(
                context,
                icon: Icons.payment_rounded,
                color: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFF97316),
                label: 'Thanh toán',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (context) => const PaymentsScreen())),
              ),
              _buildActionItem(
                context,
                icon: Icons.people_outline_rounded,
                color: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF8B5CF6),
                label: 'Đặt lịch hộ',
                onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const MainNavigation(initialTab: 3))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAppointmentCard(
      BuildContext context, Map<String, dynamic> appt) {
    final status = appt['status'] ?? '';
    final bool isConfirmed = status == 'CONFIRMED';

    // Handle both mock and real API field names
    final doctorName = appt['doctorName'] ??
        appt['doctor']?['fullName'] ?? '';
    final specName = appt['specializationName'] ??
        appt['doctor']?['specializationName'] ?? '';
    final date = appt['date'] ?? appt['appointmentDate'] ?? '';
    final time = appt['time'] ??
        '${appt['timeSlot']?['startTime'] ?? ''} - ${appt['timeSlot']?['endTime'] ?? ''}';
    final code = appt['code'] ?? appt['appointmentCode'] ?? appt['id'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E64D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lịch hẹn sắp tới',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConfirmed ? AppColors.success : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isConfirmed ? 'Đã xác nhận' : 'Đang xử lý',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(doctorName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(specName,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13)),
          const Divider(color: Colors.white24, height: 24),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(date,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(time,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã phiếu: $code',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const MainNavigation(initialTab: 1))),
                child: const Row(
                  children: [
                    Text('Chi tiết',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Icon(Icons.chevron_right,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTrackers() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chỉ số sức khỏe hôm nay',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              TextButton(
                onPressed: () {},
                child: const Text('Xem lịch sử',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTrackerCard(
                  color: const Color(0xFFFEF2F2),
                  icon: Icons.favorite_rounded,
                  iconColor: AppColors.danger,
                  title: 'Nhịp tim',
                  value: '78 bpm',
                  status: 'Bình thường',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrackerCard(
                  color: const Color(0xFFEFF6FF),
                  icon: Icons.compress_rounded,
                  iconColor: AppColors.primary,
                  title: 'Huyết áp',
                  value: '120/80 mmHg',
                  status: 'Tốt',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerCard({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(status,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: iconColor.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildFeaturedDoctors(
      BuildContext context, AuthProvider authProvider) {
    final docs = authProvider.featuredDoctors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bác sĩ nổi bật',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DoctorsScreen())),
              child: const Text('Xem tất cả',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (docs.isEmpty)
          Container(
            height: 120,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.primary),
          )
        else
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final avatarUrl =
                    doc['avatarUrl'] ?? doc['avatar'] ?? '';
                final specName = doc['specializationName'] ??
                    doc['specialization']?['name'] ?? '';
                final rating =
                    (doc['rating'] ?? 0.0).toDouble();

                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: avatarUrl.isNotEmpty
                            ? Image.network(
                                avatarUrl,
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person,
                                      color: AppColors.primary, size: 30),
                                ),
                              )
                            : Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person,
                                    color: AppColors.primary, size: 30),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        doc['fullName'] ?? '',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(specName,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textLight)),
                      if (rating > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 12),
                            Text(rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BookingScreen(preselectedDoctor: doc),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          minimumSize: const Size(0, 28),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Đặt lịch',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}