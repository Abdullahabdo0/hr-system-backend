import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../models/leave.dart';
import '../models/user.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class LeaveRequestScreen extends StatefulWidget {
  final User user;
  final Employee employee;
  final String initialRequestType;

  const LeaveRequestScreen({
    super.key,
    required this.user,
    required this.employee,
    this.initialRequestType = 'annual',
  });

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _apiService = ApiService();

  late String _leaveType;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _leaveType = widget.initialRequestType;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isMission => _leaveType == 'mission';

  String _screenTitle() {
    return _isMission ? 'طلب مأمورية' : 'طلب إجازة';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'annual':
        return 'إجازة سنوية';
      case 'sick':
        return 'إجازة مرضية';
      case 'personal':
        return 'إجازة شخصية';
      case 'rest':
        return 'راحة';
      case 'comp_rest':
        return 'بدل راحة';
      case 'mission':
        return 'مأمورية';
      default:
        return type;
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (widget.employee.id == null) {
        throw Exception('معرف الموظف غير موجود');
      }

      final leave = Leave(
        employeeId: widget.employee.id!,
        leaveType: _leaveType,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _apiService.requestLeave(leave);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال ${_typeLabel(_leaveType)} بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_screenTitle()),
          backgroundColor: Colors.green.shade700,
          actions: [
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).toggleTheme();
              },
              tooltip: 'تبديل الوضع',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _leaveType,
                        decoration: InputDecoration(
                          labelText: 'نوع الطلب',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'annual',
                            child: Text('إجازة سنوية'),
                          ),
                          DropdownMenuItem(
                            value: 'sick',
                            child: Text('إجازة مرضية'),
                          ),
                          DropdownMenuItem(
                            value: 'personal',
                            child: Text('إجازة شخصية'),
                          ),
                          DropdownMenuItem(value: 'rest', child: Text('راحة')),
                          DropdownMenuItem(
                            value: 'comp_rest',
                            child: Text('بدل راحة'),
                          ),
                          DropdownMenuItem(
                            value: 'mission',
                            child: Text('مأمورية'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _leaveType = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('تاريخ البداية'),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd').format(_startDate),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked;
                              if (_endDate.isBefore(_startDate)) {
                                _endDate = _startDate;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('تاريخ النهاية'),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd').format(_endDate),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate.isBefore(_startDate)
                                ? _startDate
                                : _endDate,
                            firstDate: _startDate,
                            lastDate: _startDate.add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          labelText: _isMission
                              ? 'تفاصيل المأمورية'
                              : 'سبب الطلب',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) => value?.trim().isEmpty ?? true
                            ? 'الرجاء إدخال ${_isMission ? 'تفاصيل المأمورية' : 'سبب الطلب'}'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'إرسال ${_typeLabel(_leaveType)}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
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
