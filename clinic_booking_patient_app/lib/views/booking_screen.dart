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
  String? _selectedDate;
  Map<String, String>? _selectedTimeSlot;
  Map<String, dynamic>? _selectedPatient;
  String _paymentMethod = 'MOMO'; // MOMO, VNPAY, BANK_TRANSFER, CASH
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedDoctor != null) {
      _selectedDoctor = widget.preselectedDoctor;
      // Find specialty matching doctor's specializationId
      _selectedSpecialty = MockData.specializations.firstWhere(
        (spec) => spec['id'] == _selectedDoctor!['specializationId'],
        orElse: () => MockData.specializations.first,
      );
      _currentStep = 2; // Jump directly to select Date & Time
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedSpecialty == null) {
      _showWarning('Vui lòng chọn chuyên khoa');
      return;
    }
    if (_currentStep == 1 && _selectedDoctor == null) {
      _showWarning('Vui lòng chọn bác sĩ');
      return;
    }
    if (_currentStep == 2 && (_selectedDate == null || _selectedTimeSlot == null)) {
      _showWarning('Vui lòng chọn ngày và giờ khám');
      return;
    }
    if (_currentStep == 3 && _selectedPatient == null) {
      _showWarning('Vui lòng chọn hồ sơ bệnh nhân');
      return;
    }

    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.warning),
    );
  }

  void _confirmBooking(AuthProvider authProvider) {
    // Save appointment to state
    final appt = {
      'date': _selectedDate,
      'time': _selectedTimeSlot!['time'],
      'doctorName': _selectedDoctor!['fullName'],
      'specializationName': _selectedDoctor!['specializationName'],
      'clinicName': 'Phòng khám Đa khoa Sài Gòn',
      'patientName': _selectedPatient!['fullName'],
      'reason': _reasonController.text.isNotEmpty ? _reasonController.text : 'Khám sức khỏe tổng quát',
    };
    
    authProvider.addAppointment(appt);
    
    // Show booking success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFFECFDF5),
                child: Icon(Icons.check_circle, color: AppColors.success, size: 54),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đặt Lịch Thành Công!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
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
                  Navigator.pop(context); // Close dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainNavigation(initialTab: 1)),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Xem Lịch Hẹn', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

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
          // Step progress indicator bar
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
                          : (isCompleted ? AppColors.secondary : AppColors.border),
                      child: isCompleted 
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.white : AppColors.textLight,
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.primary : AppColors.textLight,
                      ),
                    )
                  ],
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < _currentStep ? AppColors.secondary : AppColors.border,
                      margin: const EdgeInsets.only(bottom: 15, left: 4, right: 4),
                    ),
                  )
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
        return _buildSpecialtySelect();
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

  Widget _buildSpecialtySelect() {
    final specs = MockData.specializations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Chọn chuyên khoa khám bệnh',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                subtitle: Text(spec['description'] ?? '', style: const TextStyle(fontSize: 12)),
                trailing: isSelected 
                    ? const Icon(Icons.radio_button_checked, color: AppColors.primary)
                    : const Icon(Icons.radio_button_off, color: AppColors.border),
                onTap: () {
                  setState(() {
                    _selectedSpecialty = spec;
                    _selectedDoctor = null; // Reset doctor if specialty changes
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDoctorSelect() {
    // Filter doctors by selected specialty
    final doctors = MockData.doctors.where(
      (doc) => doc['specializationId'] == _selectedSpecialty?['id'],
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bác sĩ thuộc khoa ${_selectedSpecialty?['name']}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        if (doctors.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Hiện khoa này chưa có lịch bác sĩ. Vui lòng quay lại sau.'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doc = doctors[index];
              final isSelected = _selectedDoctor?['id'] == doc['id'];
              final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
              
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.transparent,
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
                            child: Image.network(
                              doc['avatarUrl'] ?? '',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc['fullName'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${doc['rating']}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.work_history, color: AppColors.textLight, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${doc['experienceYears']} năm KN',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  doc['biography'] ?? '',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Giá khám dịch vụ', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                              Text(
                                currencyFormat.format(doc['price']),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedDoctor = doc;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.08),
                              foregroundColor: isSelected ? Colors.white : AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(isSelected ? 'Đã Chọn' : 'Chọn Bác Sĩ'),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDateTimeSelect() {
    final dates = MockData.availableDates;
    final slots = MockData.timeSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date selector
        const Text(
          '1. Chọn ngày khám',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = _selectedDate == date;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      date,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        
        // Time slot selector
        const Text(
          '2. Chọn khung giờ khám',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            final isSelected = _selectedTimeSlot?['id'] == slot['id'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeSlot = slot;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.secondary : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    slot['time']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPatientSelect(AuthProvider authProvider) {
    final primaryProfile = authProvider.userProfile;
    final relatives = authProvider.familyMembers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Chọn hồ sơ khám bệnh',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        
        // Main User Profile
        if (primaryProfile != null) ...[
          const Text('Bản thân:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 8),
          _buildPatientCard(primaryProfile, isSelf: true),
          const SizedBox(height: 20),
        ],

        // Dependent relative profiles
        const Text('Người thân:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight)),
        const SizedBox(height: 8),
        if (relatives.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Không tìm thấy thông tin người thân. Bạn có thể thêm hồ sơ trong phần Tài khoản.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: relatives.length,
            itemBuilder: (context, index) {
              final relative = relatives[index];
              return _buildPatientCard(relative, isSelf: false);
            },
          ),
      ],
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient, {required bool isSelf}) {
    final isSelected = _selectedPatient?['id'] == patient['id'];
    final genderText = patient['gender'] == 'MALE' ? 'Nam' : 'Nữ';
    
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
          backgroundColor: isSelf ? AppColors.primary.withOpacity(0.1) : AppColors.secondary.withOpacity(0.1),
          child: Icon(
            isSelf ? Icons.person : Icons.people_alt,
            color: isSelf ? AppColors.primary : AppColors.secondary,
          ),
        ),
        title: Row(
          children: [
            Text(
              patient['fullName'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            if (!isSelf) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  patient['relation'] == 'CHILD' ? 'Con cái' : 'Vợ/Chồng',
                  style: const TextStyle(fontSize: 9, color: Colors.purple, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
        subtitle: Text(
          '$genderText - NS: ${patient['dateOfBirth']} - CCCD: ${patient['nationalId'] ?? "Không có"}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : const Icon(Icons.circle_outlined, color: AppColors.border),
        onTap: () {
          setState(() {
            _selectedPatient = patient;
          });
        },
      ),
    );
  }

  Widget _buildConfirmSection() {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Kiểm tra lại thông tin & Đặt lịch',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        
        // Medical Booking Review Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewRow('Phòng khám:', 'Phòng khám Đa khoa Sài Gòn'),
              const Divider(height: 16),
              _buildReviewRow('Chuyên khoa:', _selectedSpecialty?['name'] ?? ''),
              const Divider(height: 16),
              _buildReviewRow('Bác sĩ khám:', _selectedDoctor?['fullName'] ?? ''),
              const Divider(height: 16),
              _buildReviewRow('Thời gian:', '${_selectedTimeSlot?['time']} - ${_selectedDate}'),
              const Divider(height: 16),
              _buildReviewRow('Người khám:', _selectedPatient?['fullName'] ?? ''),
              const Divider(height: 16),
              _buildReviewRow('Giá khám dịch vụ:', currencyFormat.format(_selectedDoctor?['price'] ?? 0), isPrice: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Booking reason text box
        const Text(
          'Lý do khám bệnh (Tùy chọn)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
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

        // Payment Method Selector
        const Text(
          'Phương thức thanh toán viện phí',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 10),
        _buildPaymentOption('MOMO', 'Ví điện tử MoMo', 'https://upload.wikimedia.org/wikipedia/vi/f/fe/MoMo_Logo.png'),
        _buildPaymentOption('VNPAY', 'Cổng thanh toán VNPay', 'https://play-lh.googleusercontent.com/o1nS1u66vWz6fK15jD-n-8cE6Rk8g6V_y2Tir1r8W_D62YnS9k6V8PxhWw'),
        _buildPaymentOption('BANK_TRANSFER', 'Chuyển khoản ngân hàng', null, icon: Icons.account_balance),
        _buildPaymentOption('CASH', 'Thanh toán trực tiếp tại quầy', null, icon: Icons.payments),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
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
        )
      ],
    );
  }

  Widget _buildPaymentOption(String value, String title, String? logoUrl, {IconData? icon}) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentMethod = value;
        });
      },
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
                  image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.contain),
                ),
              )
            else
              Icon(icon ?? Icons.payment, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.border,
            )
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
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Quay lại', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: isLastStep ? () => _confirmBooking(authProvider) : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                isLastStep ? 'Xác Nhận Đặt Lịch' : 'Tiếp tục',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
