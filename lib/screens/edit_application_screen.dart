import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../gen_l10n/app_localizations.dart';
import '../services/api.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

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
  bool isLoading = true;
  String? selectedDormCost;
  final parentPhoneCtrl = TextEditingController();
  final entResultCtrl = TextEditingController();

  // Added variables
  PlatformFile? entCertificateFile; // To store selected ENТ certificate file
  String? entScore; // To store extracted ENТ score
  String? gpaValue; // To store GPA for higher courses

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    try {
      final client = RefreshHttpClient();
      final student = await AuthService.getStudentData();

      final resApp =
          await client.get(Uri.parse("https://dormmate-back.onrender.com/api/v1/application/"));
      final appData = jsonDecode(utf8.decode(resApp.bodyBytes));

      final resEvidence = await client
          .get(Uri.parse("https://dormmate-back.onrender.com/api/v1/application/evidences/"));
      final evidencesRaw = jsonDecode(utf8.decode(resEvidence.bodyBytes));
      final evidences = evidencesRaw is Map && evidencesRaw.containsKey('results')
          ? List<Map<String, dynamic>>.from(evidencesRaw['results'])
          : List<Map<String, dynamic>>.from(evidencesRaw);

      final resTypes =
          await client.get(Uri.parse("https://dormmate-back.onrender.com/api/v1/evidence-types/"));
      final typesRaw = jsonDecode(utf8.decode(resTypes.bodyBytes));
      final types = typesRaw is Map && typesRaw.containsKey('results')
          ? List<Map<String, dynamic>>.from(typesRaw['results'])
          : List<Map<String, dynamic>>.from(typesRaw);

      final resPrices =
          await client.get(Uri.parse("https://dormmate-back.onrender.com/api/v1/dorms/costs/"));
      final pricesRaw = jsonDecode(utf8.decode(resPrices.bodyBytes));
      final prices = pricesRaw is Map && pricesRaw.containsKey('results')
          ? List<String>.from(pricesRaw['results'].map((e) => e.toString()))
          : List<String>.from(pricesRaw.map((e) => e.toString()));

      final mappedDocs = <String, dynamic>{};
      for (var ev in evidences) {
        final code = ev['code'];
        if (ev['file'] != null) {
          mappedDocs[code] = {'url': ev['file'], 'name': ev['name'], 'existing': true};
        }
      }

      if (mounted) {
        setState(() {
          studentData = student;
          applicationData = appData;
          evidenceTypes = types;
          dormitoryPrices = prices;
          documents = mappedDocs;
          selectedDormCost = appData['dormitory_cost']?.toString();
          parentPhoneCtrl.text = appData['parent_phone'] ?? '';
          entResultCtrl.text = appData['ent_result']?.toString() ?? '';
          gpaValue = appData['gpa']?.toString() ?? ''; // Fetch GPA for higher courses
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Ошибка: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(String label, String value, Color cardColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold, color: textColor, fontSize: 18)),
            Text(value ?? '-', style: GoogleFonts.montserrat(color: textColor, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(
      String label, TextEditingController ctrl, Color cardColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.montserrat(color: textColor, fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(color: textColor, fontSize: 18),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildFileRow(Map<String, dynamic> doc, Color cardColor, Color textColor) {
    final code = doc['code'];
    final label = doc['label'] ?? doc['name'];
    final file = documents[code];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold, color: textColor, fontSize: 18)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: file == null
                      ? Text('Файл не выбран',
                          style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 18))
                      : Text(file.name,
                          style: GoogleFonts.montserrat(color: textColor, fontSize: 18)),
                ),
                IconButton(
                    onPressed: () => removeFile(code), icon: Icon(Icons.delete, color: Colors.red)),
                IconButton(
                    onPressed: () => pickFile(code),
                    icon: Icon(Icons.upload_file, color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to pick a file
  Future<void> pickFile(String code) async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() => documents[code] = file);
    }
  }

  // Method to remove a file
  void removeFile(String code) {
    setState(() {
      if (documents[code]?['existing'] == true) removedDocs.add(code);
      documents.remove(code);
    });
  }

  // Method to pick ENТ certificate and extract score
  Future<void> pickEntCertificateAndExtractScore() async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        entCertificateFile = result.files.first;
        entScore = null;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        final uri = Uri.parse("https://dormmate-back.onrender.com/api/v1/ent-extract/");
        final request = http.MultipartRequest('POST', uri)
          ..headers["Authorization"] = "Bearer $token"
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              entCertificateFile!.bytes!,
              filename: entCertificateFile!.name,
              contentType: MediaType('application', 'pdf'),
            ),
          );
        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          setState(() {
            entScore = data['total_score']?.toString();
          });
        } else {
          setState(() {
            entScore = null;
          });
        }
      } catch (e) {
        setState(() {
          entScore = null;
        });
      }
    }
  }

  // Method to submit changes
  Future<void> submitChanges() async {
    final int course = int.tryParse(studentData['course']?.toString() ?? '0') ?? 0;
    final bool isFirstYear = course == 1;

    if (selectedDormCost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Выберите стоимость общежития")),
      );
      return;
    }
    if (isFirstYear && entCertificateFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Загрузите PDF сертификат ЕНТ")),
      );
      return;
    }
    if (isFirstYear && (entScore == null || entScore!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Не удалось получить балл ЕНТ из файла")),
      );
      return;
    }
    if (!isFirstYear && (entScore == null || entScore!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите GPA")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String? token;

      if (kIsWeb) {
        token = await AuthService.getAccessToken();
      } else {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('access_token');
      }

      if (token == null || token.isEmpty) {
        throw Exception("Отсутствует токен доступа");
      }

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("https://dormmate-back.onrender.com/api/v1/create_application/"),
      )
        ..fields['dormitory_cost'] = selectedDormCost!
        ..fields['parent_phone'] = studentData['parent_phone'] ?? ''
        ..headers["Authorization"] = "Bearer $token";

      if (!isFirstYear) {
        request.fields['ent_result'] = '0'; // For higher courses, send 0
      }

      if (isFirstYear && entCertificateFile != null && entCertificateFile!.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'ent_certificate', // key for backend
            entCertificateFile!.bytes!,
            filename: entCertificateFile!.name,
            contentType: MediaType('application', 'pdf'),
          ),
        );
        request.fields['ent_result'] = entScore ?? ''; // Score for first year
      }

      documents.forEach((key, file) {
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              key,
              file.bytes!,
              filename: file.name,
              contentType: MediaType('application', 'pdf'),
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color mainBg = isDark ? const Color(0xFF181825) : const Color(0xfff6f7fa);
    final Color blockBg = isDark ? const Color(0xFF232338) : Colors.white;
    final Color mainText = isDark ? Colors.white : Color(0xFF1e2134);

    return Scaffold(
      backgroundColor: mainBg,
      appBar: AppBar(
        backgroundColor: blockBg,
        elevation: 0,
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'DormMate\n',
                style: GoogleFonts.montserrat(
                  color: Color(0xFFD50032),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: 'Edit Application',
                style: GoogleFonts.montserrat(
                    color: Color(0xFFD50032).withOpacity(0.85), fontSize: 14),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Color(0xFFD50032)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: DefaultTextStyle(
                style: GoogleFonts.montserrat(color: mainText),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                        t.first_name, studentData['first_name'] ?? '', mainText, blockBg),
                    _buildTextField(t.last_name, studentData['last_name'] ?? '', mainText, blockBg),
                    _buildTextField(
                        t.course, studentData['course']?.toString() ?? '', mainText, blockBg),
                    _buildTextField(t.gender, studentData['gender'] == 'M' ? t.male : t.female,
                        mainText, blockBg),
                    _buildTextField(
                        t.ent_result, studentData['ent_result'] ?? '', mainText, blockBg),
                    _buildTextField(
                        t.parent_phone, studentData['parent_phone'] ?? '', mainText, blockBg),
                    _buildEditableField(t.parent_phone, parentPhoneCtrl, blockBg, mainText),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: dormitoryPrices.contains(selectedDormCost) ? selectedDormCost : null,
                      decoration: InputDecoration(
                        labelText: t.dorm_price_10_months,
                        labelStyle: GoogleFonts.montserrat(color: mainText),
                        filled: true,
                        fillColor: blockBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: blockBg,
                      style: GoogleFonts.montserrat(color: mainText),
                      items: dormitoryPrices
                          .map((cost) => DropdownMenuItem(
                                value: cost,
                                child: Text("$cost тг",
                                    style: GoogleFonts.montserrat(color: mainText)),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedDormCost = val),
                    ),
                    const SizedBox(height: 20),
                    ...evidenceTypes.map((doc) => _buildFileRow(doc, blockBg, mainText)).toList(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: submitChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child:
                          Text(t.save_changes, style: GoogleFonts.montserrat(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }
}
