import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../auth_provider.dart';
import '../constants.dart';
import 'booking_screen.dart';

class DoctorsScreen extends StatefulWidget {
  final Map<String, dynamic>? preselectedSpecialization;
  const DoctorsScreen({super.key, this.preselectedSpecialization});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  Map<String, dynamic>? _selectedSpec;
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredDoctors = [];

  @override
  void initState() {
    super.initState();
    _selectedSpec = widget.preselectedSpecialization;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final docs = await authProvider.fetchDoctors(
      specializationId: _selectedSpec?['id']?.toString(),
    );
    setState(() {
      _doctors = docs;
      _filteredDoctors = docs;
      _isLoading = false;
    });
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = _doctors;
      } else {
        final q = query.toLowerCase();
        _filteredDoctors = _doctors.where((doc) {
          final name = (doc['fullName'] ?? '').toLowerCase();
          final spec = (doc['specializationName'] ?? '').toLowerCase();
          return name.contains(q) || spec.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final specs = authProvider.specializations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bác Sĩ'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên bác sĩ, chuyên khoa...',
                hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textLight),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Specialization filter chips
          if (specs.isNotEmpty)
            Container(
              color: Colors.white,
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: specs.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "All" chip
                    final isSelected = _selectedSpec == null;
                    return _buildChip(
                      label: 'Tất cả',
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedSpec = null);
                        _loadDoctors();
                      },
                    );
                  }
                  final spec = specs[index - 1];
                  final isSelected = _selectedSpec?['id'] == spec['id'];
                  return _buildChip(
                    label: spec['name'] ?? '',
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedSpec = spec);
                      _loadDoctors();
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 4),

          // Doctor list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _filteredDoctors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search,
                                size: 64,
                                color: AppColors.textLight.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            const Text(
                              'Không tìm thấy bác sĩ phù hợp.',
                              style: TextStyle(
                                  color: AppColors.textLight, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadDoctors,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDoctors.length,
                          itemBuilder: (context, index) {
                            return _buildDoctorCard(
                                context, _filteredDoctors[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doc) {
    final currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final price = (doc['consultationFee'] ?? doc['price'] ?? 0).toDouble();
    final rating = (doc['rating'] ?? 0.0).toDouble();
    final experience = doc['experienceYears'] ?? doc['experience'] ?? 0;
    final avatarUrl = doc['avatarUrl'] ?? doc['avatar'] ?? '';
    final specName =
        doc['specializationName'] ?? doc['specialization']?['name'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderAvatar(),
                        )
                      : _placeholderAvatar(),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['fullName'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          specName,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            rating > 0 ? rating.toStringAsFixed(1) : 'Mới',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.work_history,
                              color: AppColors.textLight, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$experience năm kinh nghiệm',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Biography
            if ((doc['biography'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                doc['biography'],
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textLight, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const Divider(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Phí khám',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textLight)),
                    Text(
                      price > 0
                          ? currencyFormat.format(price)
                          : 'Liên hệ phòng khám',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BookingScreen(preselectedDoctor: doc),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_today, size: 14),
                  label: const Text('Đặt lịch',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: AppColors.primary, size: 36),
    );
  }
}