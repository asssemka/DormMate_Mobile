// lib/screens/test_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api.dart'; // здесь лежит RefreshHttpClient

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: статус ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, ответьте на все вопросы')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Тест успешно отправлен!')),
        );
        await Future.delayed(const Duration(seconds: 1));
        // Здесь переходим на профиль, как вы и просили
        Navigator.pushReplacementNamed(context, '/profile');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: статус ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e')),
      );
    } finally {
      setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1) Загрузка
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Психологический тест')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // 2) Вопросов нет
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Психологический тест')),
        body: const Center(child: Text('Вопросы не найдены')),
      );
    }
    // 3) Показ вопроса
    final q = questions[currentIndex];
    final opts = <Map<String, String>>[];
    if ((q['answer_variant_a'] ?? '').toString().isNotEmpty) {
      opts.add({'value': 'A', 'label': q['answer_variant_a'].toString()});
    }
    if ((q['answer_variant_b'] ?? '').toString().isNotEmpty) {
      opts.add({'value': 'B', 'label': q['answer_variant_b'].toString()});
    }
    if ((q['answer_variant_c'] ?? '').toString().isNotEmpty) {
      opts.add({'value': 'C', 'label': q['answer_variant_c'].toString()});
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Психологический тест')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Вопрос ${currentIndex + 1} из ${questions.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              q['question_text']?.toString() ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ...opts.map((opt) => RadioListTile<String>(
                  title: Text(opt['label']!),
                  value: opt['value']!,
                  groupValue: answers[currentIndex],
                  onChanged: (v) => setState(() => answers[currentIndex] = v!),
                )),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentIndex == 0
                      ? null
                      : () => setState(() => currentIndex--),
                  child: const Text('Назад'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : handleNext,
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
                          currentIndex == questions.length - 1
                              ? 'Отправить тест'
                              : 'Далее',
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
