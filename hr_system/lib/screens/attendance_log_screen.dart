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

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الحضور'),
          backgroundColor: Colors.green.shade700,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  labelText: 'ابحث باسم الموظف أو رقمه',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                          Icon(
                            Icons.list_alt,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _attendanceRecords.isEmpty
                                ? 'لا يوجد سجلات'
                                : 'لا يوجد نتيجة مطابقة للبحث',
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        final att = record['attendance'] as Attendance;
                        final employeeName = record['employeeName'] as String;
                        final employeeIdText =
                            record['employeeIdText'] as String;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade700,
                              child: Text(
                                employeeName.isNotEmpty ? employeeName[0] : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(employeeName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('رقم الموظف: $employeeIdText'),
                                Text(
                                  'التاريخ: ${DateFormat('yyyy-MM-dd').format(att.date)}',
                                ),
                                if (att.checkInTime != null)
                                  Text(
                                    'حضور: ${DateFormat('HH:mm').format(att.checkInTime!)}',
                                  ),
                                if (att.checkOutTime != null)
                                  Text(
                                    'انصراف: ${DateFormat('HH:mm').format(att.checkOutTime!)}',
                                  ),
                                Text(
                                  'الساعات: ${att.totalHours.toStringAsFixed(2)}',
                                ),
                                Text('الحالة: ${_getStatusText(att.status)}'),
                              ],
                            ),
                            trailing: _getStatusIcon(att.status),
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

  String _getStatusText(String status) {
    switch (status) {
      case 'present':
        return 'حاضر';
      case 'absent':
        return 'غائب';
      case 'late':
        return 'متأخر';
      default:
        return status;
    }
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'absent':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'late':
        return const Icon(Icons.warning, color: Colors.orange);
      default:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }
}
