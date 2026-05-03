import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final Employee employee;
  final Function(Employee) onUpdate;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.employee,
    required this.onUpdate,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  late Employee _currentEmployee;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentEmployee = widget.employee;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _isUpdating = true);
        
        // In a real app, you'd upload the file to a server and get a URL
        // For now, we'll use the local path as a simulation
        final updatedEmployee = _currentEmployee.copyWith(profilePictureUrl: image.path);
        
        await _apiService.updateEmployee(updatedEmployee);
        
        setState(() {
          _currentEmployee = updatedEmployee;
          _isUpdating = false;
        });
        
        widget.onUpdate(updatedEmployee);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الصورة الشخصية بنجاح')),
          );
        }
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحديث الصورة: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1DB954);
    
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
              decoration: const BoxDecoration(
                color: Color(0xFF0A0E27),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'الملف الشخصي',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40), // Balance the back button
                    ],
                  ),
                  const SizedBox(height: 30),
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: ClipOval(
                          child: _currentEmployee.profilePictureUrl != null
                              ? (_currentEmployee.profilePictureUrl!.startsWith('http')
                                  ? Image.network(_currentEmployee.profilePictureUrl!, fit: BoxFit.cover)
                                  : Image.file(File(_currentEmployee.profilePictureUrl!), fit: BoxFit.cover))
                              : Image.network('https://i.pravatar.cc/150?u=${_currentEmployee.id}', fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUpdating ? null : _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _isUpdating
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _currentEmployee.name,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _currentEmployee.position,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('البيانات الشخصية'),
                    const SizedBox(height: 15),
                    _buildInfoCard([
                      _buildInfoRow(Icons.email_outlined, 'البريد الإلكتروني', _currentEmployee.email),
                      _buildInfoRow(Icons.phone_outlined, 'رقم الهاتف', _currentEmployee.phone),
                      _buildInfoRow(Icons.badge_outlined, 'الرقم القومي', _currentEmployee.nationalId),
                      _buildInfoRow(Icons.location_on_outlined, 'العنوان', _currentEmployee.address),
                    ]),
                    
                    const SizedBox(height: 30),
                    _buildSectionTitle('بيانات العمل'),
                    const SizedBox(height: 15),
                    _buildInfoCard([
                      _buildInfoRow(Icons.business_outlined, 'القسم', _currentEmployee.department),
                      _buildInfoRow(Icons.location_city_outlined, 'فرع العمل', _currentEmployee.location),
                      _buildInfoRow(Icons.calendar_today_outlined, 'تاريخ التعيين', DateFormat('d MMMM yyyy', 'ar').format(_currentEmployee.hireDate)),
                      _buildInfoRow(Icons.school_outlined, 'المؤهل الدراسي', _currentEmployee.qualification),
                    ]),
                    
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        'تم تحديث البيانات بتاريخ: ${DateFormat('d MMMM yyyy', 'ar').format(DateTime.now())}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget child = entry.value;
          return Column(
            children: [
              child,
              if (idx < children.length - 1)
                Divider(height: 1, color: Colors.grey.shade100, indent: 60),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0A0E27), size: 22),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              Text(
                value.isEmpty ? 'غير متوفر' : value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
