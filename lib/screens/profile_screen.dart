import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../widgets/bottom_navigation_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../gen_l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final void Function(Locale)? onLanguageChanged;

  const ProfileScreen({
    Key? key,
    required this.onToggleTheme,
    required this.themeMode,
    this.onLanguageChanged,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  String status = '';
  String statusError = '';
  String uploadMessage = '';
  String passwordMessage = '';
  bool isLoading = true;
  bool isEditEnabled = false;
  bool showUploadButton = false;
  final ImagePicker _picker = ImagePicker();
  XFile? paymentScreenshot;
  XFile? avatarImage;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String statusText = '';
  String paymentUrl = '';
  String testUrl = '';
  String dormitoryName = '';
  String roomNumber = '';
  bool _notifSound = true;

  Future<void> _loadNotifPref() async {
    final pref = await SharedPreferences.getInstance();
    setState(() => _notifSound = pref.getBool('notif_sound') ?? true);
  }

  Future<void> _toggleNotifSound(bool value) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool('notif_sound', value);
    setState(() => _notifSound = value);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchApplicationStatus();
    fetchGlobalSettings();
    _loadNotifPref();
  }

  Future<void> fetchProfile() async {
    try {
      final data = await AuthService.getStudentData();
      setState(() {
        profile = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => statusError = 'Ошибка загрузки профиля');
    }
  }

  Future<void> fetchApplicationStatus() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception("Токен не найден");
      }

      final response = await http.get(
        Uri.parse('https://dormmate-back.onrender.com/api/v1/application_status/'),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            status = data['status'] ?? '';
            statusText = data['status_text'] ?? '';
            paymentUrl = data['payment_url'] ?? '';
            testUrl = data['test_url'] ?? '';
            if (status == 'order') {
              final orderDetails = data['order_details'] ?? {};
              dormitoryName = orderDetails['dormitory'] ?? 'Неизвестно';
              roomNumber = orderDetails['room'] ?? 'Неизвестно';
            }
          });
        }
      } else {
        throw Exception("Ошибка при загрузке статуса заявки: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          status = 'unknown';
          statusText = 'Неизвестная ошибка';
        });
      }
    }
  }

  void _showLanguageDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF212128) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Выберите язык',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLangOption('Русский', const Locale('ru'), textColor),
            const SizedBox(height: 8),
            _buildLangOption('Қазақша', const Locale('kk'), textColor),
            const SizedBox(height: 8),
            _buildLangOption('English', const Locale('en'), textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption(String label, Locale locale, Color textColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF312D65),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16),
          elevation: 0,
        ),
        onPressed: () {
          widget.onLanguageChanged?.call(locale);
          Navigator.of(context).pop();
        },
        child: Text(label),
      ),
    );
  }

  Future<void> fetchGlobalSettings() async {
    try {
      final client = RefreshHttpClient();
      final response =
          await client.get(Uri.parse("https://dormmate-back.onrender.com/api/v1/global-settings/"));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() => isEditEnabled = data['allow_application_edit'] ?? false);
    } catch (e) {}
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        paymentScreenshot = XFile(result.files.first.path!);
        showUploadButton = true;
      });
    }
  }

  Future<void> uploadScreenshot() async {
    if (paymentScreenshot == null) return;
    try {
      if (kIsWeb) {
        Uint8List bytes = await paymentScreenshot!.readAsBytes();
        String filename =
            paymentScreenshot!.name.endsWith('.pdf') ? paymentScreenshot!.name : 'file.pdf';
        await ApplicationService.uploadPaymentScreenshotWeb(bytes, filename);
      } else {
        await ApplicationService.uploadPaymentScreenshot(File(paymentScreenshot!.path));
      }
      if (mounted) {
        setState(() {
          uploadMessage = 'Файл успешно загружен.';
          showUploadButton = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          uploadMessage = 'Ошибка загрузки файла: $e';
        });
      }
    }
  }

  Future<void> changeAvatarFromSource(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() => avatarImage = picked);
      await uploadAvatar(picked);
    }
  }

  Future<void> deleteAvatar() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) throw Exception("Токен не найден");
      if (profile?['avatar'] == null || profile?['avatar'] == "")
        throw Exception("Аватар уже не установлен или отсутствует");
      final response = await http.delete(
        Uri.parse("https://dormmate-back.onrender.com/api/v1/upload-avatar/"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        await fetchProfile();
        setState(() => profile?['avatar'] = null);
      } else {
        throw Exception("Ошибка при удалении аватара: ${response.body}");
      }
    } catch (e) {
      setState(() => statusError = 'Ошибка при удалении аватара: $e');
    }
  }

  Future<void> uploadAvatar(XFile pickedFile) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null || token.isEmpty) throw Exception("Токен не найден");
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("https://dormmate-back.onrender.com/api/v1/upload-avatar/"),
      )..headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('avatar', bytes, filename: 'avatar.png'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('avatar', pickedFile.path));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        await fetchProfile();
        setState(() {});
      } else {
        throw Exception("Ошибка загрузки аватара: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => statusError = 'Ошибка при загрузке аватара: $e');
    }
  }

  void showAvatarOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF232338) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: () {
                Navigator.pop(context);
                changeAvatarFromSource(ImageSource.gallery);
              },
              leading:
                  Icon(Icons.image, color: isDark ? Colors.white70 : Color(0xFF3e466c), size: 28),
              title: Text(
                "Выбрать из галереи",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  color: isDark ? Colors.white : Color(0xFF3e466c),
                  fontWeight: FontWeight.w600,
                ),
              ),
              minLeadingWidth: 0,
              horizontalTitleGap: 12,
            ),
            SizedBox(height: 8),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                deleteAvatar();
              },
              leading: Icon(Icons.delete, color: Color(0xFFD50032), size: 28),
              title: Text(
                "Удалить аватар",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  color: Color(0xFFD50032),
                  fontWeight: FontWeight.w600,
                ),
              ),
              minLeadingWidth: 0,
              horizontalTitleGap: 12,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> changePassword() async {
    setState(() => passwordMessage = '');
    final old = _oldPasswordController.text.trim();
    final newP = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    if (old.isEmpty || newP.isEmpty || confirm.isEmpty) {
      setState(() => passwordMessage = 'Пожалуйста, заполните все поля.');
      return;
    }
    if (newP != confirm) {
      setState(() => passwordMessage = 'Новый пароль и подтверждение не совпадают.');
      return;
    }
    try {
      final client = RefreshHttpClient();
      final response = await client.post(
        Uri.parse("https://dormmate-back.onrender.com/api/v1/change_password/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"old_password": old, "new_password": newP, "confirm_password": confirm}),
      );
      if (response.statusCode == 200) {
        setState(() => passwordMessage = 'Пароль успешно изменен.');
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        Navigator.of(context).pop();
      } else {
        final body = jsonDecode(response.body);
        setState(() => passwordMessage = body['error'] ?? 'Ошибка при смене пароля.');
      }
    } catch (e) {
      setState(() => passwordMessage = 'Ошибка при изменении пароля.');
    }
  }

  void showPasswordChangeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF232338) : Colors.white;
    final mainText = isDark ? Colors.white : Color(0xFF3e466c);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Сменить пароль',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: mainText,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoundedField(
                controller: _oldPasswordController, label: 'Старый пароль', isDark: isDark),
            SizedBox(height: 12),
            _buildRoundedField(
                controller: _newPasswordController, label: 'Новый пароль', isDark: isDark),
            SizedBox(height: 12),
            _buildRoundedField(
                controller: _confirmPasswordController,
                label: 'Подтвердите новый пароль',
                isDark: isDark),
            if (passwordMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(passwordMessage, style: GoogleFonts.montserrat(color: Colors.red)),
              ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: mainText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Отмена', style: GoogleFonts.montserrat()),
                ),
                ElevatedButton(
                  onPressed: changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD50032),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Сменить', style: GoogleFonts.montserrat(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundedField({
    required TextEditingController controller,
    required String label,
    bool isDark = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: isDark ? Colors.white : Color(0xFF3e466c)),
        filled: true,
        fillColor: isDark ? Color(0xFF232338) : Colors.grey[100],
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      style: GoogleFonts.montserrat(color: isDark ? Colors.white : Color(0xFF3e466c)),
    );
  }

  // Мультиязычный статус ордера
  String getOrderStatusText(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (locale) {
      case 'kk':
        return 'Ордер берілді';
      case 'en':
        return 'Order received';
      default:
        return 'Ордер получен';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainBg = isDark ? const Color(0xFF181825) : const Color(0xfff6f7fa);
    final Color blockBg = isDark ? const Color(0xFF232338) : Colors.white;
    final Color borderBlock = isDark ? Color(0xFF25253a) : Color(0xFFeeeeee);
    final Color mainText = isDark ? Colors.white : Color(0xFF1e2134);
    final Color subtitle = isDark ? Colors.grey[300]! : Colors.grey[600]!;
    final Color approvedBg = isDark ? const Color(0xff273C3B) : const Color(0xffeaf4e9);
    final Color approvedText = isDark ? const Color(0xff82FF9E) : const Color(0xff265c37);
    final Color warningBg = isDark ? Color(0xFF484251) : Colors.blue.shade100;

    final avatarUrl = profile?['avatar']?.toString() ?? '';
    final userId = profile?['id']?.toString() ?? '';
    String cleanedUrl = avatarUrl.startsWith('http')
        ? avatarUrl
        : 'https://dormmateblobstorage.blob.core.windows.net/media/avatars/user_$userId/${avatarUrl.split('/').last}';
    final avatarWithTimestamp = '$cleanedUrl?ts=${DateTime.now().millisecondsSinceEpoch}';

    ImageProvider avatarImageProvider;
    if (avatarImage != null) {
      avatarImageProvider = FileImage(File(avatarImage!.path));
    } else if (profile?['avatar'] != null) {
      avatarImageProvider = NetworkImage(avatarWithTimestamp);
    } else {
      avatarImageProvider = AssetImage('assets/avatar.png');
    }

    final double topBlockHeight = MediaQuery.of(context).size.height * 0.32;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: mainBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Блок-баннер с аватаром
              Stack(
                children: [
                  Container(
                    height: topBlockHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              colors: [Color(0xFF232338), Color(0xFF181825)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [Color(0xFFF5F7FF), Color(0xFFEFF2FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      image: DecorationImage(
                        image: AssetImage('assets/back.png'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          isDark ? Colors.black.withOpacity(0.32) : Colors.white.withOpacity(0.22),
                          BlendMode.srcOver,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(0, 0.8),
                      child: Column(
                        children: [
                          // Аватар с редактированием
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 58,
                                  backgroundColor: borderBlock,
                                  child: CircleAvatar(
                                    radius: 54,
                                    backgroundImage: avatarImageProvider,
                                    backgroundColor: Colors.grey.shade200,
                                  ),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: 4,
                                  child: GestureDetector(
                                    onTap: showAvatarOptions,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? Color(0xFF25253a) : Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 6,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(7),
                                      child: Icon(Icons.edit, color: subtitle, size: 23),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '${profile?['first_name'] ?? ""} ${profile?['last_name'] ?? ""}',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: mainText,
                              letterSpacing: 0.1,
                            ),
                          ),
                          if (profile?['email'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              profile?['email'] ?? '',
                              style: GoogleFonts.montserrat(color: subtitle, fontSize: 15),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Карточка профиля и настроек
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: blockBg,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDark ? Colors.black.withOpacity(0.09) : Colors.grey.withOpacity(0.09),
                        blurRadius: 15,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.badge_outlined, color: subtitle),
                        title: Text(t.student_id,
                            style: GoogleFonts.montserrat(fontSize: 16, color: mainText)),
                        trailing: Text(
                          profile?['s'] ?? "-",
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold, fontSize: 15, color: mainText),
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: borderBlock),
                      ListTile(
                        leading: Icon(Icons.phone_iphone, color: subtitle),
                        title: Text(
                          t.phone_number,
                          style: GoogleFonts.montserrat(fontSize: 16, color: mainText),
                        ),
                        trailing: Text(
                          profile?['phone_number'] ?? "-",
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold, fontSize: 15, color: mainText),
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: borderBlock),
                      SwitchListTile(
                        value: _notifSound,
                        onChanged: _toggleNotifSound,
                        activeColor: Color(0xFFD50032),
                        title: Text('Уведомления со звуком',
                            style: GoogleFonts.montserrat(fontSize: 16, color: mainText)),
                        secondary: Icon(
                          _notifSound ? Icons.notifications_active : Icons.notifications_off,
                          color: subtitle,
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: borderBlock),
                      ListTile(
                        leading: Icon(Icons.lock_outline, color: subtitle),
                        title: Text(
                          t.change_password,
                          style: GoogleFonts.montserrat(fontSize: 16, color: mainText),
                        ),
                        trailing: Icon(Icons.chevron_right, color: subtitle),
                        onTap: showPasswordChangeDialog,
                      ),
                      Divider(height: 1, thickness: 1, color: borderBlock),
                      ListTile(
                        leading: Icon(Icons.language, color: subtitle),
                        title: Text(t.language,
                            style: GoogleFonts.montserrat(fontSize: 16, color: mainText)),
                        trailing: Icon(Icons.chevron_right, color: subtitle),
                        onTap: _showLanguageDialog,
                      ),
                      Divider(height: 1, thickness: 1, color: borderBlock),
                      ListTile(
                        leading: Icon(Icons.nightlight_round, color: subtitle),
                        title: Text(
                          isDark ? 'Светлая тема' : 'Тёмная тема',
                          style: GoogleFonts.montserrat(fontSize: 16, color: mainText),
                        ),
                        trailing: Icon(Icons.brightness_6_outlined, color: subtitle),
                        onTap: widget.onToggleTheme,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              // Блок статуса заявки
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: blockBg,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDark ? Colors.black.withOpacity(0.05) : Colors.grey.withOpacity(0.07),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Статус заявки',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: mainText,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (status == 'approved' || status == 'awaiting_payment') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: approvedBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: GoogleFonts.montserrat(
                                color: approvedText,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: Icon(Icons.attach_file_rounded, size: 23),
                            label: Text(
                              'Прикрепить скрин оплаты',
                              style:
                                  GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            onPressed: pickFile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4982d7),
                              foregroundColor: Colors.white,
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ],
                        if (status == 'awaiting_order') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: warningBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Ожидайте ордера!',
                              style: GoogleFonts.montserrat(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                        if (status == 'order') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFFF5DA96),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.verified, color: Color(0xFFCC9300), size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      getOrderStatusText(context),
                                      style: GoogleFonts.montserrat(
                                        color: Color(0xFF684D04),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Общежитие: $dormitoryName\nКомната: $roomNumber',
                                  style: GoogleFonts.montserrat(
                                    color: Color(0xFF684D04),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (status == 'rejected') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFFFDE5E6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Color(0xFFD50032), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  statusText.isNotEmpty ? statusText : 'Заявка отклонена',
                                  style: GoogleFonts.montserrat(
                                    color: Color(0xFFD50032),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (status == 'pending' || status == '') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFFDCE3F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Color(0xFF4982d7), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  statusText.isNotEmpty ? statusText : 'На рассмотрении',
                                  style: GoogleFonts.montserrat(
                                    color: Color(0xFF1857AD),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (showUploadButton) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: Icon(Icons.upload_file, size: 22),
                            label: Text(
                              'Загрузить файл',
                              style:
                                  GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            onPressed: uploadScreenshot,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff34ba5c),
                              foregroundColor: Colors.white,
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ],
                        if (uploadMessage.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            uploadMessage,
                            style: GoogleFonts.montserrat(
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Кнопка выхода
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52.0),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.logout, size: 24),
                  label: Text(
                    'Выйти из аккаунта',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Color(0xFF27273C) : Colors.red.shade50,
                    foregroundColor: isDark ? Colors.red.shade200 : Colors.red,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _logout,
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }
}
