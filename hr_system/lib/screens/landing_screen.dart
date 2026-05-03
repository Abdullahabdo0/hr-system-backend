import 'package:flutter/material.dart';
import 'login_type_selection_screen.dart';
import 'employee_registration_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1DB954);
    final secondaryColor = const Color(0xFF2D9CDB);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E12), // Dark background from design
      body: Stack(
        children: [
          // Hero Section Background (Simple representation of the image)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Opacity(
              opacity: 0.3,
              child: Image.network(
                'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&q=80&w=2070',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Custom Header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'إدارة المخازن\nنظام متكامل للإدارة',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.inventory_2, color: Color(0xFF1DB954), size: 30),
                    ],
                  ),
                  const Spacer(),
                  // Main Content
                  const Text(
                    'إدارة مخازنك\nبذكاء وسهولة',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'نظام متكامل لإدارة المخزون والمشتريات والمستندات\nيربط بين الإدارات ويرفع كفاءة الأداء',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Feature Mini Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildMiniFeature(Icons.description_outlined, 'تقارير لحظية'),
                      const SizedBox(width: 12),
                      _buildMiniFeature(Icons.sync_alt, 'ربط بين الإدارات'),
                      const SizedBox(width: 12),
                      _buildMiniFeature(Icons.business_center_outlined, 'إدارة متكاملة'),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'دخول الموظفين',
                          Icons.person_outline,
                          primaryColor,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginTypeSelectionScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'تقديم على وظيفة',
                          Icons.work_outline,
                          secondaryColor,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EmployeeRegistrationScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFeature(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
