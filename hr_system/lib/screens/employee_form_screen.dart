import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/employee.dart';
import '../services/api_service.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _locationController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _addressController = TextEditingController();
  final _salaryController = TextEditingController();

  DateTime _hireDate = DateTime.now();
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    if (employee != null) {
      _nameController.text = employee.name;
      _emailController.text = employee.email;
      _phoneController.text = employee.phone;
      _positionController.text = employee.position;
      _departmentController.text = employee.department;
      _locationController.text = employee.location;
      _nationalIdController.text = employee.nationalId;
      _qualificationController.text = employee.qualification;
      _addressController.text = employee.address;
      _salaryController.text = employee.salary.toString();
      _hireDate = employee.hireDate;
      _status = employee.status;
    }
  }

  @override
  void dispose() {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final employee = Employee(
      id: widget.employee?.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      position: _positionController.text.trim(),
      department: _departmentController.text.trim(),
      location: _locationController.text.trim(),
      nationalId: _nationalIdController.text.trim(),
      qualification: _qualificationController.text.trim(),
      address: _addressController.text.trim(),
      hireDate: _hireDate,
      salary: double.tryParse(_salaryController.text.trim()) ?? 0,
      status: _status,
    );

    try {
      if (widget.employee == null) {
        await _apiService.addEmployee(employee);
      } else {
        await _apiService.updateEmployee(employee);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.employee == null ? 'تمت إضافة الموظف' : 'تم تعديل الموظف',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) =>
          value?.trim().isEmpty ?? true ? 'الرجاء إدخال $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.employee == null ? 'إضافة موظف جديد' : 'تعديل الموظف',
          ),
          backgroundColor: Colors.green.shade700,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField(
                  controller: _nameController,
                  label: 'اسم الموظف',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _positionController,
                  label: 'الوظيفة',
                  icon: Icons.work,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _departmentController,
                  label: 'القسم',
                  icon: Icons.business,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _locationController,
                  label: 'المكان',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _nationalIdController,
                  label: 'رقم القومي',
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _qualificationController,
                  label: 'المؤهل',
                  icon: Icons.school,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _phoneController,
                  label: 'رقم التلفون',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _addressController,
                  label: 'العنوان',
                  icon: Icons.home,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _salaryController,
                  label: 'الراتب',
                  icon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('تاريخ التعيين'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_hireDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _hireDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _hireDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: 'الحالة',
                    prefixIcon: const Icon(Icons.check_circle),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('نشط')),
                    DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'active'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'حفظ',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
