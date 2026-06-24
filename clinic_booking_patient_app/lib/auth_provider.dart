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
  List<Map<String, dynamic>> _featuredDoctors = [];
  List<Map<String, dynamic>> _specializations = [];
  List<Map<String, dynamic>> _medicalRecords = [];
  bool _homeDataLoaded = false;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<Map<String, dynamic>> get familyMembers => _familyMembers;
  List<Map<String, dynamic>> get appointments => _appointments;
  String? get accessToken => _accessToken;
  List<Map<String, dynamic>> get featuredDoctors => _featuredDoctors;
  List<Map<String, dynamic>> get specializations => _specializations;
  List<Map<String, dynamic>> get medicalRecords => _medicalRecords;
  bool get homeDataLoaded => _homeDataLoaded;

  AuthProvider() {
    _loadSession();
  }

  // ── Headers helper ───────────────────────────────────────

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

  // ── Session ──────────────────────────────────────────────

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
      // Auto-load data after session restored
      await fetchHomeData();
    }
  }

  // ── Auth ─────────────────────────────────────────────────

  Future<bool> login(String loginId, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final isPhone = RegExp(r'^[0-9]+$').hasMatch(loginId);

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          if (isPhone) 'phone': loginId,
          if (!isPhone) 'nationalId': loginId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        // Backend wraps in ApiResponse: { data: { accessToken, refreshToken } }
        final data = body['data'] ?? body;
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        _isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _accessToken!);
        await prefs.setString('refresh_token', _refreshToken ?? '');


        await _fetchProfile();
        await fetchHomeData();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('Login failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Login error: $e');
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
        return await login(phone, password);
      } else {
        debugPrint('Register failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Registration error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    try {
      if (_refreshToken != null) {
        await http.post(
          Uri.parse('${AppConstants.apiBaseUrl}/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'refreshToken': _refreshToken}),
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_profile');

    _isLoggedIn = false;
    _accessToken = null;
    _refreshToken = null;
    _userProfile = null;
    _appointments = [];
    _familyMembers = [];
    _featuredDoctors = [];
    _specializations = [];
    _medicalRecords = [];
    _homeDataLoaded = false;
    notifyListeners();
  }

  // ── Profile ──────────────────────────────────────────────

  Future<void> _fetchProfile() async {
    if (_accessToken == null) return;
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/patients/me'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        _userProfile = body['data'] ?? body;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', json.encode(_userProfile));
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch profile error: $e');
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_accessToken == null) return false;
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/patients/me'),
        headers: _authHeaders,
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        await _fetchProfile();
        return true;
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
    }
    return false;
  }

  // ── Family members ────────────────────────────────────────

  Future<void> fetchFamilyMembers() async {
    if (_accessToken == null) return;
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/patients/my-profiles'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final list = body['data'] ?? body;
        _familyMembers = List<Map<String, dynamic>>.from(list is List ? list : []);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch family members error: $e');
    }
  }

  Future<bool> addFamilyMember(Map<String, dynamic> member) async {
    if (_accessToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/patients/my-profiles'),
        headers: _authHeaders,
        body: json.encode(member),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchFamilyMembers();
        return true;
      }
    } catch (e) {
      debugPrint('Add family member error: $e');
    }
    return false;
  }

  // ── Appointments ──────────────────────────────────────────

  Future<void> fetchAppointments() async {
    if (_accessToken == null) return;
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/appointments/my?size=50&sort=bookedAt,desc'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        // Page response: { data: { content: [...] } }
        final data = body['data'] ?? body;
        final content = data['content'] ?? data;
        _appointments = List<Map<String, dynamic>>.from(content is List ? content : []);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch appointments error: $e');
    }
  }

  Future<Map<String, dynamic>?> bookAppointment({
    required String timeSlotId,
    required String patientProfileId,
    String? reason,
    String? paymentMethod,
  }) async {
    if (_accessToken == null) return null;
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/appointments'),
        headers: _authHeaders,
        body: json.encode({
          'timeSlotId': timeSlotId,
          'patientProfileId': patientProfileId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        final newAppt = body['data'] ?? body;
        _appointments.insert(0, Map<String, dynamic>.from(newAppt));
        notifyListeners();
        return Map<String, dynamic>.from(newAppt);
      } else {
        debugPrint('Book appointment failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Book appointment error: $e');
    }
    return null;
  }

  Future<bool> cancelAppointment(String appointmentId, String reason) async {
    if (_accessToken == null) return false;
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/appointments/$appointmentId/cancel'),
        headers: _authHeaders,
        body: json.encode({'reason': reason}),
      );
      if (response.statusCode == 200) {
        // Update local state
        final idx = _appointments.indexWhere((a) => a['id'].toString() == appointmentId);
        if (idx != -1) {
          _appointments[idx] = {..._appointments[idx], 'status': 'CANCELLED'};
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Cancel appointment error: $e');
    }
    return false;
  }

  // ── Doctors & Specializations ─────────────────────────────

  Future<void> fetchSpecializations() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/doctors/specializations'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final list = body['data'] ?? body;
        _specializations = List<Map<String, dynamic>>.from(list is List ? list : []);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch specializations error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchDoctors({
    String? specializationId,
    String? clinicId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final params = {
        'page': '$page',
        'size': '$size',
        'sort': 'fullName,asc',
        if (specializationId != null) 'specializationId': specializationId,
        if (clinicId != null) 'clinicId': clinicId,
      };
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/doctors')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'] ?? body;
        final content = data['content'] ?? data;
        final doctors = List<Map<String, dynamic>>.from(content is List ? content : []);

        // Cache first page as featured doctors for home screen
        if (page == 0 && specializationId == null) {
          _featuredDoctors = doctors.take(6).toList();
          notifyListeners();
        }

        return doctors;
      }
    } catch (e) {
      debugPrint('Fetch doctors error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchDoctorById(String doctorId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/doctors/$doctorId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['data'] ?? body;
      }
    } catch (e) {
      debugPrint('Fetch doctor error: $e');
    }
    return null;
  }

  // ── Schedules & Slots ─────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchDoctorSchedules(String doctorId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/doctors/$doctorId/schedules'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final list = body['data'] ?? body;
        return List<Map<String, dynamic>>.from(list is List ? list : []);
      }
    } catch (e) {
      debugPrint('Fetch schedules error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchAvailableSlots(
      String doctorId, String date) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConstants.apiBaseUrl}/doctors/$doctorId/slots?date=$date'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final list = body['data'] ?? body;
        return List<Map<String, dynamic>>.from(list is List ? list : []);
      }
    } catch (e) {
      debugPrint('Fetch slots error: $e');
    }
    return [];
  }

  // ── Medical Records ───────────────────────────────────────

  Future<void> fetchMedicalRecords({String? patientId}) async {
    if (_accessToken == null) return;
    // Note: adjust endpoint to match your BE
    // Common pattern: GET /medical-records?patientId=xxx
    try {
      final patId = patientId ?? _userProfile?['id']?.toString();
      if (patId == null) return;

      final response = await http.get(
        Uri.parse(
            '${AppConstants.apiBaseUrl}/medical-records?patientId=$patId&size=50&sort=date,desc'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'] ?? body;
        final content = data['content'] ?? data;
        _medicalRecords =
            List<Map<String, dynamic>>.from(content is List ? content : []);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch medical records error: $e');
    }
  }

  // ── Home data ─────────────────────────────────────────────

  Future<void> fetchHomeData() async {
    if (_accessToken == null) return;

    try {
      await Future.wait([
        fetchAppointments(),
        fetchFamilyMembers(),
        fetchSpecializations(),
        fetchDoctors(),
      ]);
      _homeDataLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch home data error: $e');
    }
  }
}