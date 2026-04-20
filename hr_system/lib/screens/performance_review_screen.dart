import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/performance_review.dart';
import '../models/user.dart';
import '../models/employee.dart';
import '../providers/theme_provider.dart';

class PerformanceReviewScreen extends StatefulWidget {
  final User user;

  const PerformanceReviewScreen({
    super.key,
    required this.user,
  });

  @override
  State<PerformanceReviewScreen> createState() => _PerformanceReviewScreenState();
}

class _PerformanceReviewScreenState extends State<PerformanceReviewScreen> {
  final _apiService = ApiService();
  List<PerformanceReview> _reviews = [];
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
      final reviews = await _apiService.getPerformanceReviews();
      final employees = await _apiService.getEmployees();
      if (mounted) {
        setState(() {
          _reviews = reviews;
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

  Future<void> _showAddReviewDialog() async {
    final commentsController = TextEditingController();
    DateTime reviewDate = DateTime.now();
    int? selectedEmployeeId;
    int rating = 3;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة تقييم أداء'),
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
                  onChanged: (value) => setState(() => selectedEmployeeId = value),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('تاريخ التقييم'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(reviewDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: reviewDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => reviewDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('التقييم (1-5)'),
                Slider(
                  value: rating.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: rating.toString(),
                  onChanged: (value) => setState(() => rating = value.toInt()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: commentsController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
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
                if (selectedEmployeeId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء اختيار الموظف')),
                  );
                  return;
                }
                try {
                  final review = PerformanceReview(
                    employeeId: selectedEmployeeId!,
                    reviewerId: widget.user.id,
                    reviewDate: reviewDate,
                    rating: rating,
                    comments: commentsController.text,
                    createdAt: DateTime.now(),
                  );
                  // ignore: use_build_context_synchronously
                  final ctx = context;
                  await _apiService.addPerformanceReview(review);
                  // ignore: use_build_context_synchronously
                  final snackBar = SnackBar(
                    content: const Text('تم إضافة التقييم بنجاح'),
                  );
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
                  // ignore: use_build_context_synchronously
                  Navigator.pop(ctx);
                  _loadData();
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تقييم الأداء'),
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
            : _reviews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rate, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('لا يوجد تقييمات مسجلة'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade700,
                            child: Text(
                              review.rating.toString(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < review.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(review.reviewDate)}'),
                              if (review.comments != null) Text('ملاحظات: ${review.comments}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              if (review.id == null) return;
                              try {
                                // ignore: use_build_context_synchronously
                                // Add a comment here
                                final ctx = context;
                                await _apiService.deletePerformanceReview(review.id!);
                                _loadData();
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('تم حذف التقييم')),
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
          onPressed: _showAddReviewDialog,
          backgroundColor: Colors.green.shade700,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
