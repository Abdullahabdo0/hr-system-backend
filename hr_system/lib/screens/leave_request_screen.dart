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
  List<Leave> _previousRequests = [];

  @override
  void initState() {
    super.initState();
    _leaveType = widget.initialRequestType;
    _loadPreviousRequests();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviousRequests() async {
    try {
      final leaves = await _apiService.getLeaves(employeeId: widget.employee.id!);
      if (mounted) {
        setState(() {
          _previousRequests = [...leaves]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      }
    } catch (e) {
      debugPrint('Error loading previous requests: $e');
    }
  }

  String _screenTitle() {
    return _leaveType == 'mission' ? 'طلب مأمورية' : 'طلب إجازة';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'annual': return 'إجازة سنوية';
      case 'sick': return 'إجازة مرضية';
      case 'personal': return 'إجازة شخصية';
      case 'mission': return 'مأمورية';
      default: return type;
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (widget.employee.id == null) throw Exception('معرف الموظف غير موجود');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال ${_typeLabel(_leaveType)} بنجاح')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF2D9CDB);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _screenTitle(),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('نوع الإجازة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _leaveType,
                        decoration: _inputDecoration('اختر نوع الإجازة', null),
                        items: const [
                          DropdownMenuItem(value: 'annual', child: Text('إجازة سنوية')),
                          DropdownMenuItem(value: 'sick', child: Text('إجازة مرضية')),
                          DropdownMenuItem(value: 'personal', child: Text('إجازة شخصية')),
                          DropdownMenuItem(value: 'mission', child: Text('مأمورية')),
                        ],
                        onChanged: (value) => setState(() => _leaveType = value!),
                      ),
                      
                      const SizedBox(height: 20),
                      const Text('من تاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildDatePickerField(
                        DateFormat('d MMMM yyyy', 'ar').format(_startDate),
                        () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _startDate = picked);
                        },
                      ),

                      const SizedBox(height: 20),
                      const Text('إلى تاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildDatePickerField(
                        DateFormat('d MMMM yyyy', 'ar').format(_endDate),
                        () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: _startDate,
                            lastDate: _startDate.add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                      ),

                      const SizedBox(height: 20),
                      const Text('السبب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        decoration: _inputDecoration('اكتب سبب الإجازة', null),
                        maxLines: 3,
                        validator: (v) => v!.isEmpty ? 'الرجاء إدخال السبب' : null,
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text('إرسال الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),

                      const SizedBox(height: 40),
                      const Text(
                        'طلباتي السابقة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),

                      _previousRequests.isEmpty
                        ? const Text('لا توجد طلبات سابقة')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _previousRequests.length,
                            itemBuilder: (context, index) {
                              final req = _previousRequests[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.grey.shade100),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _typeLabel(req.leaveType),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const Spacer(),
                                        _buildStatusBadge(req.status),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'من ${DateFormat('d MMMM', 'ar').format(req.startDate)} إلى ${DateFormat('d MMMM yyyy', 'ar').format(req.endDate)}',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _buildDatePickerField(String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: Colors.grey.shade300, size: 20),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'approved': color = Colors.green; text = 'مقبول'; break;
      case 'rejected': color = Colors.red; text = 'مرفوض'; break;
      default: color = Colors.orange; text = 'معلق';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
