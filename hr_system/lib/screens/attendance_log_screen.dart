import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/attendance.dart';
import '../services/api_service.dart';

class AttendanceLogScreen extends StatefulWidget {
  const AttendanceLogScreen({super.key});

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredRecords {
    if (_searchQuery.trim().isEmpty) {
      return _attendanceRecords;
    }

    final query = _searchQuery.trim().toLowerCase();
    return _attendanceRecords.where((record) {
      final employeeName = (record['employeeName'] as String).toLowerCase();
      final employeeNumber = (record['employeeIdText'] as String).toLowerCase();
      return employeeName.contains(query) || employeeNumber.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final attendance = await _apiService.getAttendanceRecords();
      final employees = await _apiService.getEmployees();
      final employeesById = {
        for (final employee in employees) employee.id: employee,
      };

      final records = attendance.map((att) {
        final employee = employeesById[att.employeeId];
        return {
          'attendance': att,
          'employeeName': employee?.name ?? 'غير معروف',
          'employeeIdText': att.employeeId.toString(),
        };
      }).toList();

      if (!mounted) return;
      setState(() => _attendanceRecords = records);
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
    final filteredRecords = _filteredRecords;
    final primaryColor = const Color(0xFF1DB954);
    final darkBlue = const Color(0xFF0A0E27);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: darkBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('سجل الحضور', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم الموظف أو رقمه...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                _attendanceRecords.isEmpty ? 'لا يوجد سجلات حضور اليوم' : 'لم نجد نتائج مطابقة لبحثك',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = filteredRecords[index];
                            final att = record['attendance'] as Attendance;
                            final employeeName = record['employeeName'] as String;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(att.status).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(_getStatusIconData(att.status), color: _getStatusColor(att.status), size: 24),
                                  ),
                                ),
                                title: Text(employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Text(DateFormat('yyyy-MM-dd').format(att.date), style: const TextStyle(fontSize: 12)),
                                        const SizedBox(width: 15),
                                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Text(
                                          att.checkInTime != null ? DateFormat('HH:mm').format(att.checkInTime!) : '--:--',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text('إجمالي الساعات: ${att.totalHours.toStringAsFixed(1)} ساعة', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                                trailing: _buildStatusBadge(att.status),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(_getStatusText(status), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'present': return 'حاضر';
      case 'absent': return 'غائب';
      case 'late': return 'متأخر';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present': return Colors.green;
      case 'absent': return Colors.red;
      case 'late': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIconData(String status) {
    switch (status) {
      case 'present': return Icons.check_circle_outline;
      case 'absent': return Icons.highlight_off;
      case 'late': return Icons.history_toggle_off;
      default: return Icons.help_outline;
    }
  }
}
