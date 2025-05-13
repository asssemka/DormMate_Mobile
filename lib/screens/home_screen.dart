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
            icon: const Icon(Icons.menu, color: Colors.red, size: 28),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'DormMate',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.red,
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
                decoration: const BoxDecoration(color: Colors.red),
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
                leading: const Icon(Icons.home),
                title: const Text('Главная'),
                onTap: () => Navigator.pushReplacementNamed(ctx, '/home'),
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Чат'),
                onTap: () => Navigator.pushReplacementNamed(ctx, '/chat'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Выход'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacementNamed(ctx, '/login');
                },
              ),
            ],
          ),
        ),
      );

  BottomNavigationBar _buildBottomNavigationBar(BuildContext ctx) =>
      BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
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
              Navigator.pushReplacementNamed(ctx, '/notifications');
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
              icon: CircleAvatar(
                  radius: 12, backgroundImage: AssetImage('assets/avatar.png')),
              label: ''),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHeader(),
      drawer: _buildDrawer(context),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 200, child: BannerCarousel()),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UsefulInfoPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: GoogleFonts.montserrat(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('Полезное для студентов'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _dorms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final dorm = _dorms[i];
                final isEven = i % 2 == 0;
                final images = dorm['images'] as List<dynamic>?;
                final imageUrl = (images != null && images.isNotEmpty)
                    ? images[0]['image'] as String
                    : 'assets/banner.png';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  color: isEven ? Colors.grey[100] : Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pushNamed(context, '/dorm/${dorm['id']}'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dorm['name'] as String,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('₸${dorm['cost']}',
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 2),
                                Text(dorm['address'] as String? ?? '',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey),
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
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}
