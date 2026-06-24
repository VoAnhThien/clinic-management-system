import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../auth_provider.dart';
import '../constants.dart';
import 'main_navigation.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic>? preselectedDoctor;
  const BookingScreen({super.key, this.preselectedDoctor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _currentStep = 0;

  Map<String, dynamic>? _selectedSpecialty;
  Map<String, dynamic>? _selectedDoctor;
  String? _selectedDate; // yyyy-MM-dd format for API
  String? _selectedDateDisplay; // Display format
  Map<String, dynamic>? _selectedTimeSlot;
  Map<String, dynamic>? _selectedPatient;
  String _paymentMethod = 'CASH';
  final _reasonController = TextEditingController();

  // API-loaded data
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _availableSlots = [];
  List<String> _availableDates = []; // dates from schedules

  bool _loadingDoctors = false;
  bool _loadingSlots = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedDoctor != null) {
      _selectedDoctor = widget.preselectedDoctor;
      _currentStep = 2;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSchedulesForDoctor();
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────

  Future<void> _loadDoctorsForSpecialty() async {
    if (_selectedSpecialty == null) return;
    setState(() => _loadingDoctors = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final docs = await authProvider.fetchDoctors(
      specializationId: _selectedSpecialty!['id']?.toString(),
    );
    setState(() {
      _doctors = docs;
      _loadingDoctors = false;
    });
  }

  Future<void> _loadSchedulesForDoctor() async {
    if (_selectedDoctor == null) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final doctorId = _selectedDoctor!['id']?.toString() ?? '';
    final schedules = await authProvider.fetchDoctorSchedules(doctorId);

    // Extract available dates from schedules
    final dates = <String>[];
    for (final sched in schedules) {
      final dateStr = sched['workDate'] ?? sched['date'] ?? '';
      if (dateStr.isNotEmpty && !dates.contains(dateStr)) {
        dates.add(dateStr);
      }
    }

    // If no schedules from API, generate next 7 working days as fallback
    if (dates.isEmpty) {
      final now = DateTime.now();
      for (int i = 1; i <= 14; i++) {
        final d = now.add(Duration(days: i));
        if (d.weekday != DateTime.sunday) {
          dates.add(DateFormat('yyyy-MM-dd').format(d));
        }
        if (dates.length >= 7) break;
      }
    }

    setState(() {
      _availableDates = dates;
      _selectedDate = null;
      _selectedDateDisplay = null;
      _availableSlots = [];
      _selectedTimeSlot = null;
    });
  }

  Future<void> _loadSlotsForDate(String date) async {
    if (_selectedDoctor == null) return;
    setState(() => _loadingSlots = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final doctorId = _selectedDoctor!['id']?.toString() ?? '';
    final slots = await authProvider.fetchAvailableSlots(doctorId, date);
    setState(() {
      _availableSlots = slots;
      _selectedTimeSlot = null;
      _loadingSlots = false;
    });
  }

  // ── Navigation ────────────────────────────────────────────

  void _nextStep() {
    if (_currentStep == 0 && _selectedSpecialty == null) {
      _showWarning('Vui lòng chọn chuyên khoa');
      return;
    }
    if (_currentStep == 1 && _selectedDoctor == null) {
      _showWarning('Vui lòng chọn bác sĩ');
      return;
    }
    if (_currentStep == 2 &&
        (_selectedDate == null || _selectedTimeSlot == null)) {
      _showWarning('Vui lòng chọn ngày và giờ khám');
      return;
    }
    if (_currentStep == 3 && _selectedPatient == null) {
      _showWarning('Vui lòng chọn hồ sơ bệnh nhân');
      return;
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.warning),
    );
  }

  Future<void> _confirmBooking(AuthProvider authProvider) async {
    final slotId = _selectedTimeSlot?['id']?.toString();
    final patientId = _selectedPatient?['id']?.toString();

    if (slotId == null || patientId == null) {
      _showWarning('Thiếu thông tin đặt lịch. Vui lòng kiểm tra lại.');
      return;
    }

    setState(() => _isBooking = true);

    final result = await authProvider.bookAppointment(
      timeSlotId: slotId,
      patientProfileId: patientId,
      reason: _reasonController.text,
      paymentMethod: _paymentMethod,
    );

    setState(() => _isBooking = false);

    if (result != null) {
      _showSuccessDialog();
    } else {
      _showWarning('Đặt lịch thất bại. Vui lòng thử lại hoặc chọn giờ khác.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFFECFDF5),
                child:
                    Icon(Icons.check_circle, color: AppColors.success, size: 54),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đặt Lịch Thành Công!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lịch khám của bạn đã được xác nhận. Vui lòng đến đúng giờ hẹn.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const MainNavigation(initialTab: 1)),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Xem Lịch Hẹn',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đặt Lịch Khám Bệnh'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildStepContent(authProvider),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(authProvider),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Chuyên Khoa', 'Bác Sĩ', 'Giờ Khám', 'Hồ Sơ', 'Xác Nhận'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isCurrent
                          ? AppColors.primary
                          : (isCompleted
                              ? AppColors.secondary
                              : AppColors.border),
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? Colors.white
                                    : AppColors.textLight,
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color:
                            isCurrent ? AppColors.primary : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < _currentStep
                          ? AppColors.secondary
                          : AppColors.border,
                      margin: const EdgeInsets.only(
                          bottom: 15, left: 4, right: 4),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(AuthProvider authProvider) {
    switch (_currentStep) {
      case 0:
        return _buildSpecialtySelect(authProvider);
      case 1:
        return _buildDoctorSelect();
      case 2:
        return _buildDateTimeSelect();
      case 3:
        return _buildPatientSelect(authProvider);
      case 4:
        return _buildConfirmSection();
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Specialization ────────────────────────────────

  Widget _buildSpecialtySelect(AuthProvider authProvider) {
    final specs = authProvider.specializations;

    if (specs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Chọn chuyên khoa khám bệnh',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: specs.length,
          itemBuilder: (context, index) {
            final spec = specs[index];
            final isSelected = _selectedSpecialty?['id'] == spec['id'];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.healing, color: AppColors.primary),
                ),
                title: Text(
                  spec['name'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                subtitle: Text(spec['description'] ?? '',
                    style: const TextStyle(fontSize: 12)),
                trailing: isSelected
                    ? const Icon(Icons.radio_button_checked,
                        color: AppColors.primary)
                    : const Icon(Icons.radio_button_off,
                        color: AppColors.border),
                onTap: () {
                  setState(() {
                    _selectedSpecialty = spec;
                    _selectedDoctor = null;
                    _doctors = [];
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Step 1: Doctor ────────────────────────────────────────

  Widget _buildDoctorSelect() {
    if (_loadingDoctors) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bác sĩ thuộc khoa ${_selectedSpecialty?['name']}',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        if (_doctors.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                  'Hiện khoa này chưa có lịch bác sĩ. Vui lòng quay lại sau.'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _doctors.length,
            itemBuilder: (context, index) {
              final doc = _doctors[index];
              final isSelected = _selectedDoctor?['id'] == doc['id'];
              final currencyFormat =
                  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
              final price =
                  (doc['consultationFee'] ?? doc['price'] ?? 0).toDouble();
              final rating = (doc['rating'] ?? 0.0).toDouble();
              final experience =
                  doc['experienceYears'] ?? doc['experience'] ?? 0;
              final avatarUrl = doc['avatarUrl'] ?? doc['avatar'] ?? '';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color:
                        isSelected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: avatarUrl.isNotEmpty
                                ? Image.network(avatarUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _placeholderAvatar(56))
                                : _placeholderAvatar(56),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc['fullName'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.textDark),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (rating > 0) ...[
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 12),
                                    ],
                                    const Icon(Icons.work_history,
                                        color: AppColors.textLight, size: 14),
                                    const SizedBox(width: 4),
                                    Text('$experience năm KN',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textLight)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if ((doc['biography'] ?? '').isNotEmpty)
                                  Text(
                                    doc['biography'],
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textLight),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Giá khám dịch vụ',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textLight)),
                              Text(
                                price > 0
                                    ? currencyFormat.format(price)
                                    : 'Liên hệ phòng khám',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _selectedDoctor = doc;
                                _availableDates = [];
                                _availableSlots = [];
                                _selectedDate = null;
                                _selectedTimeSlot = null;
                              });
                              await _loadSchedulesForDoctor();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(0.08),
                              foregroundColor: isSelected
                                  ? Colors.white
                                  : AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                                isSelected ? 'Đã Chọn' : 'Chọn Bác Sĩ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _placeholderAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person,
          color: AppColors.primary, size: size * 0.6),
    );
  }

  // ── Step 2: Date & Time ───────────────────────────────────

  Widget _buildDateTimeSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '1. Chọn ngày khám',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        if (_availableDates.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: const Text(
              'Không có ngày khám khả dụng cho bác sĩ này.',
              style: TextStyle(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          )
        else
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableDates.length,
              itemBuilder: (context, index) {
                final dateStr = _availableDates[index]; // yyyy-MM-dd
                final dt = DateTime.tryParse(dateStr);
                final display = dt != null
                    ? DateFormat('EEE, dd/MM', 'vi').format(dt)
                    : dateStr;
                final isSelected = _selectedDate == dateStr;

                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedDate = dateStr;
                      _selectedDateDisplay = display;
                      _selectedTimeSlot = null;
                    });
                    await _loadSlotsForDate(dateStr);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        display,
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
              },
            ),
          ),
        const SizedBox(height: 24),

        const Text(
          '2. Chọn khung giờ khám',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 12),

        if (_selectedDate == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Vui lòng chọn ngày khám trước.',
                style: TextStyle(color: AppColors.textLight),
                textAlign: TextAlign.center),
          )
        else if (_loadingSlots)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_availableSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: const Text(
              'Không còn khung giờ trống cho ngày này.',
              style: TextStyle(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          )
        else
          // Thay thế toàn bộ phần GridView.builder trong _buildDateTimeSelect()
// (từ "else" cuối cùng sau _availableSlots.isEmpty check)

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _availableSlots.length,
            itemBuilder: (context, index) {
              final slot = _availableSlots[index];
              final isSelected = _selectedTimeSlot?['id'] == slot['id'];

              // Lấy status từ API: AVAILABLE, BOOKED, HELD, BLOCKED
              final status = (slot['status'] ?? 'AVAILABLE').toString().toUpperCase();
              final bool isAvailable = slot['available'] == true || status == 'AVAILABLE';

              final startTime = slot['startTime'] ?? '';
              final endTime = slot['endTime'] ?? '';
              final display = endTime.isNotEmpty ? '$startTime - $endTime' : startTime;

              // Màu theo trạng thái
              Color bgColor;
              Color borderColor;
              Color textColor;

              if (isSelected) {
                bgColor = AppColors.secondary;
                borderColor = AppColors.secondary;
                textColor = Colors.white;
              } else if (!isAvailable) {
                // Đã đặt / bị giữ / bị khóa → tối
                bgColor = const Color(0xFFEEEEEE);
                borderColor = const Color(0xFFDDDDDD);
                textColor = const Color(0xFFBBBBBB);
              } else {
                // Còn trống
                bgColor = Colors.white;
                borderColor = AppColors.border;
                textColor = AppColors.textDark;
              }

              return GestureDetector(
                onTap: isAvailable
                    ? () => setState(() => _selectedTimeSlot = slot)
                    : null, // disable tap nếu không available
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        display,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          decoration: !isAvailable
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Icon khóa cho slot không available
                      if (!isAvailable)
                        Positioned(
                          top: 4,
                          right: 6,
                          child: Icon(
                            Icons.lock_outline,
                            size: 10,
                            color: const Color(0xFFBBBBBB),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ── Step 3: Patient ───────────────────────────────────────

  Widget _buildPatientSelect(AuthProvider authProvider) {
    final primaryProfile = authProvider.userProfile;
    final relatives = authProvider.familyMembers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Chọn hồ sơ khám bệnh',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        if (primaryProfile != null) ...[
          const Text('Bản thân:',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight)),
          const SizedBox(height: 8),
          _buildPatientCard(primaryProfile, isSelf: true),
          const SizedBox(height: 20),
        ],
        if (relatives.isNotEmpty) ...[
          const Text('Người thân:',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: relatives.length,
            itemBuilder: (context, index) =>
                _buildPatientCard(relatives[index], isSelf: false),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Không tìm thấy thông tin người thân. Bạn có thể thêm hồ sơ trong phần Tài khoản.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient,
      {required bool isSelf}) {
    final isSelected = _selectedPatient?['id'] == patient['id'];
    final genderText = patient['gender'] == 'MALE' ? 'Nam' : 'Nữ';
    final relation = patient['relation'] ?? '';
    String relationLabel = '';
    if (!isSelf) {
      switch (relation) {
        case 'CHILD':
          relationLabel = 'Con cái';
          break;
        case 'SPOUSE':
          relationLabel = 'Vợ/Chồng';
          break;
        case 'PARENT':
          relationLabel = 'Bố/Mẹ';
          break;
        default:
          relationLabel = 'Người thân';
      }
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelf
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.secondary.withOpacity(0.1),
          child: Icon(
            isSelf ? Icons.person : Icons.people_alt,
            color: isSelf ? AppColors.primary : AppColors.secondary,
          ),
        ),
        title: Row(
          children: [
            Text(
              patient['fullName'] ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            if (!isSelf && relationLabel.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  relationLabel,
                  style: const TextStyle(
                      fontSize: 9,
                      color: Colors.purple,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '$genderText - NS: ${patient['dateOfBirth'] ?? ''}'
          '${patient['nationalId'] != null ? ' - CCCD: ${patient['nationalId']}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : const Icon(Icons.circle_outlined, color: AppColors.border),
        onTap: () => setState(() => _selectedPatient = patient),
      ),
    );
  }

  // ── Step 4: Confirm ───────────────────────────────────────

  Widget _buildConfirmSection() {
    final currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final price =
        (_selectedDoctor?['consultationFee'] ?? _selectedDoctor?['price'] ?? 0)
            .toDouble();
    final startTime =
        _selectedTimeSlot?['startTime'] ?? _selectedTimeSlot?['time'] ?? '';
    final endTime = _selectedTimeSlot?['endTime'] ?? '';
    final timeDisplay =
        endTime.isNotEmpty ? '$startTime - $endTime' : startTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Kiểm tra lại thông tin & Đặt lịch',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewRow('Chuyên khoa:',
                  _selectedSpecialty?['name'] ?? ''),
              const Divider(height: 16),
              _buildReviewRow(
                  'Bác sĩ khám:', _selectedDoctor?['fullName'] ?? ''),
              const Divider(height: 16),
              _buildReviewRow(
                  'Thời gian:', '$timeDisplay - ${_selectedDateDisplay ?? _selectedDate ?? ''}'),
              const Divider(height: 16),
              _buildReviewRow(
                  'Người khám:', _selectedPatient?['fullName'] ?? ''),
              const Divider(height: 16),
              _buildReviewRow(
                'Giá khám dịch vụ:',
                price > 0 ? currencyFormat.format(price) : 'Liên hệ phòng khám',
                isPrice: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Lý do khám bệnh (Tùy chọn)',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'VD: Triệu chứng đau họng, sốt nhẹ...',
            hintStyle: const TextStyle(fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Phương thức thanh toán viện phí',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 10),
        _buildPaymentOption('MOMO', 'Ví điện tử MoMo',
            'https://upload.wikimedia.org/wikipedia/vi/f/fe/MoMo_Logo.png'),
        _buildPaymentOption(
            'VNPAY',
            'Cổng thanh toán VNPay',
            'https://play-lh.googleusercontent.com/o1nS1u66vWz6fK15jD-n-8cE6Rk8g6V_y2Tir1r8W_D62YnS9k6V8PxhWw'),
        _buildPaymentOption('BANK_TRANSFER', 'Chuyển khoản ngân hàng', null,
            icon: Icons.account_balance),
        _buildPaymentOption(
            'CASH', 'Thanh toán trực tiếp tại quầy', null,
            icon: Icons.payments),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value,
      {bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textLight, fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isPrice ? AppColors.primary : AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String value, String title, String? logoUrl,
      {IconData? icon}) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (logoUrl != null)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  image: DecorationImage(
                      image: NetworkImage(logoUrl), fit: BoxFit.contain),
                ),
              )
            else
              Icon(icon ?? Icons.payment,
                  color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(AuthProvider authProvider) {
    final isLastStep = _currentStep == 4;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _isBooking ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Quay lại',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _isBooking
                  ? null
                  : () {
                      if (isLastStep) {
                        _confirmBooking(authProvider);
                      } else {
                        // Load doctors when moving from step 0 → 1
                        if (_currentStep == 0) {
                          _loadDoctorsForSpecialty();
                        }
                        _nextStep();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isLastStep ? 'Xác Nhận Đặt Lịch' : 'Tiếp tục',
                      style:
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}