import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api.dart';
import 'dart:convert';

class ApplyScreen extends StatefulWidget {
  @override
  _ApplyScreenState createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _picker = ImagePicker();
  Map<String, dynamic> studentData = {};
  Map<String, XFile?> documents = {};
  List<String> dormitoryPrices = [];
  String? selectedDormCost;
  bool isLoading = false;

  List<String> documentFields = [
    'orphan_certificate',
    'disability_1_2_certificate',
    'disability_3_certificate',
    'parents_disability_certificate',
    'loss_of_breadwinner_certificate',
    'social_aid_certificate',
    'mangilik_el_certificate',
    'olympiad_winner_certificate',
  ];

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    final student = await AuthService.getStudentData();
    final client = RefreshHttpClient();
    final response = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/dorms/costs/"));
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

    setState(() {
      studentData = student;
      dormitoryPrices = data.map((e) => e.toString()).toList(); // исправлено здесь!
    });
  }

  Future<void> submitApplication() async {
    if (selectedDormCost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Выберите стоимость общежития")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await ApplicationService.createApplication(selectedDormCost!, documents);
      Navigator.pushReplacementNamed(context, '/testpage');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickFile(String key) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => documents[key] = file);
    }
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (index) {
        final routes = ['/home', '/apply', '/chat', '/notification', '/profile'];
        if (index < routes.length) {
          Navigator.pushReplacementNamed(context, routes[index]);
        }
      },
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_outlined), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: ''),
        BottomNavigationBarItem(
          icon: CircleAvatar(radius: 12, backgroundImage: AssetImage('assets/avatar.png')),
          label: '',
        ),
      ],
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.red, size: 30),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: const Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'NARXOZ\n',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            TextSpan(
              text: 'Dorm Mate',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      centerTitle: true,
    ),
    body: studentData.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: studentData['first_name']?.toString() ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(hintText: 'Имя'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: studentData['last_name']?.toString() ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(hintText: 'Фамилия'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: studentData['course']?.toString() ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(hintText: 'Курс'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: studentData['region']?.toString() ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(hintText: 'Регион'),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedDormCost,
                    decoration: const InputDecoration(
                      labelText: 'Стоимость общежития',
                    ),
                    items: dormitoryPrices
                        .map((cost) => DropdownMenuItem(
                              value: cost.toString(),
                              child: Text("$cost тг"),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedDormCost = value),
                  ),
                  const SizedBox(height: 20),
                  ...documentFields.map((field) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ElevatedButton(
                          onPressed: () => pickFile(field),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
                          child: Text(
                            documents[field] == null
                                ? 'Загрузить $field'
                                : 'Файл прикреплён: $field',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : submitApplication,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Отправить заявку и пройти тест'),
                  ),
                ],
              ),
            ),
          ),
    bottomNavigationBar: _buildBottomNavigationBar(),
  );
}
}