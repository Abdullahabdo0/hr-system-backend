import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class NewPurchaseRequestScreen extends StatefulWidget {
  const NewPurchaseRequestScreen({super.key});

  @override
  State<NewPurchaseRequestScreen> createState() => _NewPurchaseRequestScreenState();
}

class _NewPurchaseRequestScreenState extends State<NewPurchaseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _departmentController = TextEditingController();
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController();
  final _specsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
          title: const Text('طلب شراء جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('الإدارة المستفيدة'),
                _buildDropdownField('اختر الإدارة', ['إدارة المخازن', 'إدارة المشتريات', 'الموارد البشرية']),
                const SizedBox(height: 20),
                
                _buildFieldLabel('الصنف المطلوب'),
                _buildDropdownField('اختر الصنف', ['مواد بناء', 'أدوات مكتبية', 'أجهزة إلكترونية']),
                const SizedBox(height: 20),

                _buildFieldLabel('الكمية'),
                _buildTextField(_quantityController, 'أدخل الكمية', Icons.numbers),
                const SizedBox(height: 20),

                _buildFieldLabel('المواصفات'),
                _buildTextField(_specsController, 'اكتب المواصفات المطلوبة', Icons.description_outlined, maxLines: 4),
                const SizedBox(height: 20),

                _buildFieldLabel('مرفقات (اختياري)'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_file, color: primaryColor),
                      const SizedBox(width: 10),
                      Text('إضافة مرفق', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب بنجاح')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('إرسال الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        suffixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
      validator: (val) => val!.isEmpty ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildDropdownField(String hint, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) {},
        ),
      ),
    );
  }
}
