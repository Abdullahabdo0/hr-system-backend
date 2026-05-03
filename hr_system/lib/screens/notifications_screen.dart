import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {'title': 'تم اعتماد طلب الشراء رقم 2024-05-15-001', 'time': 'منذ 5 دقائق', 'icon': Icons.check_circle_outline, 'color': Colors.blue},
      {'title': 'رد على مكاتبتك من الإدارة المالية', 'time': 'منذ 1 ساعة', 'icon': Icons.reply, 'color': Colors.indigo},
      {'title': 'طلب إجازتك تم قبوله', 'time': 'منذ 2 ساعة', 'icon': Icons.beach_access, 'color': Colors.green},
      {'title': 'تقرير المخزن الشهري جاهز', 'time': 'منذ يوم', 'icon': Icons.assessment_outlined, 'color': Colors.red},
      {'title': 'اجتماع إداري غداً الساعة 10:00 ص', 'time': 'منذ يومين', 'icon': Icons.groups_outlined, 'color': Colors.blueGrey},
    ];

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
          title: const Text('الإشعارات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final note = notifications[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: (note['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(note['icon'] as IconData, color: note['color'] as Color, size: 24),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text(note['time'] as String, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A0E27), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: const Text('عرض الكل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
