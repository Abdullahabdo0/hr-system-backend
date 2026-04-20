import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/attendance.dart';
import '../models/employee.dart';

class AttendanceLogScreen extends StatefulWidget {
  const AttendanceLogScreen({super.key});

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Employee> _employees = [];
  bool _isLoading = true;
  int? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final attendance = await _apiService.getAttendanceRecords();
      final employees = await _apiService.getEmployees();
      
      // Join attendance with employee names
      final records = <Map<String, dynamic>>[];
      for (var att in attendance) {
        final employee = employees.firstWhere(
          (e) => e.id == att.employeeId,
          orElse: () => Employee(
            id: att.employeeId,
            name: 'غير معروف',
            email: '',
            phone: '',
            position: '',
            department: '',
            hireDate: DateTime.now(),
            salary: 0,
          ),
        );
        records.add({
          'attendance': att,
          'employeeName': employee.name,
        });
      }
      
      setState(() {
        _attendanceRecords = records;
        _employees = employees;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_selectedEmployeeId == null) return _attendanceRecords;
    return _attendanceRecords.where((r) => r['attendance'].employeeId == _selectedEmployeeId).toList();
  }

  @override
  Widget build(BuildContext context) {
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
              child: DropdownButtonFormField<int?>(
                initialValue: _selectedEmployeeId,
                decoration: InputDecoration(
                  labelText: 'فلترة حسب الموظف',
                  prefixIcon: const Icon(Icons.filter_list),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              items: [
                const DropdownMenuItem(value: null, child: Text('جميع الموظفين')),
                ..._employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))),
              ],
              onChanged: (value) => setState(() => _selectedEmployeeId = value),
            ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.list_alt, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('لا يوجد سجلات'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            final att = record['attendance'] as Attendance;
                            final employeeName = record['employeeName'] as String;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.shade700,
                                  child: Text(
                                    employeeName[0],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(employeeName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(att.date)}'),
                                    if (att.checkInTime != null)
                                      Text('حضور: ${DateFormat('HH:mm').format(att.checkInTime!)}'),
                                    if (att.checkOutTime != null)
                                      Text('انصراف: ${DateFormat('HH:mm').format(att.checkOutTime!)}'),
                                    Text('الساعات: ${att.totalHours.toStringAsFixed(2)}'),
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
