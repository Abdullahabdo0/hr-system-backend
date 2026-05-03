import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../models/employee.dart';
import '../services/api_service.dart';
import 'employee_form_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();

  List<Employee> _employees = [];
  bool _isLoading = true;
  String _searchQuery = '';

  List<Employee> get _filteredEmployees {
    if (_searchQuery.trim().isEmpty) {
      return _employees;
    }

    final query = _searchQuery.trim().toLowerCase();
    return _employees.where((employee) {
      return employee.name.toLowerCase().contains(query) ||
          employee.position.toLowerCase().contains(query) ||
          employee.department.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final employees = await _apiService.getEmployees();
      if (!mounted) return;
      setState(() => _employees = employees);
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

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الموظف ${employee.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteEmployee(employee.id!);
      await _loadEmployees();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف الموظف بنجاح')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = _filteredEmployees;
    final primaryColor = const Color(0xFF1DB954);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0E27),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('إدارة الموظفين', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم الموظف، القسم، أو الوظيفة...',
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
                    child: filteredEmployees.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _employees.isEmpty ? 'لا يوجد موظفين حالياً' : 'لم نجد نتائج مطابقة لبحثك',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredEmployees.length,
                            itemBuilder: (context, index) {
                              final employee = filteredEmployees[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            employee.name.isNotEmpty ? employee.name[0] : '?',
                                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
                                          ),
                                        ),
                                      ),
                                      title: Text(employee.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      subtitle: Text('${employee.position} - ${employee.department}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                          child: Column(
                                            children: [
                                              const Divider(height: 1),
                                              const SizedBox(height: 15),
                                              _buildDetailRow(Icons.email_outlined, 'البريد', employee.email),
                                              _buildDetailRow(Icons.phone_outlined, 'الهاتف', employee.phone),
                                              _buildDetailRow(Icons.attach_money_outlined, 'الراتب', employee.salary.toStringAsFixed(2)),
                                              const SizedBox(height: 15),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  TextButton.icon(
                                                    onPressed: () async {
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(builder: (context) => EmployeeFormScreen(employee: employee)),
                                                      );
                                                      _loadEmployees();
                                                    },
                                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                    label: const Text('تعديل', style: TextStyle(color: Colors.blue)),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  TextButton.icon(
                                                    onPressed: () => _deleteEmployee(employee),
                                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                                    label: const Text('حذف', style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmployeeFormScreen()),
            );
            _loadEmployees();
          },
          backgroundColor: const Color(0xFF0A0E27),
          child: const Icon(Icons.person_add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 5),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
