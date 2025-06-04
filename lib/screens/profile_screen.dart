import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

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

  Future<void> fetchApplicationStatus() async {
    try {
      final client = RefreshHttpClient();
      final response = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/application_status/"));
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
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        paymentScreenshot = file;
        showUploadButton = true;
      });
    }
  }

  Future<void> uploadScreenshot() async {
    if (paymentScreenshot == null) return;
    await ApplicationService.uploadPaymentScreenshot(File(paymentScreenshot!.path));
    setState(() {
      uploadMessage = 'Скриншот успешно загружен.';
      showUploadButton = false;
    });
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: Icon(Icons.photo),
              label: Text("Выбрать из галереи"),
              onPressed: () {
                Navigator.pop(context);
                changeAvatarFromSource(ImageSource.gallery);
              },
            ),
            TextButton.icon(
              icon: Icon(Icons.delete),
              label: Text("Удалить аватар"),
              onPressed: () {
                Navigator.pop(context);
                deleteAvatar();
              },
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        'Изменить пароль',
        style: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRoundedField(
            controller: _oldPasswordController,
            label: 'Старый пароль',
          ),
          SizedBox(height: 12),
          _buildRoundedField(
            controller: _newPasswordController,
            label: 'Новый пароль',
          ),
          SizedBox(height: 12),
          _buildRoundedField(
            controller: _confirmPasswordController,
            label: 'Подтвердите новый пароль',
          ),
          if (passwordMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                passwordMessage,
                style: GoogleFonts.montserrat(color: Colors.red),
              ),
            ),
             SizedBox(height: 24),
              Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    TextButton(
      onPressed: () => Navigator.of(context).pop(),
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
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
      // actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // actions: [
      //   TextButton(
      //     onPressed: () => Navigator.of(context).pop(),
      //     child: Text(
      //       'Отмена',
      //       style: GoogleFonts.montserrat(color: Colors.black),
      //     ),
      //   ),
      //   ElevatedButton(
      //     onPressed: changePassword,
      //     style: ElevatedButton.styleFrom(
      //       backgroundColor: Colors.red,
      //       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      //       shape: RoundedRectangleBorder(
      //         borderRadius: BorderRadius.circular(20),
      //       ),
      //     ),
      //     child: Text('Сменить', style: GoogleFonts.montserrat(color: Colors.white)),
      //   ),
        
      // ],
    ),
  );
}

Widget _buildRoundedField({required TextEditingController controller, required String label}) {
  return TextField(
    controller: controller,
    obscureText: true,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.montserrat(color: Colors.black),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: avatarImageProvider,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.edit, color: Colors.grey),
                          onPressed: showAvatarOptions,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text('${profile?['first_name']} ${profile?['last_name']}', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(profile?['email'] ?? '', style: GoogleFonts.montserrat(color: Colors.grey[700])),
                  SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: showPasswordChangeDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        minimumSize: Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Изменить пароль', style: GoogleFonts.montserrat(color: Colors.black)),
                    ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Student ID:', profile?['s'] ?? '-'),
                        _buildRow('Phone Number:', profile?['phone_number'] ?? '-'),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Статус заявки:', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        if (status.isEmpty) ...[
                          Text('Вы ещё не подали заявку.', style: GoogleFonts.montserrat()),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/apply'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: Size.fromHeight(48),
                            ),
                            child: Text('Перейти к заявке', style: GoogleFonts.montserrat(color: Colors.white)),
                          ),
                        ] else ...[
                          Text('Ваша заявка одобрена, внесите оплату и прикрепите сюда чек.', style: GoogleFonts.montserrat(fontSize: 16)),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: pickFile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[100],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: Size.fromHeight(48),
                            ),
                            child: Text('Прикрепить скрин оплаты', style: GoogleFonts.montserrat(color: Colors.black)),
                          ),
                          if (showUploadButton) ...[
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: uploadScreenshot,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[100],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                minimumSize: Size.fromHeight(48),
                              ),
                              child: Text('Отправить', style: GoogleFonts.montserrat(color: Colors.black)),
                            ),
                          ],
                          if (uploadMessage.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(uploadMessage, style: TextStyle(color: Colors.green)),
                            ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: isEditEnabled ? () => Navigator.pushNamed(context, '/edit-application') : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEditEnabled ? Colors.black : Colors.grey,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: Size.fromHeight(48),
                            ),
                            child: Text('Редактировать заявку', style: GoogleFonts.montserrat(color: Colors.white)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
