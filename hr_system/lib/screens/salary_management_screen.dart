import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/salary_payment.dart';
import '../models/user.dart';
import '../models/employee.dart';
import '../providers/theme_provider.dart';

class SalaryManagementScreen extends StatefulWidget {
  final User user;

  const SalaryManagementScreen({
    super.key,
    required this.user,
  });

  @override
  State<SalaryManagementScreen> createState() => _SalaryManagementScreenState();
}

class _SalaryManagementScreenState extends State<SalaryManagementScreen> {
  final _apiService = ApiService();
  List<SalaryPayment> _payments = [];
  List<Employee> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final payments = await _apiService.getSalaryPayments();
      final employees = await _apiService.getEmployees();
      if (mounted) {
        setState(() {
          _payments = payments;
          _employees = employees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _showAddPaymentDialog() async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    DateTime paymentDate = DateTime.now();
    int? selectedEmployeeId;
    String paymentType = 'salary';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دفعة راتب'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedEmployeeId,
                decoration: InputDecoration(
                  labelText: 'الموظف',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _employees.map((e) {
                  return DropdownMenuItem(
                    value: e.id,
                    child: Text(e.name),
                  );
                }).toList(),
                onChanged: (value) => selectedEmployeeId = value,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: paymentType,
                decoration: InputDecoration(
                  labelText: 'نوع الدفعة',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'salary', child: Text('راتب')),
                  DropdownMenuItem(value: 'bonus', child: Text('مكافأة')),
                  DropdownMenuItem(value: 'deduction', child: Text('خصم')),
                ],
                onChanged: (value) => paymentType = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('تاريخ الدفعة'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(paymentDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: paymentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    paymentDate = picked;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'ملاحظات',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedEmployeeId == null || amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء اختيار الموظف وإدخال المبلغ')),
                );
                return;
              }
              try {
                final payment = SalaryPayment(
                  employeeId: selectedEmployeeId!,
                  amount: double.tryParse(amountController.text) ?? 0,
                  paymentDate: paymentDate,
                  paymentType: paymentType,
                  notes: notesController.text,
                  createdAt: DateTime.now(),
                );
                // ignore: use_build_context_synchronously
                final ctx = context;
                await _apiService.addSalaryPayment(payment);
                // ignore: use_build_context_synchronously
                Navigator.pop(ctx);
                _loadData();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('تم إضافة الدفعة بنجاح')),
                );
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e')),
                );
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  String _getPaymentTypeText(String type) {
    switch (type) {
      case 'salary':
        return 'راتب';
      case 'bonus':
        return 'مكافأة';
      case 'deduction':
        return 'خصم';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة دفعات الرواتب'),
          backgroundColor: Colors.green.shade700,
          actions: [
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              },
              tooltip: 'الوضع الداكن',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _payments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payments, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('لا يوجد دفعات مسجلة'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade700,
                            child: Text(
                              _getPaymentTypeText(payment.paymentType)[0],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text('${_getPaymentTypeText(payment.paymentType)}: ${payment.amount.toStringAsFixed(2)}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(payment.paymentDate)}'),
                              if (payment.notes != null) Text('ملاحظات: ${payment.notes}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              if (payment.id == null) return;
                              try {
                                // ignore: use_build_context_synchronously
                                final ctx = context;
                                await _apiService.deleteSalaryPayment(payment.id!);
                                _loadData();
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('تم حذف الدفعة')),
                                );
                              } catch (e) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('خطأ: $e')),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddPaymentDialog,
          backgroundColor: Colors.green.shade700,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
