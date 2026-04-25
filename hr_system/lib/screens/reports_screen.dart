import 'dart:io';
import 'dart:ui' as ui;

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/attendance.dart';
import '../models/leave.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _allRecords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> get _filteredRecords {
    var records = _allRecords;

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      records = records.where((record) {
        final employeeName = (record['employeeName'] as String).toLowerCase();
        final employeeIdText = (record['employeeIdText'] as String)
            .toLowerCase();
        return employeeName.contains(query) || employeeIdText.contains(query);
      }).toList();
    }

    if (_startDate != null) {
      records = records.where((record) {
        final recordDate = record['date'] as DateTime;
        return recordDate.isAfter(
          _startDate!.subtract(const Duration(days: 1)),
        );
      }).toList();
    }

    if (_endDate != null) {
      records = records.where((record) {
        final recordDate = record['date'] as DateTime;
        return recordDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    return records;
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
      final leaves = await _apiService.getLeaves();
      final employees = await _apiService.getEmployees();
      final employeesById = {
        for (final employee in employees) employee.id: employee,
      };

      // Process attendance records
      final attendanceRecords = attendance.map((att) {
        final employee = employeesById[att.employeeId];
        return {
          'type': 'attendance',
          'date': att.date,
          'attendance': att,
          'employeeName': employee?.name ?? 'غير معروف',
          'employeeIdText': att.employeeId.toString(),
          'position': employee?.position ?? '',
          'department': employee?.department ?? '',
        };
      }).toList();

      // Process approved leave records
      final leaveRecords = leaves.where((leave) => leave.status == 'approved').map((leave) {
        final employee = employeesById[leave.employeeId];
        return {
          'type': 'leave',
          'date': leave.startDate,
          'leave': leave,
          'employeeName': employee?.name ?? 'غير معروف',
          'employeeIdText': leave.employeeId.toString(),
          'position': employee?.position ?? '',
          'department': employee?.department ?? '',
        };
      }).toList();

      // Merge all records and sort by date
      final allRecords = [...attendanceRecords, ...leaveRecords];
      allRecords.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (!mounted) return;
      setState(() {
        _allRecords = allRecords;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (!mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final filtered = _filteredRecords;
      if (filtered.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للتصدير')));
        return;
      }

      final rows = [
        [
          'نوع السجل',
          'اسم الموظف',
          'رقم الموظف',
          'المنصب',
          'القسم',
          'التاريخ',
          'وقت الحضور',
          'وقت الانصراف',
          'الساعات',
          'نوع الإجازة',
          'من تاريخ',
          'إلى تاريخ',
          'الحالة',
          'ملاحظات',
        ],
        ...filtered.map((record) {
          final type = record['type'] as String;
          if (type == 'attendance') {
            final att = record['attendance'] as Attendance;
            return [
              'حضور',
              record['employeeName'],
              record['employeeIdText'],
              record['position'],
              record['department'],
              DateFormat('yyyy-MM-dd').format(att.date),
              att.checkInTime != null
                  ? DateFormat('HH:mm').format(att.checkInTime!)
                  : '-',
              att.checkOutTime != null
                  ? DateFormat('HH:mm').format(att.checkOutTime!)
                  : '-',
              att.totalHours.toStringAsFixed(2),
              '-',
              '-',
              '-',
              _getStatusText(att.status),
              att.notes ?? '-',
            ];
          } else {
            final leave = record['leave'] as Leave;
            return [
              'إجازة',
              record['employeeName'],
              record['employeeIdText'],
              record['position'],
              record['department'],
              DateFormat('yyyy-MM-dd').format(leave.startDate),
              '-',
              '-',
              '-',
              leave.leaveType,
              DateFormat('yyyy-MM-dd').format(leave.startDate),
              DateFormat('yyyy-MM-dd').format(leave.endDate),
              'موافق عليه',
              leave.reason ?? '-',
            ];
          }
        }),
      ];

      final csvString = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/attendance_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      if (!mounted) return;
      await Share.shareXFiles([XFile(path)], text: 'تقرير الحضور');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _filteredRecords;

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
                    TextField(
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('من تاريخ'),
                            subtitle: Text(
                              _startDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_startDate!)
                                  : 'اختر التاريخ',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _startDate = picked);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('إلى تاريخ'),
                            subtitle: Text(
                              _endDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                  : 'اختر التاريخ',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _endDate = picked);
                              }
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
                  : filteredRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assessment,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _allRecords.isEmpty
                                ? 'لا توجد بيانات'
                                : 'لا توجد نتيجة مطابقة للبحث',
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        final type = record['type'] as String;

                        if (type == 'attendance') {
                          final att = record['attendance'] as Attendance;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade700,
                                child: const Icon(Icons.check_circle, color: Colors.white),
                              ),
                              title: Text(record['employeeName'] as String),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('رقم الموظف: ${record['employeeIdText']}'),
                                  Text(
                                    '${record['position']} - ${record['department']}',
                                  ),
                                  Text(
                                    'التاريخ: ${DateFormat('yyyy-MM-dd').format(att.date)}',
                                  ),
                                  Text(
                                    'الحضور: ${att.checkInTime != null ? DateFormat('HH:mm').format(att.checkInTime!) : '-'}',
                                  ),
                                  Text(
                                    'الانصراف: ${att.checkOutTime != null ? DateFormat('HH:mm').format(att.checkOutTime!) : '-'}',
                                  ),
                                  Text(
                                    'الساعات: ${att.totalHours.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(att.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(att.status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          final leave = record['leave'] as Leave;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.shade700,
                                child: const Icon(Icons.event, color: Colors.white),
                              ),
                              title: Text(record['employeeName'] as String),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('رقم الموظف: ${record['employeeIdText']}'),
                                  Text(
                                    '${record['position']} - ${record['department']}',
                                  ),
                                  Text(
                                    'نوع الإجازة: ${leave.leaveType}',
                                  ),
                                  Text(
                                    'من: ${DateFormat('yyyy-MM-dd').format(leave.startDate)}',
                                  ),
                                  Text(
                                    'إلى: ${DateFormat('yyyy-MM-dd').format(leave.endDate)}',
                                  ),
                                  if (leave.reason != null && leave.reason!.isNotEmpty)
                                    Text('السبب: ${leave.reason}'),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'إجازة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
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
