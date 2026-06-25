import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppColors {
  static const Color primary = Color(0xFF0F52BA); // UMC Blue
  static const Color secondary = Color(0xFF00A896); // Teal accent
  static const Color background = Color(0xFFF4F6F9); // Light background
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}

class AppConstants {
  static const String appName = 'UMC Care';
  
  // Base API URL
  static String apiBaseUrl = (kIsWeb || kReleaseMode)
      ? 'https://clinic-management-system-82ar.onrender.com/api'
      : 'http://10.0.2.2:8080/api';
  static bool useMockData = true; 
}


class MockData {
  static final List<Map<String, dynamic>> specializations = [
    {
      'id': 'spec-1',
      'name': 'Nội khoa',
      'description': 'Chẩn đoán và điều trị bệnh nội tạng',
      'icon': 'medical_services',
    },
    {
      'id': 'spec-2',
      'name': 'Nhi khoa',
      'description': 'Chăm sóc sức khỏe trẻ em toàn diện',
      'icon': 'child_care',
    },
    {
      'id': 'spec-3',
      'name': 'Da liễu',
      'description': 'Khám và điều trị bệnh về da, tóc, móng',
      'icon': 'face',
    },
    {
      'id': 'spec-4',
      'name': 'Tim mạch',
      'description': 'Điều trị bệnh tim và mạch máu chuyên sâu',
      'icon': 'favorite',
    },
    {
      'id': 'spec-5',
      'name': 'Thần kinh',
      'description': 'Các bệnh lý liên quan đến hệ thần kinh',
      'icon': 'psychology',
    },
    {
      'id': 'spec-6',
      'name': 'Tai Mũi Họng',
      'description': 'Khám tai, mũi xoang và họng thanh quản',
      'icon': 'hearing',
    },
  ];

  static final List<Map<String, dynamic>> clinics = [
    {
      'id': 'clinic-1',
      'name': 'Phòng khám Đa khoa Sài Gòn',
      'address': '123 Nguyễn Thị Minh Khai, Q1, TP.HCM',
      'phone': '02812345678',
    },
    {
      'id': 'clinic-2',
      'name': 'Phòng khám Nhi Bình Thạnh',
      'address': '45 Đinh Tiên Hoàng, Q.Bình Thạnh, TP.HCM',
      'phone': '02887654321',
    },
  ];

  static final List<Map<String, dynamic>> doctors = [
    {
      'id': 'doc-1',
      'fullName': 'PGS.TS.BS Nguyễn Văn An',
      'specializationId': 'spec-1',
      'specializationName': 'Nội khoa',
      'experienceYears': 25,
      'biography': 'Trưởng khoa Nội tim mạch BV Đại học Y Dược TP.HCM với hơn 25 năm kinh nghiệm điều trị các bệnh mãn tính.',
      'licenseNumber': 'CCHN-000123',
      'avatarUrl': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=200',
      'price': 250000.0,
      'rating': 4.9,
    },
    {
      'id': 'doc-2',
      'fullName': 'ThS.BS Trần Thị Bình',
      'specializationId': 'spec-2',
      'specializationName': 'Nhi khoa',
      'experienceYears': 12,
      'biography': 'Chuyên gia dinh dưỡng và nhi khoa, tận tâm, yêu mến trẻ em. Cựu bác sĩ nội trú BV Nhi Đồng.',
      'licenseNumber': 'CCHN-000456',
      'avatarUrl': 'https://images.unsplash.com/photo-1594824813573-246434de83fb?auto=format&fit=crop&q=80&w=200',
      'price': 150000.0,
      'rating': 4.8,
    },
    {
      'id': 'doc-3',
      'fullName': 'BSCKII Lê Hoàng Nam',
      'specializationId': 'spec-3',
      'specializationName': 'Da liễu',
      'experienceYears': 18,
      'biography': 'Chuyên gia điều trị các bệnh lý da liễu thẩm mỹ, mụn trứng cá nặng, viêm da cơ địa.',
      'licenseNumber': 'CCHN-000789',
      'avatarUrl': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=200',
      'price': 200000.0,
      'rating': 4.7,
    },
    {
      'id': 'doc-4',
      'fullName': 'BSCKI Phạm Minh Đức',
      'specializationId': 'spec-4',
      'specializationName': 'Tim mạch',
      'experienceYears': 15,
      'biography': 'Bác sĩ chuyên khoa Tim mạch can thiệp, chẩn đoán sớm và điều trị hiệu quả các bệnh mạch vành, tăng huyết áp.',
      'licenseNumber': 'CCHN-000999',
      'avatarUrl': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=200',
      'price': 300000.0,
      'rating': 4.9,
    },
  ];

  static final List<String> availableDates = [
    'Thứ 6, 19/06/2026',
    'Thứ Bảy, 20/06/2026',
    'Thứ Hai, 22/06/2026',
    'Thứ Ba, 23/06/2026',
  ];

  static final List<Map<String, String>> timeSlots = [
    {'id': 'slot-1', 'time': '08:00 - 08:30'},
    {'id': 'slot-2', 'time': '08:30 - 09:00'},
    {'id': 'slot-3', 'time': '09:00 - 09:30'},
    {'id': 'slot-4', 'time': '09:30 - 10:00'},
    {'id': 'slot-5', 'time': '10:00 - 10:30'},
    {'id': 'slot-6', 'time': '10:30 - 11:00'},
    {'id': 'slot-7', 'time': '14:00 - 14:30'},
    {'id': 'slot-8', 'time': '14:30 - 15:00'},
    {'id': 'slot-9', 'time': '15:00 - 15:30'},
    {'id': 'slot-10', 'time': '15:30 - 16:00'},
  ];

  static final Map<String, dynamic> activePatient = {
    'id': 'pat-self',
    'fullName': 'Nguyễn Văn A',
    'nationalId': '079096001234',
    'phone': '0987654321',
    'dateOfBirth': '1996-05-15',
    'gender': 'MALE',
    'bloodType': 'O+',
    'allergies': 'Không có dị ứng thuốc',
    'address': '783 Trần Hưng Đạo, Phường 1, Quận 5, TP.HCM',
  };

  static final List<Map<String, dynamic>> familyMembers = [
    {
      'id': 'pat-dep-1',
      'fullName': 'Nguyễn Hoàng Lâm',
      'relation': 'CHILD',
      'dateOfBirth': '2018-10-12',
      'gender': 'MALE',
      'bloodType': 'O+',
      'allergies': 'Dị ứng với Hải sản',
      'address': '783 Trần Hưng Đạo, Phường 1, Quận 5, TP.HCM',
    },
    {
      'id': 'pat-dep-2',
      'fullName': 'Trần Thị Mai',
      'relation': 'SPOUSE',
      'dateOfBirth': '1998-02-20',
      'gender': 'FEMALE',
      'bloodType': 'AB-',
      'allergies': 'Dị ứng phấn hoa',
      'address': '783 Trần Hưng Đạo, Phường 1, Quận 5, TP.HCM',
    },
  ];

  static final List<Map<String, dynamic>> medicalRecords = [
    {
      'id': 'rec-1',
      'date': '2026-05-10',
      'doctorName': 'PGS.TS.BS Nguyễn Văn An',
      'specializationName': 'Nội khoa',
      'clinicName': 'Phòng khám Đa khoa Sài Gòn',
      'chiefComplaint': 'Đau ngực trái nhẹ kèm khó thở nhẹ khi leo cầu thang.',
      'diagnosis': 'Tăng huyết áp vô căn độ II, Thiếu máu cơ tim nhẹ.',
      'treatmentPlan': 'Nghỉ ngơi hợp lý, hạn chế ăn mặn, tập thể dục nhẹ nhàng 30p mỗi ngày. Uống thuốc đúng giờ và tái khám sau 1 tháng.',
      'prescription': [
        {'name': 'Amlodipin 5mg', 'quantity': 30, 'dosage': 'Sáng 1 viên sau ăn', 'duration': '30 ngày'},
        {'name': 'Concor 2.5mg', 'quantity': 30, 'dosage': 'Sáng 1 viên trước ăn', 'duration': '30 ngày'},
        {'name': 'Aspirin 81mg', 'quantity': 30, 'dosage': 'Tối 1 viên sau ăn', 'duration': '30 ngày'},
      ]
    },
    {
      'id': 'rec-2',
      'date': '2026-03-12',
      'doctorName': 'BSCKII Lê Hoàng Nam',
      'specializationName': 'Da liễu',
      'clinicName': 'Phòng khám Đa khoa Sài Gòn',
      'chiefComplaint': 'Ngứa ngáy và bong tróc da tay chân nhiều vào mùa hanh khô.',
      'diagnosis': 'Viêm da cơ địa dị ứng.',
      'treatmentPlan': 'Dưỡng ẩm thường xuyên bằng kem chuyên dụng, tránh tiếp xúc xà phòng chất tẩy rửa mạnh.',
      'prescription': [
        {'name': 'Fucicort Cream 15g', 'quantity': 1, 'dosage': 'Thoa mỏng 2 lần/ngày (Sáng - Tối)', 'duration': '10 ngày'},
        {'name': 'Telfast 180mg', 'quantity': 10, 'dosage': 'Tối 1 viên sau ăn', 'duration': '10 ngày'},
        {'name': 'Cetaphil Moisturizing Cream 50g', 'quantity': 1, 'dosage': 'Thoa dưỡng ẩm nhiều lần trong ngày', 'duration': '30 ngày'},
      ]
    }
  ];

  static final List<Map<String, dynamic>> appointments = [
    {
      'id': 'appt-1',
      'date': 'Thứ 6, 19/06/2026',
      'time': '09:00 - 09:30',
      'doctorName': 'PGS.TS.BS Nguyễn Văn An',
      'specializationName': 'Nội khoa',
      'clinicName': 'Phòng khám Đa khoa Sài Gòn',
      'patientName': 'Nguyễn Văn A',
      'status': 'CONFIRMED', // CONFIRMED, COMPLETED, CANCELLED
      'reason': 'Tái khám tăng huyết áp định kỳ.',
      'code': 'UMC-77391-A',
    }
  ];

  static final List<Map<String, dynamic>> news = [
    {
      'title': 'Bảo vệ tim mạch mùa nắng nóng: Những điều cần đặc biệt lưu ý',
      'category': 'Y Khoa Thường Thức',
      'time': '2 giờ trước',
      'imageUrl': 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&q=80&w=300',
    },
    {
      'title': 'Chế độ ăn cho trẻ bị béo phì dưới góc nhìn chuyên gia dinh dưỡng',
      'category': 'Nhi Khoa',
      'time': '1 ngày trước',
      'imageUrl': 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&q=80&w=300',
    },
    {
      'title': 'Tác hại khôn lường của việc tự ý sử dụng kháng sinh không kê đơn',
      'category': 'Khuyến cáo Y tế',
      'time': '3 ngày trước',
      'imageUrl': 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?auto=format&fit=crop&q=80&w=300',
    }
  ];
}
