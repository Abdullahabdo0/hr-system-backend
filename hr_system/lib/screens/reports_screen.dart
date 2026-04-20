import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../models/attendance.dart';
import '../models/employee.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Employee> _employees = [];
  bool _isLoading = true;
  int? _selectedEmployeeId;
  DateTime? _startDate;
  DateTime? _endDate;

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
          'position': employee.position,
          'department': employee.department,
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
    var records = _attendanceRecords;
    
    if (_selectedEmployeeId != null) {
      records = records.where((r) => r['attendance'].employeeId == _selectedEmployeeId).toList();
    }
    
    if (_startDate != null) {
      records = records.where((r) => r['attendance'].date.isAfter(_startDate!.subtract(const Duration(days: 1)))).toList();
    }
    
    if (_endDate != null) {
      records = records.where((r) => r['attendance'].date.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
    }
    
    return records;
  }

  Future<void> _exportToCSV() async {
    try {
      final filtered = _filteredRecords;
      if (filtered.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد بيانات للتصدير')),
          );
        }
        return;
      }

      final rows = [
        ['اسم الموظف', 'المنصب', 'القسم', 'التاريخ', 'وقت الحضور', 'وقت الانصراف', 'الساعات', 'الحالة', 'ملاحظات'],
        ...filtered.map((r) {
          final att = r['attendance'] as Attendance;
          return [
            r['employeeName'],
            r['position'],
            r['department'],
            DateFormat('yyyy-MM-dd').format(att.date),
            att.checkInTime != null ? DateFormat('HH:mm').format(att.checkInTime!) : '-',
            att.checkOutTime != null ? DateFormat('HH:mm').format(att.checkOutTime!) : '-',
            att.totalHours.toStringAsFixed(2),
            _getStatusText(att.status),
            att.notes ?? '-',
          ];
        }),
      ];

      final csvString = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/attendance_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      if (mounted) {
        await Share.shareXFiles([XFile(path)], text: 'تقرير الحضور');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تقارير الحضور'),
          backgroundColor: Colors.green.shade700,
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _exportToCSV,
              tooltip: 'تصدير CSV',
            ),
          ],
        ),
        body: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<int?>(
                      initialValue: _selectedEmployeeId,
                      decoration: InputDecoration(
                        labelText: 'فلترة حسب الموظف',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('جميع الموظفين')),
                        ..._employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))),
                      ],
                      onChanged: (value) => setState(() => _selectedEmployeeId = value),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('من تاريخ'),
                            subtitle: Text(_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : 'اختر التاريخ'),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setState(() => _startDate = picked);
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('إلى تاريخ'),
                            subtitle: Text(_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'اختر التاريخ'),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setState(() => _endDate = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                              Icon(Icons.assessment, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('لا توجد بيانات'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            final att = record['attendance'] as Attendance;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.purple.shade700,
                                  child: Text(
                                    (index + 1).toString(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(record['employeeName']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${record['position']} - ${record['department']}'),
                                    Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(att.date)}'),
                                    Text('الحضور: ${att.checkInTime != null ? DateFormat('HH:mm').format(att.checkInTime!) : '-'}'),
                                    Text('الانصراف: ${att.checkOutTime != null ? DateFormat('HH:mm').format(att.checkOutTime!) : '-'}'),
                                    Text('الساعات: ${att.totalHours.toStringAsFixed(2)}'),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(att.status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(att.status),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
