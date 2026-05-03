import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/employee.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class EmployeeRegistrationScreen extends StatefulWidget {
  const EmployeeRegistrationScreen({super.key});

  @override
  State<EmployeeRegistrationScreen> createState() =>
      _EmployeeRegistrationScreenState();
}

class _EmployeeRegistrationScreenState
    extends State<EmployeeRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _picker = ImagePicker();

  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();
  
  // Additional fields
  final _departmentController = TextEditingController();
  final _locationController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _addressController = TextEditingController();
  final _salaryController = TextEditingController();
  DateTime _hireDate = DateTime.now();

  // Document Images
  final Map<String, String?> _documentImages = {
    'صورة البطاقة (وجه)': null,
    'صورة البطاقة (ظهر)': null,
    'شهادة الميلاد': null,
    'المؤهل الدراسي': null,
  };

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    _locationController.dispose();
    _nationalIdController.dispose();
    _qualificationController.dispose();
    _addressController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String label) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _documentImages[label] = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final employee = Employee(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        position: _positionController.text.trim(),
        department: _departmentController.text.trim().isEmpty ? 'General' : _departmentController.text.trim(),
        location: _locationController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        qualification: _qualificationController.text.trim(),
        address: _addressController.text.trim(),
        hireDate: _hireDate,
        salary: double.tryParse(_salaryController.text.trim()) ?? 0,
        status: 'active',
      );

      final employeeId = await _apiService.addEmployee(employee);

      await _apiService.register(
        _usernameController.text.trim(),
        _passwordController.text,
        'employee',
        employeeId: employeeId,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF1DB954);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تسجيل موظف جديد',
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Custom Stepper Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepIndicator(0, 'البيانات الشخصية'),
                _buildStepLine(),
                _buildStepIndicator(1, 'المعلومات'),
                _buildStepLine(),
                _buildStepIndicator(2, 'المستندات'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: _buildCurrentStepView(isDark, primaryColor),
            ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'السابق',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _register();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _currentStep == 2 ? 'إنهاء' : 'التالي',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    bool isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1DB954) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}', // Fixed numbering to match user request (1, 2, 3)
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? const Color(0xFF1DB954) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 1,
        color: Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 20),
      ),
    );
  }

  Widget _buildCurrentStepView(bool isDark, Color primaryColor) {
    if (_currentStep == 0) {
      return Column(
        children: [
          _buildTextField('الاسم الكامل', 'أدخل اسمك الكامل', _nameController, isDark),
          const SizedBox(height: 20),
          _buildTextField('البريد الإلكتروني', 'أدخل بريدك الإلكتروني', _emailController, isDark),
          const SizedBox(height: 20),
          _buildTextField('رقم الهاتف', 'أدخل رقم الهاتف', _phoneController, isDark, keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          _buildDropdownField('الوظيفة المتقدم لها', ['محاسب', 'مدير مخازن', 'عامل شحن', 'أخرى'], isDark),
        ],
      );
    } else if (_currentStep == 1) {
      return Column(
        children: [
          _buildTextField('اسم المستخدم', 'اختر اسم مستخدم', _usernameController, isDark),
          const SizedBox(height: 20),
          _buildTextField('كلمة المرور', 'أدخل كلمة المرور', _passwordController, isDark, isPassword: true),
          const SizedBox(height: 20),
          _buildTextField('العنوان', 'أدخل العنوان بالتفصيل', _addressController, isDark),
          const SizedBox(height: 20),
          _buildTextField('الراتب المتوقع', 'أدخل الراتب', _salaryController, isDark, keyboardType: TextInputType.number),
        ],
      );
    } else {
      return Column(
        children: _documentImages.keys.map((label) => Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: _buildFileUploadCard(label, isDark),
        )).toList(),
      );
    }
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, bool isDark, {TextInputType keyboardType = TextInputType.text, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.right,
          keyboardType: keyboardType,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          hint: Align(alignment: Alignment.centerRight, child: Text('اختر الوظيفة', style: TextStyle(color: Colors.grey.shade400, fontSize: 13))),
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Align(alignment: Alignment.centerRight, child: Text(value)),
            );
          }).toList(),
          onChanged: (val) => _positionController.text = val ?? '',
        ),
      ],
    );
  }

  Widget _buildFileUploadCard(String label, bool isDark) {
    final hasFile = _documentImages[label] != null;

    return GestureDetector(
      onTap: () => _pickImage(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasFile ? const Color(0xFF1DB954) : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (hasFile)
              const Icon(Icons.check_circle, color: Color(0xFF1DB954))
            else
              const Icon(Icons.cloud_upload_outlined, color: Colors.grey),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  hasFile ? 'تم اختيار الملف' : label,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: hasFile ? const Color(0xFF1DB954) : (isDark ? Colors.grey.shade300 : Colors.black87),
                    fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
            if (hasFile)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(File(_documentImages[label]!), width: 40, height: 40, fit: BoxFit.cover),
              )
            else
              Text(label, style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
