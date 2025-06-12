import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/api.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../gen_l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onOpenChat;
  const NotificationsScreen({Key? key, this.onOpenChat}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Map<String, dynamic>> notifications = [];
  Timer? timer;
  String? error;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications(init: true);
    timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchNotifications());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications({bool init = false}) async {
    try {
      final result = await NotificationsService.getNotifications();
      if (mounted) {
        setState(() {
          error = null;
          isLoading = false;
        });
        // Для анимации появления новых уведомлений
        if (init) {
          notifications = List.from(result);
        } else {
          final newList = List<Map<String, dynamic>>.from(result);
          // Добавление новых элементов
          for (var i = 0; i < newList.length; i++) {
            if (notifications.length <= i || notifications[i]['id'] != newList[i]['id']) {
              notifications.insert(i, newList[i]);
              _listKey.currentState?.insertItem(i, duration: Duration(milliseconds: 300));
            }
          }
          // Удаление исчезнувших
          for (var i = notifications.length - 1; i >= 0; i--) {
            if (newList.where((n) => n['id'] == notifications[i]['id']).isEmpty) {
              final removed = notifications.removeAt(i);
              _listKey.currentState?.removeItem(
                i,
                (context, animation) => _buildAnimatedNotifCard(
                  context,
                  removed,
                  animation,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
                duration: Duration(milliseconds: 250),
              );
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        error = 'Ошибка при загрузке уведомлений: $e';
        isLoading = false;
      });
    }
  }

  String getNotificationText(Map<String, dynamic> notification, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'kk') {
      return notification['message_kk'] as String? ??
          notification['message_ru'] as String? ??
          notification['message_en'] as String? ??
          '';
    } else if (locale == 'en') {
      return notification['message_en'] as String? ??
          notification['message_ru'] as String? ??
          notification['message_kk'] as String? ??
          '';
    } else {
      return notification['message_ru'] as String? ??
          notification['message_kk'] as String? ??
          notification['message_en'] as String? ??
          '';
    }
  }

  String _formatTime(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    return DateFormat('dd.MM.yyyy • HH:mm').format(date);
  }

  Future<void> _markAsRead(int id) async {
    try {
      await NotificationsService.markAsRead([id]);
      final idx = notifications.indexWhere((n) => n['id'] == id);
      if (idx >= 0) {
        final removed = notifications.removeAt(idx);
        _listKey.currentState?.removeItem(
          idx,
          (context, animation) => _buildAnimatedNotifCard(
            context,
            removed,
            animation,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          duration: Duration(milliseconds: 300),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при отметке уведомления: $e')),
      );
    }
  }

  void _openChat(int id) {
    if (widget.onOpenChat != null) widget.onOpenChat!();
    _markAsRead(id);
  }

  Widget _buildAnimatedNotifCard(
      BuildContext context, Map<String, dynamic> n, Animation<double> animation,
      {required bool isDark}) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final card = theme.cardColor;
    final textMain = isDark ? Colors.white : Colors.black87;
    final textSub = isDark ? Colors.grey[400]! : Colors.grey.shade600;
    final divider = isDark ? Colors.grey[800]! : Colors.grey.shade300;
    return SizeTransition(
      sizeFactor: animation,
      axis: Axis.vertical,
      child: FadeTransition(
        opacity: animation,
        child: Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: divider.withOpacity(0.18),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          margin: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Красная точка если не прочитано (пример анимации статуса)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD50032).withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications, color: Color(0xFFD50032), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getNotificationText(n, context),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(n['created_at'] ?? ''),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: textSub,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  TextButton(
                    onPressed: () => _openChat(n['id']),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFFD50032),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      t.chat,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _markAsRead(n['id']),
                    style: TextButton.styleFrom(
                      foregroundColor: textSub,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      t.markAsRead,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final card = theme.cardColor;
    final textMain = isDark ? Colors.white : Colors.black87;
    final textSub = isDark ? Colors.grey[400]! : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 0,
        title: Text(
          t.notifications,
          style: GoogleFonts.montserrat(
            color: textMain,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textMain),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
          splashRadius: 22,
          tooltip: t.back,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFFD50032)))
            : error != null
                ? Center(
                    child: Text(
                      error!,
                      style: GoogleFonts.montserrat(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : notifications.isEmpty
                    ? Center(
                        child: Text(
                          t.noNotifications,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: textSub,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : AnimatedList(
                        key: _listKey,
                        physics: const BouncingScrollPhysics(),
                        initialItemCount: notifications.length,
                        itemBuilder: (context, index, animation) => _buildAnimatedNotifCard(
                          context,
                          notifications[index],
                          animation,
                          isDark: isDark,
                        ),
                      ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}
