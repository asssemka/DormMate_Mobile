import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../widgets/bottom_navigation_bar.dart';

class ApplyScreen extends StatefulWidget {
  @override
  _ApplyScreenState createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  Map<String, dynamic> studentData = {};
  Map<String, PlatformFile> documents = {};
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

  Future<void> pickFile(String key) async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.isNotEmpty) {
      setState(() => documents[key] = result.files.first);
    }
  }

  Future<void> fetchInitialData() async {
    try {
      final student = await AuthService.getStudentData();
      final client = RefreshHttpClient();

      final dormResponse = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/dorms/costs/"));
      final dormData = jsonDecode(utf8.decode(dormResponse.bodyBytes));
      final dormList =
          dormData is Map && dormData.containsKey('results') ? dormData['results'] : dormData;

      final evidenceResponse =
          await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/evidence-types/"));
      final decoded = jsonDecode(utf8.decode(evidenceResponse.bodyBytes));
      final evidenceList =
          decoded is Map && decoded.containsKey('results') ? decoded['results'] : decoded;

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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Выберите стоимость общежития")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Отсутствует токен доступа");

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("http://127.0.0.1:8000/api/v1/create_application/"),
      )
        ..fields['dormitory_cost'] = selectedDormCost!
        ..fields['parent_phone'] = studentData['parent_phone'] ?? ''
        ..fields['ent_result'] = studentData['ent_result']?.toString() ?? ''
        ..headers["Authorization"] = "Bearer $token";

      documents.forEach((key, file) {
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            key,
            file.bytes!,
            filename: file.name,
            contentType: MediaType('application', 'pdf'),
          ));
        }
      });

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 201) {
        throw Exception("Ошибка при создании заявки: ${response.statusCode}");
      }

      Navigator.pushReplacementNamed(context, '/testpage');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    } finally {
      setState(() => isLoading = false);
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
            style: GoogleFonts.montserrat(),
            decoration: InputDecoration(
              filled: true,
              fillColor: editable ? Colors.white : Colors.grey.shade200,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
                file == null ? "Загрузить $label" : "Файл прикреплён: ${file.name}",
                style: GoogleFonts.montserrat(),
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
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'NARXOZ\n',
                style: GoogleFonts.montserrat(
                    color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              TextSpan(
                  text: 'Dorm Mate',
                  style: GoogleFonts.montserrat(color: Colors.red, fontSize: 14)),
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
              child: DefaultTextStyle(
                style: GoogleFonts.montserrat(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField("Имя", studentData['first_name'] ?? ''),
                    _buildTextField("Фамилия", studentData['last_name'] ?? ''),
                    _buildTextField("Курс", studentData['course']?.toString() ?? ''),
                    _buildTextField("Дата рождения", studentData['birth_date'] ?? ''),
                    _buildTextField("Пол", studentData['gender'] == 'M' ? 'Мужской' : 'Женский'),
                    _buildTextField("Телефон родителей", studentData['parent_phone'] ?? '',
                        editable: true),
                    _buildTextField("Результат ЕНТ", studentData['ent_result']?.toString() ?? '',
                        editable: true),
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
                              child: Text("$cost тг", style: GoogleFonts.montserrat())))
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
                        style: GoogleFonts.montserrat(color: Colors.white),
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
                          : Text('Отправить заявку',
                              style: GoogleFonts.montserrat(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
