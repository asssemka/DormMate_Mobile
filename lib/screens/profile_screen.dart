import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api.dart';
import 'dart:io';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  String status = '';
  String statusError = '';
  String uploadMessage = '';
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();
  XFile? paymentScreenshot;

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchApplicationStatus();
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
          status = data['status'] ?? 'Неизвестный статус';
        });
      } else {
        setState(() {
          status = 'Ошибка загрузки статуса: \${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        status = 'Ошибка загрузки статуса: \$e';
      });
    }
  }

  Future<void> pickFile() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => paymentScreenshot = file);
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

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      currentIndex: 3,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/apply');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/chat');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/notification');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_outlined), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: ''),
        BottomNavigationBarItem(icon: CircleAvatar(radius: 12, backgroundImage: AssetImage('assets/avatar.png')), label: ''),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/avatar.png'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    profile?['email'] ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Student Id:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(profile?['s'] ?? '-')
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phone Number:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(profile?['phone'] ?? '-')
                    ],
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[100]),
                    child: const Text('Change Password', style: TextStyle(color: Colors.black)),
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
                        const Text('Application status:', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 10),
                        Text(
                          statusError.isNotEmpty ? statusError : status,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        if (status.contains('одобрена')) ...[
                          ElevatedButton(
                            onPressed: pickFile,
                            child: Text(paymentScreenshot == null ? 'Выбрать скрин оплаты' : 'Файл выбран'),
                          ),
                          ElevatedButton(
                            onPressed: uploadScreenshot,
                            child: const Text('Загрузить скриншот'),
                          ),
                          if (uploadMessage.isNotEmpty)
                            Text(uploadMessage, style: const TextStyle(color: Colors.green)),
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}