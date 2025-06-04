import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api.dart';

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

  Future<void> fetchQuestions() async {
    setState(() => loading = true);
    try {
      final client = RefreshHttpClient();
      final response = await client.get(
        Uri.parse('http://127.0.0.1:8000/api/v1/questionlist'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> list = decoded is List
            ? decoded
            : (decoded['results'] as List<dynamic>? ?? []);
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
        Uri.parse('http://127.0.0.1:8000/api/v1/test/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'test_answers': payload}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Тест успешно отправлен!');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacementNamed(context, '/profile');
      } else {
        _showSnackBar('Ошибка отправки: статус ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Ошибка отправки: $e');
    } finally {
      setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text('Психологический тест', style: GoogleFonts.montserrat()),
        backgroundColor: const Color(0xFFD50032),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD50032)))
          : questions.isEmpty
              ? const Center(child: Text('Вопросы не найдены'))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Вопрос ${currentIndex + 1} из ${questions.length}',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              questions[currentIndex]['question_text'] ?? '',
                              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 20),
                            ...['A', 'B', 'C'].where((k) => questions[currentIndex]['answer_variant_${k.toLowerCase()}'] != null && questions[currentIndex]['answer_variant_${k.toLowerCase()}'].toString().isNotEmpty).map((k) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: RadioListTile<String>(
                                  value: k,
                                  groupValue: answers[currentIndex],
                                  onChanged: (v) => setState(() => answers[currentIndex] = v!),
                                  title: Text(
                                    questions[currentIndex]['answer_variant_${k.toLowerCase()}'],
                                    style: GoogleFonts.montserrat(fontSize: 16),
                                  ),
                                  activeColor: const Color(0xFFD50032),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  tileColor: Colors.grey.shade100,
                                  selectedTileColor: const Color(0xFFFFEDEE),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: currentIndex == 0 ? null : () => setState(() => currentIndex--),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Назад'),
                          ),
                          ElevatedButton(
                            onPressed: submitting ? null : handleNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD50032),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                    currentIndex == questions.length - 1 ? 'Отправить тест' : 'Далее',
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
}