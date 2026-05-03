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
        final employeeIdText = (record['employeeIdText'] as String).toLowerCase();
        return employeeName.contains(query) || employeeIdText.contains(query);
      }).toList();
    }

    if (_startDate != null) {
      records = records.where((record) {
        final recordDate = record['date'] as DateTime;
        return recordDate.isAfter(_startDate!.subtract(const Duration(days: 1)));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final filtered = _filteredRecords;
      if (filtered.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للتصدير')));
        return;
      }

      final rows = [
        ['نوع السجل', 'اسم الموظف', 'رقم الموظف', 'المنصب', 'القسم', 'التاريخ', 'وقت الحضور', 'وقت الانصراف', 'الساعات', 'نوع الإجازة', 'الحالة'],
        ...filtered.map((record) {
          final type = record['type'] as String;
          if (type == 'attendance') {
            final att = record['attendance'] as Attendance;
            return ['حضور', record['employeeName'], record['employeeIdText'], record['position'], record['department'], DateFormat('yyyy-MM-dd').format(att.date), att.checkInTime != null ? DateFormat('HH:mm').format(att.checkInTime!) : '-', att.checkOutTime != null ? DateFormat('HH:mm').format(att.checkOutTime!) : '-', att.totalHours.toStringAsFixed(2), '-', _getStatusText(att.status)];
          } else {
            final leave = record['leave'] as Leave;
            return ['إجازة', record['employeeName'], record['employeeIdText'], record['position'], record['department'], DateFormat('yyyy-MM-dd').format(leave.startDate), '-', '-', '-', leave.leaveType, 'موافق عليه'];
          }
        }),
      ];

      final csvString = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      if (!mounted) return;
      await Share.shareXFiles([XFile(path)], text: 'تقرير الموارد البشرية');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء التصدير: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _filteredRecords;
    final darkBlue = const Color(0xFF0A0E27);
    final primaryColor = const Color(0xFF1DB954);

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
          title: const Text('تقارير النظام', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(icon: const Icon(Icons.file_download, color: Colors.white), onPressed: _exportToCSV),
          ],
        ),
        body: Column(
          children: [
            // Filter Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: darkBlue,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم الموظف أو رقمه...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildDateSelector('من تاريخ', _startDate, (d) => setState(() => _startDate = d)),
                      const SizedBox(width: 15),
                      _buildDateSelector('إلى تاريخ', _endDate, (d) => setState(() => _endDate = d)),
                    ],
                  ),
                ],
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
                              Icon(Icons.assessment_outlined, size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text('لا توجد بيانات مطابقة للبحث', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = filteredRecords[index];
                            final type = record['type'] as String;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (type == 'attendance' ? Colors.green : Colors.orange).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    type == 'attendance' ? Icons.timer_outlined : Icons.event_available_outlined,
                                    color: type == 'attendance' ? Colors.green : Colors.orange,
                                  ),
                                ),
                                title: Text(record['employeeName'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${record['position']} - ${record['department']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 5),
                                    Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(record['date'] as DateTime)}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                trailing: _buildBadge(type, record),
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

  Widget _buildDateSelector(String label, DateTime? date, Function(DateTime) onSelect) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (picked != null) onSelect(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                date != null ? DateFormat('MM/dd').format(date) : label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String type, Map<String, dynamic> record) {
    if (type == 'attendance') {
      final att = record['attendance'] as Attendance;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: _getStatusColor(att.status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(_getStatusText(att.status), style: TextStyle(color: _getStatusColor(att.status), fontSize: 10, fontWeight: FontWeight.bold)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: const Text('إجازة', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
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
}
