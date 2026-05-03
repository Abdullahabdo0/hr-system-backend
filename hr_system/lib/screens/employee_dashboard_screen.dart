import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/attendance.dart';
import '../models/employee.dart';
import '../models/leave.dart';
import '../models/user.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'leave_request_screen.dart';
import 'login_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final User user;
  final Employee employee;

  const EmployeeDashboardScreen({
    super.key,
    required this.user,
    required this.employee,
  });

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  final ApiService _apiService = ApiService();

  List<Attendance> _attendanceRecords = [];
  List<Leave> _leaveRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final employeeId = widget.employee.id;
      if (employeeId == null) {
        throw Exception('معرف الموظف غير موجود');
      }

      final attendance = await _apiService.getAttendanceRecords();
      final leaves = await _apiService.getLeaves(employeeId: employeeId);

      if (!mounted) return;

      setState(() {
        _attendanceRecords = attendance
            .where((record) => record.employeeId == employeeId)
            .toList();
        _leaveRequests = [...leaves]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
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

  Future<void> _checkIn() async {
    try {
      await _apiService.checkIn(widget.employee.id!);
      await _loadDashboardData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تسجيل الحضور بنجاح')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  Future<void> _checkOut() async {
    try {
      await _apiService.checkOut(widget.employee.id!);
      await _loadDashboardData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تسجيل الانصراف بنجاح')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  bool _hasCheckedInToday() {
    if (_attendanceRecords.isEmpty) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _attendanceRecords.any((record) {
      final recordDay = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      return recordDay == today &&
          record.checkInTime != null &&
          record.checkOutTime == null;
    });
  }

  Future<void> _openRequestScreen(String type) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => LeaveRequestScreen(
          user: widget.user,
          employee: widget.employee,
          initialRequestType: type,
        ),
      ),
    );

    if (created == true && mounted) {
      await _loadDashboardData();
    }
  }

  String _getRequestTypeText(String type) {
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

  String _getRequestStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'تمت الموافقة';
      case 'rejected':
        return 'تم الرفض';
      default:
        return status;
    }
  }

  Color _getRequestStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getAttendanceStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  Color _getAttendanceStatusColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    final pendingCount = _leaveRequests
        .where((request) => request.status == 'pending')
        .length;
    final approvedCount = _leaveRequests
        .where((request) => request.status == 'approved')
        .length;
    final rejectedCount = _leaveRequests
        .where((request) => request.status == 'rejected')
        .length;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الموظف'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
              tooltip: 'تحديث',
            ),
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
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.employee.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('الوظيفة: ${widget.employee.position}'),
                              Text('القسم: ${widget.employee.department}'),
                              Text('المكان: ${widget.employee.location}'),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.attach_money,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'الراتب: ${widget.employee.salary.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _hasCheckedInToday() ? null : _checkIn,
                              icon: const Icon(Icons.login),
                              label: const Text('تسجيل الحضور'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _hasCheckedInToday()
                                  ? _checkOut
                                  : null,
                              icon: const Icon(Icons.logout),
                              label: const Text('تسجيل الانصراف'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openRequestScreen('annual'),
                              icon: const Icon(Icons.event),
                              label: const Text('طلب إجازة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openRequestScreen('mission'),
                              icon: const Icon(Icons.work_history),
                              label: const Text('مأمورية'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'حالة الطلبات',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatusBadge(
                            label: 'قيد الانتظار',
                            count: pendingCount,
                            color: Colors.orange,
                          ),
                          _StatusBadge(
                            label: 'تمت الموافقة',
                            count: approvedCount,
                            color: Colors.green,
                          ),
                          _StatusBadge(
                            label: 'تم الرفض',
                            count: rejectedCount,
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'طلباتي',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _leaveRequests.isEmpty
                          ? const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('لا توجد طلبات حتى الآن'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _leaveRequests.length,
                              itemBuilder: (context, index) {
                                final request = _leaveRequests[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _getRequestTypeText(
                                                  request.leaveType,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getRequestStatusColor(
                                                  request.status,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _getRequestStatusText(
                                                  request.status,
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'من: ${DateFormat('yyyy-MM-dd').format(request.startDate)}',
                                        ),
                                        Text(
                                          'إلى: ${DateFormat('yyyy-MM-dd').format(request.endDate)}',
                                        ),
                                        Text(
                                          'تاريخ الطلب: ${DateFormat('yyyy-MM-dd').format(request.createdAt)}',
                                        ),
                                        if (request.reason != null &&
                                            request.reason!.trim().isNotEmpty)
                                          Text('التفاصيل: ${request.reason}'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 24),
                      const Text(
                        'سجل الحضور',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _attendanceRecords.isEmpty
                          ? const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('لا توجد سجلات حضور'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _attendanceRecords.length,
                              itemBuilder: (context, index) {
                                final record = _attendanceRecords[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(record.date),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (record.checkInTime != null)
                                          Text(
                                            'حضور: ${DateFormat('HH:mm').format(record.checkInTime!)}',
                                          ),
                                        if (record.checkOutTime != null)
                                          Text(
                                            'انصراف: ${DateFormat('HH:mm').format(record.checkOutTime!)}',
                                          ),
                                        if (record.totalHours > 0)
                                          Text(
                                            'إجمالي الساعات: ${record.totalHours.toStringAsFixed(2)}',
                                          ),
                                      ],
                                    ),
                                    trailing: Icon(
                                      _getAttendanceStatusIcon(record.status),
                                      color: _getAttendanceStatusColor(
                                        record.status,
                                      ),
                                    ),
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
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
