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
      backgroundColor: const Color(0xFF0A0E12),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Hero Section
            Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?q=80&w=2070'),
                      fit: BoxFit.cover,
                      opacity: 0.3,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 10),
                        // Header
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'إدارة المخازن\nنظام متكامل للإدارة',
                              textAlign: TextAlign.right,
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.inventory_2, color: Color(0xFF1DB954), size: 35),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                        // Hero Content
                        const Text(
                          'إدارة مخازنك\nبذكاء وسهولة',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            shadows: [
                              Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'نظام متكامل لإدارة المخزون والمشتريات والمستندات\nيربط بين الإدارات ويرفع كفاءة الأداء',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white, // Changed from white70 to full white
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                            shadows: [
                              Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Features - Using Wrap to avoid overflow
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.end,
                          children: [
                            _buildMiniFeature(Icons.description_outlined, 'تقارير لحظية'),
                            _buildMiniFeature(Icons.sync_alt, 'ربط بين الإدارات'),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 2. White Sections Container
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Video Section
                  _buildSectionTitle('فيديو تعريفي عن نظام إدارة المخازن'),
                  const SizedBox(height: 20),
                  _buildVideoCard('https://images.unsplash.com/photo-1553413077-190dd305871c?q=80&w=1935'),
                  
                  const SizedBox(height: 40),
                  // About Section
                  _buildAboutSection(),

                  const SizedBox(height: 40),
                  // Cards Grid (About Mgmt, Tour, CEO)
                  _buildCardsGrid(),

                  const SizedBox(height: 40),
                  // Goals Section
                  _buildGoalsSection(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A), // Darker black for better contrast
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF1DB954), size: 50),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'عن إدارة المخازن',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          const Text(
            'نظام يساعد الإدارات المختلفة على إدارة المخزون والمشتريات والمراسلات الداخلية بكفاءة عالية، بدون ورق وبخطوات بسيطة وسريعة.',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF333333), // Darker grey for better readability
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text(
              'اقرأ المزيد ←',
              style: TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // About Management Card
          _buildInfoCard(
            title: 'حول الإدارة',
            content: 'نحن نؤمن بأهمية التنظيم والدقة في إدارة المخزون لتحقيق أعلى مستويات الكفاءة وتقليل الهدر والتكاليف.',
            isDark: true,
          ),
          const SizedBox(height: 20),
          // Warehouse Tour Card
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1587293852726-70cdb56c2866?q=80&w=2072'),
                fit: BoxFit.cover,
              ),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
                const Center(child: Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 60)),
                const Positioned(
                  right: 20,
                  bottom: 20,
                  child: Text(
                    'جولة داخل المخزن',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // CEO Card
          _buildInfoCard(
            title: 'كلمة المدير العام',
            content: 'نحن ملتزمون بتطوير أعمالنا باستخدام أحدث التقنيات وتحقيق التكامل بين جميع الإدارات للوصول لأعلى مستويات الجودة.',
            isDark: false,
            showQuote: true,
            imageUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=1974',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content, bool isDark = false, bool showQuote = false, String? imageUrl}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0E12) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(24),
        border: isDark ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Hero(
              tag: 'ceo_image',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imageUrl, width: 90, height: 120, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showQuote) const Icon(Icons.format_quote_rounded, color: Color(0xFF1DB954), size: 35),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF444444),
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'اقرأ المزيد',
                  style: TextStyle(
                    color: const Color(0xFF1DB954),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'أهدافنا',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              const Icon(Icons.ads_click_rounded, size: 90, color: Color(0xFF1DB954)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildGoalItem('تسهيل العمليات الإدارية وإلغاء الورق'),
                    _buildGoalItem('رفع كفاءة الأداء وتقليل الوقت'),
                    _buildGoalItem('تحقيق الشفافية والدقة في التقارير'),
                    _buildGoalItem('دعم اتخاذ القرار بالمعلومات الدقيقة'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String goal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              goal,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: Color(0xFF222222), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.verified_rounded, color: Color(0xFF1DB954), size: 22),
        ],
      ),
    );
  }

  Widget _buildMiniFeature(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
