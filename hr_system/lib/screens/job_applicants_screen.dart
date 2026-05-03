import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class JobApplicantsScreen extends StatefulWidget {
  const JobApplicantsScreen({super.key});

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  final List<Map<String, dynamic>> _applicants = [
    {
      'name': 'أحمد محمد علي',
      'position': 'محاسب',
      'date': '15 مايو 2024',
      'status': 'جديد',
      'image': 'https://i.pravatar.cc/150?u=1',
    },
    {
      'name': 'سارة عبد الرحمن',
      'position': 'موظف مخزن',
      'date': '14 مايو 2024',
      'status': 'قيد المراجعة',
      'image': 'https://i.pravatar.cc/150?u=2',
    },
    {
      'name': 'محمد إبراهيم',
      'position': 'مدخل بيانات',
      'date': '14 مايو 2024',
      'status': 'جديد',
      'image': 'https://i.pravatar.cc/150?u=3',
    },
    {
      'name': 'نورهان حسن',
      'position': 'موظف إداري',
      'date': '13 مايو 2024',
      'status': 'مرفوض',
      'image': 'https://i.pravatar.cc/150?u=4',
    },
    {
      'name': 'كريم محمود',
      'position': 'مندوب مبيعات',
      'date': '12 مايو 2024',
      'status': 'قيد المراجعة',
      'image': 'https://i.pravatar.cc/150?u=5',
    },
  ];

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
          title: const Text('المتقدمين للوظائف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'بحث عن متقدم...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: const Icon(Icons.filter_list, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _applicants.length,
                itemBuilder: (context, index) {
                  final app = _applicants[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(image: NetworkImage(app['image']), fit: BoxFit.cover),
                        ),
                      ),
                      title: Text(app['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app['position'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          Text(app['date'], style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                        ],
                      ),
                      trailing: _buildStatusBadge(app['status']),
                      onTap: () => _showApplicantDetails(app),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'جديد': color = Colors.blue; break;
      case 'قيد المراجعة': color = Colors.orange; break;
      case 'مرفوض': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _showApplicantDetails(Map<String, dynamic> applicant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicantDetailsScreen(applicant: applicant),
      ),
    );
  }
}

class ApplicantDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> applicant;

  const ApplicantDetailsScreen({super.key, required this.applicant});

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
          title: const Text('تفاصيل المتقدم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF0A0E27),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  CircleAvatar(radius: 50, backgroundImage: NetworkImage(applicant['image'])),
                  const SizedBox(height: 15),
                  Text(applicant['name'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(applicant['position'], style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('البيانات الشخصية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _buildInfoCard([
                      _buildInfoRow(Icons.email, 'البريد الإلكتروني', 'ahmed.m@email.com'),
                      _buildInfoRow(Icons.phone, 'الهاتف', '01012345678'),
                      _buildInfoRow(Icons.school, 'المؤهل', 'بكالوريوس تجارة'),
                      _buildInfoRow(Icons.star, 'الخبرة', '3 سنوات'),
                    ]),
                    const SizedBox(height: 30),
                    const Text('السيرة الذاتية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                          const SizedBox(width: 15),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ahmed_Resume.pdf', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('1.2 MB', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('قبول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('رفض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
