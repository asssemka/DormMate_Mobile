import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../gen_l10n/app_localizations.dart';
import 'dart:html' as html;

class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const HomePage({
    Key? key,
    required this.onToggleTheme,
    required this.themeMode,
  }) : super(key: key);

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

  PreferredSizeWidget _buildHeader(BuildContext context) => AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFD50032), size: 28),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: AppLocalizations.of(context)!.menu,
          ),
        ),
        title: Text(
          'DormMate',
          style: GoogleFonts.montserrat(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD50032),
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      );

  String getDormName(Map<String, dynamic> dorm, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'kk') {
      return dorm['name_kk'] as String? ??
          dorm['name_ru'] as String? ??
          dorm['name_en'] as String? ??
          '';
    } else if (locale == 'en') {
      return dorm['name_en'] as String? ??
          dorm['name_ru'] as String? ??
          dorm['name_kk'] as String? ??
          '';
    } else {
      return dorm['name_ru'] as String? ??
          dorm['name_kk'] as String? ??
          dorm['name_en'] as String? ??
          '';
    }
  }

  void _showUsefulInfoModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF232338) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1e2134);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.36),
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.87,
          ),
          child: Material(
            color: cardBg,
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates_rounded, color: Color(0xFFD50032), size: 27),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.useful_info_students,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red.shade300, size: 27),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Закрыть',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "🏠 Как получить место?\n",
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: textColor,
                                  ),
                                ),
                                TextSpan(
                                  text: "1. Заполните заявку, приложите документы.\n"
                                      "2. Дождитесь статуса 'Одобрено' — появится доступ к ордеру.\n\n",
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                    color: textColor,
                                    height: 1.55,
                                  ),
                                ),
                                TextSpan(
                                  text: "💬 Вопросы? \n",
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: textColor,
                                  ),
                                ),
                                TextSpan(
                                  text: "Пишите в чат поддержки DormMate, мы быстро поможем!\n\n",
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                    color: textColor,
                                    height: 1.5,
                                  ),
                                ),
                                TextSpan(
                                  text: "⚡ Советы:\n",
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: textColor,
                                  ),
                                ),
                                TextSpan(
                                  text: "• Не забывайте оплачивать проживание вовремя.\n"
                                      "• Соблюдайте правила (они есть прямо в приложении!).\n"
                                      "• Любые вопросы — не стесняйтесь, мы всегда на связи ❤️",
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                    color: textColor,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext ctx) {
    final t = AppLocalizations.of(ctx)!;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFD50032).withOpacity(0.85) : const Color(0xFFFFDEE2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_circle, color: Colors.white, size: 54),
                  const SizedBox(height: 12),
                  Text(
                    t.menu,
                    style: GoogleFonts.montserrat(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFFD50032)),
              title: Text(
                t.home,
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pushReplacementNamed(ctx, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD50032)),
              title: Text(
                t.chat,
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pushReplacementNamed(ctx, '/chat'),
            ),
            ListTile(
              leading: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: Color(0xFFD50032),
              ),
              title: Text(
                isDark ? "Светлая тема" : "Тёмная тема",
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: widget.onToggleTheme,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color.fromARGB(255, 0, 0, 0)),
              title: Text(
                t.logout,
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await AuthService.logout();
                Navigator.pushNamedAndRemoveUntil(ctx, '/login', (route) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFD50032)),
              title: Text(
                t.useful_info_students,
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showUsefulInfoModal(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD50032)),
              title: Text(
                t.chat,
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                final token = html.window.localStorage['flutter.access_token'];
                print('TOKEN BEFORE CHAT: $token');
                Navigator.pushNamed(context, '/dorm_chats');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDormCard(Map<String, dynamic> dorm, bool isEven, BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final images = dorm['images'] as List<dynamic>?;
    final imageUrl =
        (images != null && images.isNotEmpty) ? images[0]['image'] as String : 'assets/banner.png';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Используем цвета из профиля
    final cardBg = isDark ? Color(0xFF232338) : Colors.white;
    final borderBlock = isDark ? Color(0xFF25253a) : Color(0xFFeeeeee);
    final textColor = isDark ? Colors.white : Color(0xFF1e2134);
    final subtitleColor = isDark ? Colors.grey[300] : Colors.grey[600];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: isDark ? 4 : 7,
      shadowColor: isDark ? Colors.black54 : Colors.grey[200],
      color: cardBg,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, '/dorm/${dorm['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.network(
                  imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey[200], width: 90, height: 90),
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getDormName(dorm, context),
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text('₸${dorm['cost']} / мес',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFD50032),
                        )),
                    const SizedBox(height: 7),
                    Text(dorm['address'] as String? ?? '',
                        style: GoogleFonts.montserrat(fontSize: 14, color: subtitleColor)),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 18,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.bed, size: 16, color: subtitleColor),
                            SizedBox(width: 6),
                            Text(
                              '${dorm['places'] ?? '—'} ${t.total_places}',
                              style: GoogleFonts.montserrat(fontSize: 14, color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.utensils, size: 16, color: subtitleColor),
                            SizedBox(width: 6),
                            Text(
                              t.dorm_canteen,
                              style: GoogleFonts.montserrat(fontSize: 14, color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.tshirt, size: 16, color: subtitleColor),
                            SizedBox(width: 6),
                            Text(
                              t.dorm_laundry,
                              style: GoogleFonts.montserrat(fontSize: 14, color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: subtitleColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Color(0xFF1e2134);
    final bodyColor = isDark ? Colors.grey[300] : Colors.black54;

    final faqItems = [
      {'question': t.faq_q1, 'answer': t.faq_a1},
      {'question': t.faq_q2, 'answer': t.faq_a2},
      {
        'question': t.faq_q3 ?? 'Кто может получить место в общежитии?',
        'answer': t.faq_a3 ?? 'Студенты, подавшие заявку и прошедшие отбор.',
      },
      {
        'question': t.faq_q4 ?? 'Как происходит заселение?',
        'answer': t.faq_a4 ??
            'Выдаётся ордер и заключается договор найма. Прописка оформляется через деканат. Самовольное заселение запрещено.',
      },
      {
        'question': t.faq_q5 ?? 'Как я могу оплатить проживание?',
        'answer':
            t.faq_a5 ?? 'Оплата производится через университетскую платёжную систему или банк.',
      },
      {
        'question': t.faq_q6 ?? 'Какие правила проживания я должен соблюдать?',
        'answer': t.faq_a6 ?? 'Соблюдайте тишину, чистоту, уважайте соседей и имущество общежития.',
      },
      {
        'question': t.faq_q7 ?? 'Что произойдёт при нарушении правил?',
        'answer': t.faq_a7 ??
            'Сначала предупреждение, далее — штраф или даже выселение, если нарушение серьёзное.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.faq,
            style: GoogleFonts.montserrat(
                fontSize: 22, fontWeight: FontWeight.bold, color: titleColor),
          ),
          const SizedBox(height: 12),
          ...faqItems.map((item) => Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  collapsedIconColor: titleColor,
                  iconColor: titleColor,
                  backgroundColor: Colors.transparent,
                  childrenPadding: EdgeInsets.zero,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 6),
                  title: Text(item['question']!,
                      style:
                          GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: titleColor)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 12),
                      child: Text(item['answer']!,
                          style: GoogleFonts.montserrat(fontSize: 15, color: bodyColor)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Основные цвета — ровно как в профиле:
    final Color mainBg = isDark ? const Color(0xFF181825) : const Color(0xfff6f7fa);

    return Scaffold(
      appBar: _buildHeader(context),
      drawer: _buildDrawer(context),
      backgroundColor: mainBg,
      body: ListView(
        children: [
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final bannerHeight = screenWidth * 9 / 16;
              return SizedBox(
                height: bannerHeight,
                child: const BannerCarousel(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () => _showUsefulInfoModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD50032),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
                textStyle: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700),
                elevation: 4,
                shadowColor: isDark ? Colors.black45 : Colors.grey.shade200,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tips_and_updates_rounded, size: 23, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(t.useful_info_students),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              t.our_dormitories,
              style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Color(0xFF1e2134),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._dorms.asMap().entries.map((entry) {
            final i = entry.key;
            final dorm = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: _buildDormCard(dorm, i % 2 == 0, context),
            );
          }).toList(),
          const SizedBox(height: 24),
          _buildFAQSection(context),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
