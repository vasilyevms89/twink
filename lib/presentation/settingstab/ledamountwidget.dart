import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:twink/services/udp_service.dart';

class LedAmountWidget extends StatefulWidget {
  const LedAmountWidget({super.key});

  @override
  State<LedAmountWidget> createState() => _LedAmountWidgetState();
}

class _LedAmountWidgetState extends State<LedAmountWidget> {
  static const int minLeds = 1;
  static const int maxLeds = 25599;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    // Добавляем слушатель к FocusNode для отправки данных, когда пользователь убирает фокус
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  // Метод, вызываемый при потере фокуса
  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Если фокус потерян (пользователь закончил ввод)
      _sendAmountToDevice(context);
    }
  }

  // Метод для обработки и отправки данных
  void _sendAmountToDevice(BuildContext context) {
    final udpService = Provider.of<UdpService>(context, listen: false);
    String value = _controller.text;
    int? amount = int.tryParse(value);

    // Логика валидации: гарантируем положительное целое число
    if (amount == null || amount < minLeds) {
      amount = minLeds;
      _controller.text = minLeds.toString(); // Обновляем UI, если нужно
    }
    if (amount > maxLeds) {
      amount = maxLeds;
      _controller.text = maxLeds.toString(); // Обновляем UI, если нужно
    }

    // Формирование и отправка массива
    int highByte = amount ~/ 100;
    int lowByte = amount % 100;
    List<int> dataToSend = [2, 0, highByte, lowByte];
    udpService.ledsText = _controller.text;
    udpService.sendData(dataToSend);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UdpService>(
      builder: (context, udpService, child) {
        final String currentLeds = udpService.ledsText;
        final bool isReadOnly = currentLeds.isEmpty;

        // Обновляем контроллер, если данные из сервиса изменились, пока виджет активен
        if (_controller.text != currentLeds) {
          _controller.text = currentLeds;
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode, // Привязываем FocusNode
            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
            readOnly: isReadOnly,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Количество светодиодов',
              hintText: isReadOnly ? 'Загрузка...' : 'Обычно 10 шт на метр',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            // onSubmitted вызывается при нажатии кнопки "Готово/Enter"
            onSubmitted: (value) {
              _sendAmountToDevice(context);
            },
            // onChanged теперь не отправляет данные, только валидирует ввод
            onChanged: (value) {
              int? amount = int.tryParse(value);
              if (amount == null || amount < minLeds) {
                // Просто показываем ошибку или игнорируем, не отправляем данные
              }
            },
          ),
        );
      },
    );
  }
}