import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:twink/services/udp_service.dart';

class OffTimerControlWidget extends StatefulWidget {
  const OffTimerControlWidget({super.key});

  @override
  State<OffTimerControlWidget> createState() => _OffTimerControlWidgetState();
}

class _OffTimerControlWidgetState extends State<OffTimerControlWidget> {
  static const int minMinutes = 1;
  static const int maxMinutes = 240;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  // Отправка данных при потере фокуса или подтверждении
  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _sendTimerSettings(context);
    }
  }

  void _sendTimerSettings(BuildContext context) {
    final udpService = Provider.of<UdpService>(context, listen: false);

    // Валидация введенного значения
    int? minutes = int.tryParse(_controller.text);
    if (minutes == null || minutes < minMinutes) {
      minutes = minMinutes;
    } else if (minutes > maxMinutes) {
      minutes = maxMinutes;
    }

    // Отправляем текущее состояние переключателя и проверенное значение минут
    udpService.sendTimerSettings(udpService.offTValue, minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UdpService>(
      builder: (context, udpService, child) {
        bool timerEnabled = udpService.offTValue;
        int currentMinutes = udpService.offSValue;

        // Обновляем контроллер, если данные из сервиса меняются
        if (_controller.text != currentMinutes.toString() && _focusNode.hasFocus == false) {
          _controller.text = currentMinutes.toString();
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Таймер автовыключения',
              isDense: true,
            ),
            isEmpty: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Таймер активен:"),
                  Switch(
                    value: timerEnabled,
                    onChanged: (bool newValue) {
                      // При переключении свитча, отправляем новое состояние и текущие минуты
                      udpService.sendTimerSettings(newValue, currentMinutes);
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                      decoration: const InputDecoration(
                        labelText: 'Минуты',
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3), // Ограничиваем ввод до 3 цифр (до 240)
                      ],
                      onSubmitted: (_) => _sendTimerSettings(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}