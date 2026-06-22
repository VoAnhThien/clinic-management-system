import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../constants.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nationalIdController = TextEditingController();
  String _selectedRelation = 'CHILD'; // CHILD, SPOUSE, PARENT, OTHER
  String _selectedGender = 'MALE';

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  void _showAddMemberDialog(AuthProvider authProvider) {
    _nameController.clear();
    _dobController.clear();
    _nationalIdController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Thêm Người Thân', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Họ tên người thân'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedRelation,
                  decoration: const InputDecoration(labelText: 'Quan hệ'),
                  items: const [
                    DropdownMenuItem(value: 'CHILD', child: Text('Con cái')),
                    DropdownMenuItem(value: 'SPOUSE', child: Text('Vợ/Chồng')),
                    DropdownMenuItem(value: 'PARENT', child: Text('Bố/Mẹ')),
                    DropdownMenuItem(value: 'SIBLING', child: Text('Anh/Chị/Em')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
                  ],
                  onChanged: (val) {
                    if (val != null) _selectedRelation = val;
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _dobController,
                  decoration: const InputDecoration(labelText: 'Ngày sinh (YYYY-MM-DD)', hintText: 'VD: 2018-05-20'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(labelText: 'Giới tính'),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Nam')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
                  ],
                  onChanged: (val) {
                    if (val != null) _selectedGender = val;
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nationalIdController,
                  decoration: const InputDecoration(labelText: 'Số CCCD (nếu có)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty || _dobController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đủ thông tin bắt buộc'), backgroundColor: AppColors.warning),
                  );
                  return;
                }
                final relative = {
                  'fullName': _nameController.text.trim(),
                  'relation': _selectedRelation,
                  'dateOfBirth': _dobController.text.trim(),
                  'gender': _selectedGender,
                  'nationalId': _nationalIdController.text.trim().isNotEmpty ? _nationalIdController.text.trim() : null,
                };
                authProvider.addFamilyMember(relative);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm hồ sơ người thân thành công!'), backgroundColor: AppColors.success),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Thêm Mới', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userProfile;
    final relatives = authProvider.familyMembers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tài Khoản & Cài Đặt'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient Profile Information
            if (user != null) ...[
              _buildSectionTitle('Thông tin cá nhân'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person_outline, 'Họ và tên', user['fullName'] ?? ''),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', user['phone'] ?? ''),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.badge_outlined, 'Số CCCD', user['nationalId'] ?? 'Chưa cập nhật'),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.calendar_today_outlined, 'Ngày sinh', user['dateOfBirth'] ?? ''),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ', user['address'] ?? 'Chưa cập nhật'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Family members management
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Hồ sơ người thân'),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                  onPressed: () => _showAddMemberDialog(authProvider),
                )
              ],
            ),
            if (relatives.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Center(
                  child: Text(
                    'Bạn chưa liên kết hồ sơ người thân nào.',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: relatives.length,
                itemBuilder: (context, index) {
                  final rel = relatives[index];
                  final genderText = rel['gender'] == 'MALE' ? 'Nam' : 'Nữ';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.secondary.withOpacity(0.1),
                        child: const Icon(Icons.people_alt, color: AppColors.secondary),
                      ),
                      title: Text(rel['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      subtitle: Text(
                        'Quan hệ: ${rel['relation'] == 'CHILD' ? 'Con cái' : 'Vợ/Chồng'} - $genderText - Ngày sinh: ${rel['dateOfBirth']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // App Settings / Connectivity Options
            _buildSectionTitle('Cấu hình kết nối'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            AppConstants.useMockData ? Icons.wifi_off : Icons.wifi,
                            color: AppConstants.useMockData ? AppColors.warning : AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kết nối Backend API',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                              ),
                              Text(
                                'Bật để gọi API thật từ Spring Boot',
                                style: TextStyle(color: AppColors.textLight, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: !AppConstants.useMockData,
                        activeColor: AppColors.success,
                        onChanged: (value) {
                          setState(() {
                            AppConstants.useMockData = !value;
                          });
                        },
                      ),
                    ],
                  ),
                  if (!AppConstants.useMockData) ...[
                    const Divider(height: 20),
                    TextFormField(
                      initialValue: AppConstants.apiBaseUrl,
                      decoration: const InputDecoration(
                        labelText: 'API Base URL',
                        labelStyle: TextStyle(fontSize: 12),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                      onChanged: (val) {
                        AppConstants.apiBaseUrl = val.trim();
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            ElevatedButton(
              onPressed: () async {
                await authProvider.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger.withOpacity(0.1),
                foregroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Đăng Xuất Tài Khoản', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13)),
          ],
        )
      ],
    );
  }
}
