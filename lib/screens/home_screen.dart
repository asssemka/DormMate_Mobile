import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/useful_info_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _dorms = [];
  String? pdfUrl;

  @override
  void initState() {
    super.initState();
    _loadDorms();
  }

  Future<void> _loadDorms() async {
    try {
      final items = await DormService.getDorms();
      setState(() => _dorms = items);
    } catch (e) {
      debugPrint('Ошибка загрузки общежитий: $e');
    }
  }

  PreferredSizeWidget _buildHeader() => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFD50032), size: 28),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Меню',
          ),
        ),
        title: Text(
          'DormMate',
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFD50032),
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      );

  Drawer _buildDrawer(BuildContext ctx) => Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFFD50032)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.account_circle, color: Colors.white, size: 50),
                    const SizedBox(height: 12),
                    Text('Меню',
                        style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Color(0xFFD50032)),
                title: const Text('Главная'),
                onTap: () => Navigator.pushReplacementNamed(ctx, '/home'),
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD50032)),
                title: const Text('Чат'),
                onTap: () => Navigator.pushReplacementNamed(ctx, '/chat'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFD50032)),
                title: const Text('Выход'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await AuthService.logout();
                  Navigator.pushNamedAndRemoveUntil(ctx, '/login', (route) => false);
                },
              ),
            ],
          ),
        ),
      );

  BottomNavigationBar _buildBottomNavigationBar(BuildContext ctx) => BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFD50032),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (idx) {
          switch (idx) {
            case 0:
              Navigator.pushReplacementNamed(ctx, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(ctx, '/apply');
              break;
            case 2:
              Navigator.pushReplacementNamed(ctx, '/chat');
              break;
            case 3:
              Navigator.pushReplacementNamed(ctx, '/notification');
              break;
            case 4:
              Navigator.pushReplacementNamed(ctx, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: ''),
          BottomNavigationBarItem(
              icon: CircleAvatar(radius: 12, backgroundImage: AssetImage('assets/avatar.png')),
              label: ''),
        ],
      );

  Widget _buildDormCard(Map<String, dynamic> dorm, bool isEven) {
    final images = dorm['images'] as List<dynamic>?;
    final imageUrl = (images != null && images.isNotEmpty) ? images[0]['image'] as String : 'assets/banner.png';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      color: isEven ? Colors.grey[100] : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, '/dorm/${dorm['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, width: 90, height: 90, fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dorm['name'] as String,
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('₸${dorm['cost']}',
                        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(dorm['address'] as String? ?? '',
                        style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    // Удобства с иконками, добавляем здесь:
                    Row(
                      children: [
                        const Icon(FontAwesomeIcons.bed, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('${dorm['places'] ?? '—'} мест', style: GoogleFonts.montserrat(fontSize: 14)),
                        const SizedBox(width: 16),
                        const Icon(FontAwesomeIcons.utensils, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        const Text('Столовая', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 16),
                        const Icon(FontAwesomeIcons.tshirt, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        const Text('Прачечная', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqItems = [
      {
        'question': 'Что входит в стоимость проживания?',
        'answer': 'Проживание, коммунальные услуги, пользование кухней и душем.',
      },
      {
        'question': 'Как долго можно проживать в Доме студентов?',
        'answer': 'На протяжении всего периода обучения при соблюдении правил.',
      },
      {
        'question': 'Кто может получить место в общежитии?',
        'answer': 'Студенты, подавшие заявку и прошедшие отбор.',
      },
      {
        'question': 'Как происходит заселение?',
        'answer': 'Выдаётся ордер и заключается договор найма. Прописка оформляется через деканат. Самовольное заселение запрещено.',
      },
      {
        'question': 'Как я могу оплатить проживание?',
        'answer': 'Оплата производится через университетскую платёжную систему или банк.',
      },
      {
        'question': 'Какие правила проживания я должен соблюдать?',
        'answer': 'Соблюдение тишины, чистоты, уважение к соседям и имуществу.',
      },
      {
        'question': 'Что произойдёт при нарушении правил?',
        'answer': 'Предупреждение, штраф или выселение в зависимости от серьёзности.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Часто задаваемые вопросы',
              style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...faqItems.map((item) => ExpansionTile(
                title: Text(item['question']!, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    child: Text(item['answer']!, style: GoogleFonts.montserrat(fontSize: 14)),
                  ),
                ],
              )),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHeader(),
      drawer: _buildDrawer(context),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          const SizedBox(height: 16),
          SizedBox(height: 240, child: BannerCarousel()), // ещё увеличил высоту
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UsefulInfoPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD50032),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                textStyle: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              child: const Text('Полезное для студентов убрать'),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Наши общежития',
              style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ..._dorms.asMap().entries.map((entry) {
  final i = entry.key;
  final dorm = entry.value;
  return Padding(
    padding: const EdgeInsets.only(bottom: 20), // Отступ между карточками
    child: _buildDormCard(dorm, i % 2 == 0),
  );
}).toList(),

          const SizedBox(height: 24),
          _buildFAQSection(),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}
