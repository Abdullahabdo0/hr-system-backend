import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/employee.dart';
import '../models/leave.dart';
import '../services/api_service.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final _apiService = ApiService();

  List<Leave> _leaves = [];
  Map<int, Employee> _employeesById = {};
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  bool _isMissionRequest(Leave leave) => leave.leaveType == 'mission';

  List<Leave> get _filteredLeaves {
    switch (_selectedFilter) {
      case 'leave':
        return _leaves.where((leave) => !_isMissionRequest(leave)).toList();
      case 'mission':
        return _leaves.where(_isMissionRequest).toList();
      default:
        return _leaves;
    }
  }

  Future<void> _loadLeaves() async {
    setState(() => _isLoading = true);
    try {
      final leaves = await _apiService.getLeaves();
      final employees = await _apiService.getEmployees();

      if (!mounted) return;
      setState(() {
        _leaves = leaves;
        _employeesById = {
          for (final employee in employees)
            if (employee.id != null) employee.id!: employee,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  String _getLeaveTypeText(String type) {
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

  String _getStatusText(String status) {
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

  Color _getStatusColor(String status) {
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

  String _getEmployeeName(int employeeId) {
    return _employeesById[employeeId]?.name ?? 'غير معروف';
  }

  String _getEmployeeNumber(int employeeId) {
    return _employeesById[employeeId]?.id?.toString() ?? employeeId.toString();
  }

  Future<void> _approveLeave(Leave leave) async {
    if (leave.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('معرّف الطلب غير موجود')));
      return;
    }

    try {
      await _apiService.approveLeave(leave.id!, 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت الموافقة على ${_getLeaveTypeText(leave.leaveType)}'),
        ),
      );
      await _loadLeaves();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  Future<void> _rejectLeave(Leave leave) async {
    if (leave.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('معرّف الطلب غير موجود')));
      return;
    }

    try {
      await _apiService.rejectLeave(leave.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم رفض ${_getLeaveTypeText(leave.leaveType)}')),
      );
      await _loadLeaves();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  Widget _buildEmptyState() {
    String message;
    switch (_selectedFilter) {
      case 'leave':
        message = 'لا توجد طلبات إجازة حالياً';
        break;
      case 'mission':
        message = 'لا توجد طلبات مأمورية حالياً';
        break;
      default:
        message = 'لا توجد طلبات حالياً';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLeaves = _filteredLeaves;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الطلبات'),
          backgroundColor: Colors.green.shade700,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment<String>(
                              value: 'all',
                              label: Text('الكل'),
                              icon: Icon(Icons.list_alt),
                            ),
                            ButtonSegment<String>(
                              value: 'leave',
                              label: Text('الإجازات'),
                              icon: Icon(Icons.event),
                            ),
                            ButtonSegment<String>(
                              value: 'mission',
                              label: Text('المأموريات'),
                              icon: Icon(Icons.work_history),
                            ),
                          ],
                          selected: {_selectedFilter},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) {
                            setState(() => _selectedFilter = selection.first);
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'عدد الطلبات: ${filteredLeaves.length}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredLeaves.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: filteredLeaves.length,
                            itemBuilder: (context, index) {
                              final leave = filteredLeaves[index];
                              final leaveTypeText = _getLeaveTypeText(
                                leave.leaveType,
                              );

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getStatusColor(
                                      leave.status,
                                    ),
                                    child: Text(
                                      leaveTypeText[0],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(leaveTypeText),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'اسم الموظف: ${_getEmployeeName(leave.employeeId)}',
                                      ),
                                      Text(
                                        'رقم الموظف: ${_getEmployeeNumber(leave.employeeId)}',
                                      ),
                                      Text(
                                        'من: ${DateFormat('yyyy-MM-dd').format(leave.startDate)}',
                                      ),
                                      Text(
                                        'إلى: ${DateFormat('yyyy-MM-dd').format(leave.endDate)}',
                                      ),
                                      if (leave.reason != null &&
                                          leave.reason!.trim().isNotEmpty)
                                        Text('التفاصيل: ${leave.reason}'),
                                      Text(
                                        'الحالة: ${_getStatusText(leave.status)}',
                                        style: TextStyle(
                                          color: _getStatusColor(leave.status),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: leave.status == 'pending'
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.check,
                                                color: Colors.green,
                                              ),
                                              onPressed: () =>
                                                  _approveLeave(leave),
                                              tooltip: 'موافقة',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  _rejectLeave(leave),
                                              tooltip: 'رفض',
                                            ),
                                          ],
                                        )
                                      : null,
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
}
