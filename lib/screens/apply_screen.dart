import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
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
  List<Map<String, dynamic>> evidenceTypes = [];
  String? selectedDormCost;
  bool isLoading = false;
  bool showDocuments = false;

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    try {
      final student = await AuthService.getStudentData();
      final client = RefreshHttpClient();

      final dormResponse = await client.get(
        Uri.parse("http://127.0.0.1:8000/api/v1/dorms/costs/"),
      );
      final dormData = jsonDecode(utf8.decode(dormResponse.bodyBytes));
      final dormList = dormData is Map && dormData.containsKey('results')
          ? dormData['results']
          : dormData;

      final evidenceResponse = await client.get(
        Uri.parse("http://127.0.0.1:8000/api/v1/evidence-types/"),
      );
      final decoded = jsonDecode(utf8.decode(evidenceResponse.bodyBytes));
      final evidenceList = decoded is Map && decoded.containsKey('results')
          ? decoded['results']
          : decoded;

      if (!mounted) return;

      setState(() {
        studentData = student;
        dormitoryPrices = (dormList as List).map((e) => e.toString()).toList();
        evidenceTypes = List<Map<String, dynamic>>.from(evidenceList);
      });
    } catch (e) {
      debugPrint("Ошибка при загрузке данных: $e");
    }
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

  Widget _buildTextField(String label, String value, {bool editable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 14)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value,
            readOnly: !editable,
            decoration: InputDecoration(
              filled: true,
              fillColor: editable ? Colors.white : Colors.grey.shade200,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Column(
        children: evidenceTypes.map((doc) {
          final code = doc['code'];
          final label = doc['label'] ?? doc['name'];
          final file = documents[code];
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ElevatedButton(
              onPressed: () => pickFile(code),
              style: ElevatedButton.styleFrom(
                backgroundColor: file == null ? Colors.blue : Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size.fromHeight(45),
              ),
              child: Text(
                file == null ? "Загрузить $label" : "Файл прикреплён: $label",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      ),
      crossFadeState: showDocuments ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
        automaticallyImplyLeading: false,
      ),
      body: studentData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField("Имя", studentData['first_name'] ?? ''),
                  _buildTextField("Фамилия", studentData['last_name'] ?? ''),
                  _buildTextField("Курс", studentData['course']?.toString() ?? ''),
                  _buildTextField("Дата рождения", studentData['birth_date'] ?? ''),
                  _buildTextField("Пол", studentData['gender'] == 'M' ? 'Мужской' : 'Женский'),
                  _buildTextField("Телефон родителей", studentData['parent_phone'] ?? '', editable: true),
                  _buildTextField("Результат ЕНТ", studentData['ent_result']?.toString() ?? '', editable: true),
                  const Text(
                    "Загрузите ЕНТ сертификат в разделе \"Загрузить документы\", без этого сертификата ваш результат учитываться не будет",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedDormCost,
                    decoration: const InputDecoration(
                      labelText: 'Ценовой диапазон',
                      border: OutlineInputBorder(),
                    ),
                    items: dormitoryPrices
                        .map((cost) => DropdownMenuItem(
                              value: cost,
                              child: Text("$cost тг"),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedDormCost = value),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() => showDocuments = !showDocuments),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: const StadiumBorder(),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      showDocuments ? "Скрыть документы" : "Загрузить документы",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  _buildFileUploadSection(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: const StadiumBorder(),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Отправить заявку', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          final routes = ['/home', '/apply', '/chat', '/notifications', '/profile'];
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
      ),
    );
  }
}