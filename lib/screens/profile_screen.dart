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
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';

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

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchApplicationStatus();
    fetchGlobalSettings();
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

  void _showLanguageDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF232323) : Colors.white;
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
          backgroundColor: const Color(0xFFD50032),
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

  Future<void> fetchApplicationStatus() async {
    try {
      final client = RefreshHttpClient();
      final response = await client.get(
        Uri.parse("http://127.0.0.1:8000/api/v1/application_status/"),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() => status = data['status'] ?? '');
    } catch (e) {
      setState(() => status = '');
    }
  }

  Future<void> fetchGlobalSettings() async {
    try {
      final client = RefreshHttpClient();
      final response = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/global-settings/"));
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
        await ApplicationService.uploadPaymentScreenshotWeb(bytes, filename); // Web
      } else {
        await ApplicationService.uploadPaymentScreenshot(File(paymentScreenshot!.path)); // Mobile
      }
      setState(() {
        uploadMessage = 'Файл успешно загружен.';
        showUploadButton = false;
      });
    } catch (e) {
      setState(() {
        uploadMessage = 'Ошибка загрузки файла.';
      });
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
    final token = await AuthService.getAccessToken();
    final response = await http.delete(
      Uri.parse("http://127.0.0.1:8000/api/v1/upload-avatar/"),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      await fetchProfile();
      setState(() => avatarImage = null);
    }
  }

  Future<void> uploadAvatar(XFile pickedFile) async {
    final token = await AuthService.getAccessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse("http://127.0.0.1:8000/api/v1/upload-avatar/"),
    )..headers['Authorization'] = 'Bearer $token';

    if (kIsWeb) {
      Uint8List bytes = await pickedFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('avatar', bytes, filename: 'avatar.png'));
    } else {
      request.files.add(await http.MultipartFile.fromPath('avatar', pickedFile.path));
    }

    await request.send();
    await fetchProfile();
    setState(() {});
  }

  Widget _buildRow(String title, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(value, style: GoogleFonts.montserrat(fontSize: 16)),
          ],
        ),
      );

  void showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      backgroundColor: Colors.white,
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
              leading: Icon(Icons.image, color: Color.fromARGB(255, 63, 63, 65), size: 28),
              title: Text(
                "Выбрать из галереи",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  color: Color.fromARGB(255, 63, 63, 65),
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
              leading: Icon(Icons.delete, color: Color.fromARGB(255, 209, 56, 56), size: 28),
              title: Text(
                "Удалить аватар",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  color: Color.fromARGB(255, 209, 56, 56),
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
        Uri.parse("http://127.0.0.1:8000/api/v1/change_password/"),
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
    final bgColor = isDark ? const Color(0xFF232323) : Colors.white;
    final mainText = isDark ? Colors.white : const Color.fromARGB(255, 87, 85, 85);

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
              isDark: isDark,
            ),
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
                    backgroundColor: Colors.red,
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
        labelStyle: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black),
        filled: true,
        fillColor: isDark ? const Color(0xFF181818) : Colors.grey[100],
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainBg = isDark ? const Color(0xFF181818) : const Color(0xfff5f5f5);
    final Color blockBg = Theme.of(context).cardColor;
    final Color mainText = isDark ? Colors.white : Colors.black87;
    final Color subtitle = isDark ? Colors.grey[300]! : Colors.grey[600]!;
    final Color approvedBg = isDark ? const Color(0xff223A24) : const Color(0xffeaf4e9);
    final Color approvedText = isDark ? const Color(0xff73fc7e) : const Color(0xff265c37);
    final Color noAppBg = isDark ? const Color(0xFF252525) : const Color(0xfff5f5f7);

    final avatarUrl = profile?['avatar']?.toString() ?? '';
    final cleanedUrl = avatarUrl.startsWith('http')
        ? avatarUrl
        : 'http://127.0.0.1:8000${avatarUrl.startsWith('/') ? avatarUrl : '/$avatarUrl'}';
    final avatarWithTimestamp = '$cleanedUrl?ts=${DateTime.now().millisecondsSinceEpoch}';

    ImageProvider avatarImageProvider;
    if (avatarImage != null) {
      avatarImageProvider = FileImage(File(avatarImage!.path));
    } else if (profile?['avatar'] != null) {
      avatarImageProvider = NetworkImage(avatarWithTimestamp);
    } else {
      avatarImageProvider = AssetImage('assets/avatar.png');
    }

    final double topBlockHeight = MediaQuery.of(context).size.height * 0.34;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: mainBg,
      body: Stack(
        children: [
          // Top background
          Container(
            height: topBlockHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/back.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: topBlockHeight * 0.4),
                  // Avatar
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: blockBg,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: avatarImageProvider,
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 4,
                          child: GestureDetector(
                            onTap: showAvatarOptions,
                            child: Container(
                              decoration: BoxDecoration(
                                color: blockBg,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.edit, color: subtitle, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${profile?['first_name'] ?? ""} ${profile?['last_name'] ?? ""}',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                      color: mainText,
                    ),
                  ),
                  if (profile?['email'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      profile?['email'] ?? '',
                      style: GoogleFonts.montserrat(color: subtitle, fontSize: 15),
                    ),
                  ],
                  const SizedBox(height: 28),
                  // Карточка профиля
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: blockBg,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
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
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: mainText,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Icon(Icons.badge_outlined, color: subtitle),
                            title: Text(
                              t.phone_number,
                              style: GoogleFonts.montserrat(fontSize: 16, color: mainText),
                            ),
                            trailing: Text(
                              profile?['phone_number'] ?? "-",
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: mainText,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Icon(Icons.lock_outline, color: subtitle),
                            title: Text(
                              t.change_password,
                              style: GoogleFonts.montserrat(fontSize: 16, color: mainText),
                            ),
                            trailing: Icon(Icons.chevron_right, color: subtitle),
                            onTap: showPasswordChangeDialog,
                          ),
                          ListTile(
                            leading: Icon(Icons.language, color: subtitle),
                            title: Text(t.language,
                                style: GoogleFonts.montserrat(fontSize: 16, color: mainText)),
                            trailing: Icon(Icons.chevron_right, color: subtitle),
                            onTap: _showLanguageDialog,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  // Блок статуса заявки
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: blockBg,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.application_status,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: mainText,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (status.isEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: noAppBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  t.status_no_application,
                                  style: GoogleFonts.montserrat(
                                    color: subtitle,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/apply'),
                                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                                label: Text(
                                  t.go_to_application,
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD50032),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  elevation: 2,
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: approvedBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  t.application_approved,
                                  style: GoogleFonts.montserrat(
                                    color: approvedText,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: pickFile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff6ec177),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(44),
                                ),
                                child: Text(
                                  t.attach_payment_screenshot,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (showUploadButton) ...[
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: uploadScreenshot,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffe4e5f8),
                                    foregroundColor: const Color(0xff2c2d6b),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    minimumSize: const Size.fromHeight(44),
                                  ),
                                  child: Text(
                                    t.send,
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                              if (uploadMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    uploadMessage,
                                    style: const TextStyle(color: Color(0xff42be54)),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: isEditEnabled
                                    ? () => Navigator.pushNamed(context, '/edit-application')
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isEditEnabled
                                      ? const Color(0xff595fa2)
                                      : Colors.grey.shade700.withOpacity(0.3),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(44),
                                ),
                                child: Text(
                                  t.edit_application,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 38),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
