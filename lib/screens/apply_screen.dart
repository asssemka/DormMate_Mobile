import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../gen_l10n/app_localizations.dart';
import '../services/api.dart';

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
  String? gpaValue;

  // Для ЕНТ сертификата
  PlatformFile? entCertificateFile;
  String? entScore;
  String? entExtractError;

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> pickFile(String key) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => documents[key] = result.files.first);
    }
  }

  Future<void> pickEntCertificateAndExtractScore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        entCertificateFile = result.files.first;
        entScore = null;
        entExtractError = null;
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
            entExtractError = null;
          });
        } else {
          setState(() {
            entScore = null;
            entExtractError = "Ошибка при извлечении балла";
          });
        }
      } catch (e) {
        setState(() {
          entScore = null;
          entExtractError = "Ошибка при отправке файла: $e";
        });
      }
    }
  }

  void removeEntCertificate() {
    setState(() {
      entCertificateFile = null;
      entScore = null;
      entExtractError = null;
    });
  }

  Future<void> fetchInitialData() async {
    try {
      final student = await AuthService.getStudentData();
      final client = RefreshHttpClient();

      final dormResponse =
          await client.get(Uri.parse("https://dormmate-back.onrender.com/api/v1/dorms/costs/"));
      final dormData = jsonDecode(utf8.decode(dormResponse.bodyBytes));
      final dormList =
          dormData is Map && dormData.containsKey('results') ? dormData['results'] : dormData;

      final evidenceResponse = await client.get(
        Uri.parse("https://dormmate-back.onrender.com/api/v1/evidence-types/"),
      );
      final decoded = jsonDecode(utf8.decode(evidenceResponse.bodyBytes));
      final evidenceList =
          decoded is Map && decoded.containsKey('results') ? decoded['results'] : decoded;

      if (!mounted) return;

      setState(() {
        studentData = student;
        dormitoryPrices = (dormList as List).map((e) => e.toString()).toList();
        evidenceTypes = List<Map<String, dynamic>>.from(evidenceList);
        gpaValue = student['gpa']?.toString() ?? '';
      });
    } catch (e) {
      debugPrint("Ошибка при загрузке данных: $e");
    }
  }

  Future<void> submitApplication() async {
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
    if (!isFirstYear && (gpaValue == null || gpaValue!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите GPA")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Отсутствует токен доступа");

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("https://dormmate-back.onrender.com/api/v1/create_application/"),
      )
        ..fields['dormitory_cost'] = selectedDormCost!
        ..fields['parent_phone'] = studentData['parent_phone'] ?? ''
        ..headers["Authorization"] = "Bearer $token";

      // GPA для 2-4 курса
      if (!isFirstYear) {
        request.fields['ent_result'] = gpaValue ?? '';
      }

      // Для 1 курса — файл сертификата и балл
      if (isFirstYear && entCertificateFile != null && entCertificateFile!.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'ent_certificate', // ключ для бэка
            entCertificateFile!.bytes!,
            filename: entCertificateFile!.name,
            contentType: MediaType('application', 'pdf'),
          ),
        );
        request.fields['ent_result'] = entScore ?? '';
      }

      // Остальные документы (кроме ent_certificate)
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

  Widget _buildTextField(
    String label,
    String value,
    Color textColor,
    Color fillColor,
    bool editable, {
    void Function(String)? onChanged,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 14, color: textColor)),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value,
            readOnly: !editable,
            onChanged: onChanged,
            keyboardType: keyboardType,
            style: GoogleFonts.montserrat(color: textColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
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

  Widget _buildEntCertificateBlock(Color inputBg, Color textMain) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ЕНТ балл (автоматически):",
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: textMain,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(text: entScore ?? ''),
          decoration: InputDecoration(
            hintText: "Балл появится после загрузки PDF",
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          style: GoogleFonts.montserrat(color: textMain),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: pickEntCertificateAndExtractScore,
          icon: const Icon(Icons.picture_as_pdf),
          label: Text(
            entCertificateFile == null
                ? "Выбрать PDF сертификат"
                : "Файл прикреплён: ${entCertificateFile!.name}",
            style: GoogleFonts.montserrat(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: entCertificateFile == null ? Colors.blue : Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: const Size.fromHeight(45),
          ),
        ),
        if (entCertificateFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: removeEntCertificate,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: Text('Удалить файл', style: TextStyle(color: Colors.red)),
            ),
          ),
        if (entExtractError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              entExtractError!,
              style: TextStyle(color: Colors.red),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFileUploadSectionWithTranslation(
    AppLocalizations t,
    bool isDark,
    Color blockBg,
    Color textMain,
    bool isFirstYear,
  ) {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...evidenceTypes.where((doc) => doc['code'] != 'ent_certificate').map((doc) {
            final code = doc['code'];
            final label = doc['label'] ?? doc['name'];
            final file = documents[code];
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton(
                onPressed: () => pickFile(code),
                style: ElevatedButton.styleFrom(
                  backgroundColor: file == null
                      ? (isDark ? Colors.blueGrey : Colors.blue)
                      : (isDark ? Colors.green.shade700 : Colors.green),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size.fromHeight(45),
                ),
                child: Text(
                  file == null
                      ? "${t.upload} $label"
                      : "${t.file_attached ?? 'Файл прикреплён'}: ${file.name}",
                  style: GoogleFonts.montserrat(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        ],
      ),
      crossFadeState: showDocuments ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mainBg = Theme.of(context).scaffoldBackgroundColor;
    final blockBg = Theme.of(context).cardColor;
    final textMain = isDark ? Colors.white : Colors.black87;
    final inputBg = isDark ? Color(0xFF22232A) : Colors.grey.shade200;

    final int course = int.tryParse(studentData['course']?.toString() ?? '0') ?? 0;
    final bool isFirstYear = course == 1;

    return Scaffold(
      backgroundColor: mainBg,
      appBar: AppBar(
        backgroundColor: blockBg,
        elevation: 0,
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'NARXOZ\n',
                style: GoogleFonts.montserrat(
                  color: Color(0xFFD50032),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: 'Dorm Mate',
                style: GoogleFonts.montserrat(
                    color: Color(0xFFD50032).withOpacity(0.85), fontSize: 14),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: Color(0xFFD50032)),
      ),
      body: studentData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: DefaultTextStyle(
                style: GoogleFonts.montserrat(color: textMain),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                        t.first_name, studentData['first_name'] ?? '', textMain, inputBg, false),
                    _buildTextField(
                        t.last_name, studentData['last_name'] ?? '', textMain, inputBg, false),
                    _buildTextField(t.course, studentData['course']?.toString() ?? '', textMain,
                        inputBg, false),
                    _buildTextField(
                        t.parent_phone, studentData['parent_phone'] ?? '', textMain, inputBg, true),
                    _buildTextField(
                        t.gender,
                        studentData['gender'] == 'M' ? t.male ?? 'Мужской' : t.female,
                        textMain,
                        inputBg,
                        false),
                    _buildTextField(t.dorm_price_10_months, studentData['birth_date'] ?? '',
                        textMain, inputBg, false),

                    // ==== Курс-специфичные поля ====
                    if (!isFirstYear)
                      _buildTextField(
                        "GPA",
                        gpaValue ?? '',
                        textMain,
                        inputBg,
                        true,
                        onChanged: (val) => gpaValue = val,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),

                    if (isFirstYear) ...[
                      const SizedBox(height: 16),
                      _buildEntCertificateBlock(inputBg, textMain),
                    ],

                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedDormCost,
                      decoration: InputDecoration(
                        labelText: t.dorm_price_10_months,
                        labelStyle: GoogleFonts.montserrat(color: textMain),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: blockBg,
                      items: dormitoryPrices
                          .map(
                            (cost) => DropdownMenuItem(
                              value: cost,
                              child:
                                  Text("$cost тг", style: GoogleFonts.montserrat(color: textMain)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => selectedDormCost = value),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() => showDocuments = !showDocuments),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD50032),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(
                        showDocuments ? t.hide : t.show,
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                    ),
                    _buildFileUploadSectionWithTranslation(
                        t, isDark, blockBg, textMain, isFirstYear),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading ? null : submitApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(t.submit, style: GoogleFonts.montserrat(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
