import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UsefulInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Полезная информация'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Полезная информация перед заселением',
              style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          _sectionTitle('📜 Правила проживания'),
          _bulletList([
            'Проживание в Доме студентов разрешено с 06:00 до 23:00.',
            'Соблюдать паспортный режим и использовать пропуск.',
            'Поддерживать чистоту и порядок в жилой комнате и местах общего пользования.',
            'Бережно относиться к имуществу, оборудованию и инвентарю общежития.',
            'Своевременно оплачивать проживание и услуги прачечной.',
            'Стирать бельё только в специально отведённых местах (не в комнате).',
            'Строго соблюдать правила пожарной и электрической безопасности.',
            'Запрещено: переселяться без разрешения, использовать обогреватели, плиты, стиральные машины в комнате.',
            'После 21:00 запрещено шуметь, включать громкую музыку, петь.',
            'Запрещено ночевать посторонним, находиться в нетрезвом виде, курить, употреблять алкоголь или наркотики.',
            'В случае порчи имущества, необходимо возместить ущерб по рыночной стоимости.',
            'Нарушение правил влечёт за собой выселение без возврата оплаты.',
          ]),
          const SizedBox(height: 24),

          _sectionTitle('🎒 Что взять с собой'),
          _bulletList([
            'Полотенца.',
            'Личные средства гигиены.',
            'Кружка, тарелка, ложка, вилка, чайник (по желанию).',
            'Удлинитель, переноска.',
            'Набор для уборки (тряпка, моющее средство).',
          ]),
          const SizedBox(height: 24),

          _sectionTitle('🤝 Как улаживать конфликты'),
          _numberedList([
            'Обсудите проблему спокойно: не обвиняйте, говорите о своих чувствах.',
            'Установите правила: договоритесь о режиме, уборке, гостях и т.д.',
            'Уважайте личные границы: дайте друг другу пространство.',
            'Обратитесь к куратору или администратору, если не удаётся решить самостоятельно.',
          ]),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600));
  }

  Widget _bulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 16))),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _numberedList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .asMap()
          .entries
          .map((entry) {
            final idx = entry.key + 1;
            final text = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$idx. ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
                ],
              ),
            );
          })
          .toList(),
    );
  }
}
