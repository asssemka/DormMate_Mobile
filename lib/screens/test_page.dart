import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api.dart';
import '../gen_l10n/app_localizations.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  bool loading = true;
  bool submitting = false;
  Map<int, String> answers = {};

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  String getLocalizedField(Map<String, dynamic> obj, BuildContext context, String baseField) {
    final locale = Localizations.localeOf(context).languageCode;
    final keys = [
      '${baseField}_$locale', // напр. question_text_ru
      '${baseField}_ru',
      '${baseField}_kk',
      '${baseField}_en',
    ];
    for (final key in keys) {
      if (obj[key] != null && (obj[key] as String).trim().isNotEmpty) return obj[key] as String;
    }
    return '';
  }

  Future<void> fetchQuestions() async {
    setState(() => loading = true);
    try {
      final client = RefreshHttpClient();
      final response = await client.get(
        Uri.parse('https://dormmate-back.onrender.com/api/v1/questionlist'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> list =
            decoded is List ? decoded : (decoded['results'] as List<dynamic>? ?? []);
        setState(() {
          questions = List<Map<String, dynamic>>.from(list);
        });
      } else {
        _showSnackBar('Ошибка загрузки: статус ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Ошибка загрузки: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void handleNext() {
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      submitTest();
    }
  }

  Future<void> submitTest() async {
    if (answers.length < questions.length) {
      _showSnackBar('Пожалуйста, ответьте на все вопросы');
      return;
    }

    setState(() => submitting = true);
    try {
      final client = RefreshHttpClient();
      final payload = List.generate(
        questions.length,
        (i) => answers[i] ?? '',
      );
      final response = await client.post(
        Uri.parse('https://dormmate-back.onrender.com/api/v1/test/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'test_answers': payload}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Тест успешно отправлен!');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacementNamed(context, '/profile');
      } else {
        // Логируем ошибку с подробностями
        print("Ошибка отправки: ${response.statusCode}, ${response.body}");
        _showSnackBar('Ошибка отправки: статус ${response.statusCode}');
      }
    } catch (e) {
      print("Ошибка отправки теста: $e"); // Логируем ошибку
      _showSnackBar('Ошибка отправки: $e');
    } finally {
      setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(t.psychological_test, style: GoogleFonts.montserrat()),
        backgroundColor: const Color(0xFFD50032),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD50032)))
          : questions.isEmpty
              ? Center(child: Text(t.question_not_found))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Прогресс теста
                      Text(
                        t.question_progress(currentIndex + 1, questions.length),
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Карточка вопроса
                      Container(
                        padding: const EdgeInsets.all(22),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getLocalizedField(questions[currentIndex], context, 'question_text'),
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ..._buildAnswerOptions(questions[currentIndex], currentIndex, textColor,
                                cardColor, isDark),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed:
                                currentIndex == 0 ? null : () => setState(() => currentIndex--),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(t.back),
                          ),
                          ElevatedButton(
                            onPressed: submitting ? null : handleNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD50032),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: submitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    currentIndex == questions.length - 1 ? t.submit_test : t.next,
                                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildAnswerOptions(
    Map<String, dynamic> question,
    int questionIdx,
    Color textColor,
    Color cardColor,
    bool isDark,
  ) {
    final answerFields = ['answer_variant_a', 'answer_variant_b', 'answer_variant_c'];
    final answersList = answerFields
        .map((f) => getLocalizedField(question, context, f))
        .where((t) => t.isNotEmpty)
        .toList();

    // Список букв-индексов для вариантов
    final answerKeys = ['A', 'B', 'C'];

    return List<Widget>.generate(
      answersList.length,
      (i) {
        final answerText = answersList[i];
        final answerKey = answerKeys[i]; // "A", "B" или "C"
        final isSelected = answers[questionIdx] == answerKey;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected ? (isDark ? Colors.red[400] : const Color(0xFFD50032)) : cardColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => answers[questionIdx] = answerKey), // <--- ВАЖНО!
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[700]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        answerText,
                        style: GoogleFonts.montserrat(
                          color: isSelected ? Colors.white : textColor,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    // Можно рядом показывать и букву, если нужно:
                    // Text(answerKey, style: GoogleFonts.montserrat(color: textColor)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
