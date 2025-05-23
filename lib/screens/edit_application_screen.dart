import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/api.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

class EditApplicationScreen extends StatefulWidget {
  @override
  State<EditApplicationScreen> createState() => _EditApplicationScreenState();
}

class _EditApplicationScreenState extends State<EditApplicationScreen> {
  Map<String, dynamic> studentData = {};
  Map<String, dynamic> applicationData = {};
  List<Map<String, dynamic>> evidenceTypes = [];
  Map<String, dynamic> documents = {};
  List<String> dormitoryPrices = [];
  List<String> removedDocs = [];
  final picker = ImagePicker();

  bool isLoading = true;
  bool isModalOpen = false;

  String? selectedDormCost;
  final parentPhoneCtrl = TextEditingController();
  final entResultCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    try {
      final client = RefreshHttpClient();
      final student = await AuthService.getStudentData();

      final resApp = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/application/"));
      final appData = jsonDecode(utf8.decode(resApp.bodyBytes));

      final resEvidence = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/application/evidences/"));
      final evidencesRaw = jsonDecode(utf8.decode(resEvidence.bodyBytes));
      final evidences = evidencesRaw is Map && evidencesRaw.containsKey('results')
          ? List<Map<String, dynamic>>.from(evidencesRaw['results'])
          : List<Map<String, dynamic>>.from(evidencesRaw is List ? evidencesRaw : []);

      final resTypes = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/evidence-types/"));
      final typesRaw = jsonDecode(utf8.decode(resTypes.bodyBytes));
      final types = typesRaw is Map && typesRaw.containsKey('results')
          ? List<Map<String, dynamic>>.from(typesRaw['results'])
          : List<Map<String, dynamic>>.from(typesRaw is List ? typesRaw : []);

      final resPrices = await client.get(Uri.parse("http://127.0.0.1:8000/api/v1/dorms/costs/"));
      final pricesRaw = jsonDecode(utf8.decode(resPrices.bodyBytes));
      final prices = pricesRaw is Map && pricesRaw.containsKey('results')
          ? List<String>.from(pricesRaw['results'].map((e) => e.toString()))
          : List<String>.from((pricesRaw is List ? pricesRaw : []).map((e) => e.toString()));

      final mappedDocs = <String, dynamic>{};
      for (var ev in evidences) {
        final code = ev['code'];
        if (ev['file'] != null) {
          mappedDocs[code] = {
            'url': ev['file'],
            'name': ev['name'],
            'existing': true
          };
        }
      }

      setState(() {
        studentData = student;
        applicationData = appData;
        evidenceTypes = types;
        dormitoryPrices = prices;
        documents = mappedDocs;
        selectedDormCost = appData['dormitory_cost']?.toString();
        parentPhoneCtrl.text = appData['parent_phone'] ?? '';
        entResultCtrl.text = appData['ent_result']?.toString() ?? '';
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Ошибка при загрузке данных: $e");
    }
  }

  Future<void> pickFile(String code) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        documents[code] = file;
      });
    }
  }

  void removeFile(String code) {
    setState(() {
      if (documents[code] != null && documents[code] is Map && documents[code]['existing'] == true) {
        removedDocs.add(code);
      }
      documents.remove(code);
    });
  }

  Future<void> submitChanges() async {
    try {
      final uri = Uri.parse("http://127.0.0.1:8000/api/v1/student/application/");
      final token = await AuthService.getAccessToken();
      final request = http.MultipartRequest('PATCH', uri)
        ..headers['Authorization'] = 'Bearer $token';

      request.fields['dormitory_cost'] = selectedDormCost ?? '';
      request.fields['parent_phone'] = parentPhoneCtrl.text;
      request.fields['ent_result'] = entResultCtrl.text;

      documents.forEach((code, value) {
        if (value is PlatformFile) {
          request.files.add(http.MultipartFile.fromBytes(
            code,
            File(value.path!).readAsBytesSync(),
            filename: value.name,
          ));
        }
      });

      if (removedDocs.isNotEmpty) {
        request.fields['deleted_documents'] = jsonEncode(removedDocs);
      }

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pushReplacementNamed(context, '/profile');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при обновлении: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('Ошибка при отправке: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Редактирование заявки", style: GoogleFonts.montserrat()),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DefaultTextStyle(
                style: GoogleFonts.montserrat(),
                child: Column(
                  children: [
                    _buildTextField("Имя", studentData['first_name']),
                    _buildTextField("Фамилия", studentData['last_name']),
                    _buildTextField("Курс", studentData['course']?.toString()),
                    _buildTextField("Пол", studentData['gender'] == 'M' ? 'Мужской' : 'Женский'),
                    _buildTextField("Дата рождения", studentData['birth_date']),
                    _buildEditableField("Телефон родителя", parentPhoneCtrl),
                    _buildEditableField("Результат ЕНТ", entResultCtrl),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedDormCost,
                      decoration: const InputDecoration(
                        labelText: 'Ценовой диапазон',
                        border: OutlineInputBorder(),
                      ),
                      items: dormitoryPrices
                          .map((cost) => DropdownMenuItem(
                                value: cost,
                                child: Text("$cost тг", style: GoogleFonts.montserrat()),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedDormCost = val),
                    ),
                    const SizedBox(height: 20),
                    ...evidenceTypes.map((doc) => _buildFileRow(doc)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: submitChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text("Сохранить изменения", style: GoogleFonts.montserrat(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: value ?? '',
        readOnly: true,
        style: GoogleFonts.montserrat(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(),
          border: OutlineInputBorder(),
          fillColor: Colors.grey.shade100,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        style: GoogleFonts.montserrat(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildFileRow(Map<String, dynamic> doc) {
    final code = doc['code'];
    final label = doc['label'] ?? doc['name'];
    final file = documents[code];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          Row(
            children: [
              if (file != null)
                file is PlatformFile
                    ? Text(file.name, style: GoogleFonts.montserrat())
                    : InkWell(
                        onTap: () async {
                          final url = Uri.parse(file['url']);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Невозможно открыть ссылку')),
                            );
                          }
                        },
                        child: Text(file['name'], style: GoogleFonts.montserrat(color: Colors.blue)),
                      ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => removeFile(code),
                child: Text("Удалить", style: GoogleFonts.montserrat(color: Colors.red)),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: () => pickFile(code),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
