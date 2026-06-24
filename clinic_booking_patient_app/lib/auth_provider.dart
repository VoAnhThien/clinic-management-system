import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _appointments = [];
  
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<Map<String, dynamic>> get familyMembers => _familyMembers;
  List<Map<String, dynamic>> get appointments => _appointments;
  String? get accessToken => _accessToken;




  AuthProvider() {
    _loadSession();
    // Load initial mock appointments
    _appointments = List.from(MockData.appointments);
    _familyMembers = List.from(MockData.familyMembers);
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final profileStr = prefs.getString('user_profile');
    if (token != null && profileStr != null) {
      _accessToken = token;
      _refreshToken = prefs.getString('refresh_token');
      _userProfile = json.decode(profileStr);
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<bool> login(String loginId, String password) async {
    _isLoading = true;
    notifyListeners();

    if (AppConstants.useMockData) {
      await Future.delayed(const Duration(milliseconds: 1500));
      _isLoggedIn = true;
      _accessToken = "mock_jwt_token_xxxx";
      _userProfile = MockData.activePatient;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      await prefs.setString('user_profile', json.encode(_userProfile));
      
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      final isPhone= loginId.startsWith('0')&& loginId.length==10;

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
         
          'phone': isPhone ? loginId : null,
          'nationalId': !isPhone ? loginId : null,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'];
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        _isLoggedIn = true;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _accessToken!);
        await prefs.setString('refresh_token', _refreshToken ?? '');
        
        await _fetchProfile();
        return true;
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String fullName,
    required String phone,
    required String nationalId,
    required String password,
    required String dob,
    required String gender,
    required String address,
  }) async {
    _isLoading = true;
    notifyListeners();

    if (AppConstants.useMockData) {
      await Future.delayed(const Duration(milliseconds: 1500));
      _userProfile = {
        'id': 'pat-new',
        'fullName': fullName,
        'nationalId': nationalId,
        'phone': phone,
        'dateOfBirth': dob,
        'gender': gender.toUpperCase(),
        'bloodType': 'O+',
        'allergies': 'Chưa ghi nhận',
        'address': address,
      };
      _isLoggedIn = true;
      _accessToken = "mock_jwt_token_xxxx";
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      await prefs.setString('user_profile', json.encode(_userProfile));

      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phone,
          'nationalId': nationalId,
          'fullName': fullName,
          'password': password,
          'dateOfBirth': dob,
          'gender': gender.toUpperCase(),
          'address': address,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        // Immediately log in user
        return await login(phone, password);
      }
    } catch (e) {
      debugPrint("Registration error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_profile');
    
    _isLoggedIn = false;
    _accessToken = null;
    _refreshToken = null;
    _userProfile = null;
    notifyListeners();
  }

  Future<void> _fetchProfile() async {
    if (_accessToken == null) return;
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/patients/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        _userProfile = body['data'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', json.encode(_userProfile));
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Fetch profile error: $e");
    }
  }

  void addFamilyMember(Map<String, dynamic> member) {
    _familyMembers.add({
      'id': 'pat-dep-${DateTime.now().millisecondsSinceEpoch}',
      ...member,
    });
    notifyListeners();
  }

  void addAppointment(Map<String, dynamic> appointment) {
    _appointments.insert(0, {
      'id': 'appt-${DateTime.now().millisecondsSinceEpoch}',
      'code': 'UMC-${10000 + _appointments.length}-B',
      'status': 'CONFIRMED',
      ...appointment,
    });
    notifyListeners();
  }



    // ==================== REAL API CALLS ====================

  List<Map<String, dynamic>> _featuredDoctors = [];
  List<Map<String, dynamic>> _news = [];

  List<Map<String, dynamic>> get featuredDoctors => _featuredDoctors;
  List<Map<String, dynamic>> get news => _news;

  /// Gọi khi vào HomeScreen hoặc sau khi login
  Future<void> fetchHomeData() async {
    if (_accessToken == null || !AppConstants.useMockData == false) return;

    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _fetchUpcomingAppointments(),
        _fetchFeaturedDoctors(),
        _fetchNews(),
      ]);
    } catch (e) {
      debugPrint("Fetch home data error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUpcomingAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/appointments/upcoming'), // ← Bạn cần xác nhận endpoint
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _appointments = List<Map<String, dynamic>>.from(data is List ? data : []);
      }
    } catch (e) {
      debugPrint("Fetch appointments error: $e");
      // Fallback to mock if needed
      if (AppConstants.useMockData) {
        _appointments = List.from(MockData.appointments);
      }
    }
  }

  Future<void> _fetchFeaturedDoctors() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/doctors/featured'), // ← Cần xác nhận
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _featuredDoctors = List<Map<String, dynamic>>.from(data is List ? data : []);
      }
    } catch (e) {
      debugPrint("Fetch featured doctors error: $e");
    }
  }

  Future<void> _fetchNews() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/news'), // ← Cần xác nhận
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _news = List<Map<String, dynamic>>.from(data is List ? data : []);
      }
    } catch (e) {
      debugPrint("Fetch news error: $e");
    }
  }
}
