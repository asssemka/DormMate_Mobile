import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
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
      setState(() {
        statusError = 'Ошибка загрузки профиля';
        isLoading = false;
      });
    }
  }

  Future<void> fetchApplicationStatus() async {
    try {
      final client = RefreshHttpClient();
      final response = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/application_status/"));

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decoded);
        setState(() {
          status = data['status'] ?? '';
        });
      } else {
        setState(() {
          status = '';
        });
      }
    } catch (e) {
      setState(() {
        status = '';
      });
    }
  }

  Future<void> fetchGlobalSettings() async {
    try {
      final client = RefreshHttpClient();
      final response = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/global-settings/"));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() => isEditEnabled = decoded['allow_application_edit'] ?? false);
      }
    } catch (e) {
      debugPrint("Ошибка получения настроек: $e");
    }
  }

  Future<void> pickFile() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => paymentScreenshot = file);
  }

  Future<void> pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => avatarImage = picked);
      await uploadAvatar(File(picked.path));
      await fetchProfile();
    }
  }

  Future<void> uploadAvatar(File file) async {
    try {
      final client = RefreshHttpClient();
      final token = await AuthService.getAccessToken();
      final request = http.MultipartRequest('POST', Uri.parse("http://127.0.0.1:8000/api/v1/upload-avatar/"));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('avatar', file.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        await fetchProfile();
      }
    } catch (e) {
      debugPrint("Ошибка загрузки аватара: $e");
    }
  }

  Future<void> uploadScreenshot() async {
    if (paymentScreenshot == null) {
      setState(() => uploadMessage = 'Пожалуйста, выберите файл.');
      return;
    }

    try {
      await ApplicationService.uploadPaymentScreenshot(File(paymentScreenshot!.path));
      setState(() => uploadMessage = 'Скриншот успешно загружен.');
    } catch (e) {
      setState(() => uploadMessage = 'Ошибка при загрузке файла.');
    }
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
        body: jsonEncode({
          "old_password": old,
          "new_password": newP,
          "confirm_password": confirm,
        }),
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Изменить пароль', style: GoogleFonts.montserrat()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              decoration: InputDecoration(labelText: 'Старый пароль'),
              obscureText: true,
            ),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(labelText: 'Новый пароль'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Подтвердите новый пароль'),
              obscureText: true,
            ),
            if (passwordMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(passwordMessage, style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Отмена')),
          ElevatedButton(onPressed: changePassword, child: Text('Сменить')),
        ],
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        Text(value, style: GoogleFonts.montserrat()),
      ],
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      currentIndex: 4,
      onTap: (index) {
        final routes = ['/home', '/apply', '/chat', '/notification', '/profile'];
        Navigator.pushReplacementNamed(context, routes[index]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_outlined), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?['avatar']?.toString();
    final cleanedUrl = avatarUrl != null && avatarUrl.startsWith('http')
        ? avatarUrl
        : 'http://127.0.0.1:8000$avatarUrl';
    final avatarWithTimestamp = '$cleanedUrl?ts=${DateTime.now().millisecondsSinceEpoch}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: DefaultTextStyle(
                style: GoogleFonts.montserrat(),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickAvatar,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: avatarImage != null
                                ? FileImage(File(avatarImage!.path))
                                : (profile?['avatar'] != null
                                    ? NetworkImage(avatarWithTimestamp)
                                    : const AssetImage('assets/avatar.png')) as ImageProvider,
                          ),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.0),
                            ),
                            child: Center(
                              child: Icon(Icons.camera_alt, color: Colors.white.withOpacity(0.0), size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}',
                      style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      profile?['email'] ?? '',
                      style: GoogleFonts.montserrat(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    _buildRow('Student Id:', profile?['s'] ?? '-') ,
                    const SizedBox(height: 10),
                    _buildRow('Phone Number:', profile?['phone'] ?? '-') ,
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: showPasswordChangeDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        minimumSize: Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Изменить пароль', style: GoogleFonts.montserrat(color: Colors.black)),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Статус заявки:', style: GoogleFonts.montserrat(fontSize: 18)),
                          const SizedBox(height: 10),
                          if (status.isEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Вы ещё не подали заявку.'),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () => Navigator.pushNamed(context, '/apply'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text('Перейти к заявке', style: GoogleFonts.montserrat(color: Colors.white)),
                                ),
                              ],
                            )
                          else ...[
                            Text(
                              statusError.isNotEmpty ? statusError : status,
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 10),
                            if (status.contains('одобрена')) ...[
                              ElevatedButton(
                                onPressed: pickFile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  paymentScreenshot == null ? 'Выбрать скрин оплаты' : 'Файл выбран',
                                  style: GoogleFonts.montserrat(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: uploadScreenshot,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text('Загрузить скриншот', style: GoogleFonts.montserrat(color: Colors.white)),
                              ),
                              if (uploadMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(uploadMessage, style: TextStyle(color: Colors.green)),
                                ),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: isEditEnabled ? () => Navigator.pushNamed(context, '/edit-application') : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Редактировать заявку', style: GoogleFonts.montserrat(color: Colors.white)),
                            )
                          ]
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}
