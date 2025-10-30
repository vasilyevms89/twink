import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LedAmountWidget extends StatefulWidget {
  const LedAmountWidget({super.key});

  @override
  State<LedAmountWidget> createState() => _LedAmountWidgetState();
}

class _LedAmountWidgetState extends State<LedAmountWidget> {
  late final TextEditingController _controller;
  final String _ledAmountKey =
      'led_amount'; // Ключ для сохранения в SharedPreferences

  @override
  void initState() {
    super.initState();
    // 2. Инициализация контроллера с начальным значением
    _controller = TextEditingController(text: '25');
    _loadLedAmount(); // Загрузка сохранённого количества светодиодов
  }

  Future<void> _loadLedAmount() async {
    final prefs = await SharedPreferences.getInstance();
    final int ledAmount = prefs.getInt(_ledAmountKey) ?? 50;
    _controller.text = '$ledAmount';
  }

  // Асинхронная функция для сохранения значения в SharedPreferences
  Future<void> _saveLedAmount() async {
    final prefs = await SharedPreferences.getInstance();
    // Безопасное преобразование и сохранение
    final int ledAmount = int.tryParse(_controller.text) ?? 50;
    await prefs.setInt(_ledAmountKey, ledAmount);
  }

  @override
  void dispose() {
    // 3. Очистка контроллера при удалении виджета
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Количество светодиодов',
          hintText: 'Обычно 10 шт на метр',
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          _saveLedAmount(); // Сохранение при каждом изменении
        },
      ),
    );
  }
}
