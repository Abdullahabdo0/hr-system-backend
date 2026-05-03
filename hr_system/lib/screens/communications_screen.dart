import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'purchase_request_detail_screen.dart';
import 'new_purchase_request_screen.dart';

class CommunicationsScreen extends StatefulWidget {
  const CommunicationsScreen({super.key});

  @override
  State<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends State<CommunicationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text('المكاتبات والطلبات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF1DB954),
            tabs: const [
              Tab(text: 'المكاتبات'),
              Tab(text: 'طلبات الشراء'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCommunicationsList(),
            _buildPurchaseRequestsList(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewPurchaseRequestScreen()),
          ),
          backgroundColor: const Color(0xFF1DB954),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCommunicationsList() {
    final items = [
      {'title': 'طلب شراء مواد', 'from': 'قسم المخازن', 'msg': 'نرجو الموافقة على طلب شراء المواد...', 'time': 'اليوم'},
      {'title': 'نقل موظف', 'from': 'إدارة الموارد البشرية', 'msg': 'طلب نقل الموظف محمد خالد من...', 'time': 'أمس'},
      {'title': 'استفسار', 'from': 'الإدارة', 'msg': 'استفسار بخصوص التقرير الشهري...', 'time': '12 مايو'},
      {'title': 'طلب صيانة', 'from': 'قسم المخازن', 'msg': 'نرجو عمل صيانة للرف رقم 5...', 'time': '12 مايو'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
          ),
          child: ListTile(
            title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['from']!, style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                Text(item['msg']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['time']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const Icon(Icons.mark_email_unread_outlined, size: 18, color: Colors.blue),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PurchaseRequestDetailScreen(request: item),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPurchaseRequestsList() {
    final requests = [
      {'id': '2024-05-15-001', 'to': 'إدارة المشتريات', 'title': 'طلب شراء مواد خام', 'status': 'قيد المراجعة', 'time': '10:30 AM'},
      {'id': '2024-05-15-002', 'from': 'إدارة المخازن', 'title': 'تقرير عن حركة المواد', 'status': 'تم الرد', 'time': '09:15 AM'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PurchaseRequestDetailScreen(request: req),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(req['to'] != null ? 'إلى: ${req['to']}' : 'من: ${req['from']}', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                      const Spacer(),
                      _buildStatusBadge(req['status']!),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(req['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('رقم: ${req['id']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  Text(req['time']!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'قيد المراجعة' ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showNewMessageDialog() {
    // Placeholder for new message dialog
  }
}
