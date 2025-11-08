import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twink/services/udp_service.dart';

class EffectGeneralSettingsWidget extends StatelessWidget {
  const EffectGeneralSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UdpService>(
      builder: (context, udpService, child) {
        bool autoSwitchEnabled = udpService.autoValue;
        bool randomEnabled = udpService.rndValue;
        int period = udpService.prdValue;

        int currentPeriod = (period >= 1 && period <= 10) ? period : 1;
        List<int> periodOptions = List.generate(10, (index) => index + 1);

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Общие настройки эффектов',
              isDense: true,
            ),
            isEmpty: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Кнопка принудительного переключения эффектов
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        udpService.forceNextEffect(); // Отправка отдельного пакета
                      },
                      icon: const Icon(Icons.skip_next),
                      label: const Text("Переключить эффект"),
                    ),
                  ),
                  // ... (Switch и DropdownButton вызывают новые методы сервиса) ...
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Автоматическое переключение:"),
                      Switch(
                        value: autoSwitchEnabled,
                        onChanged: (bool newValue) {
                          udpService.sendAutoSwitchState(newValue); // Отправка отдельного пакета
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Случайный выбор эффекта:"),
                      Switch(
                        value: randomEnabled,
                        onChanged: (bool newValue) {
                          udpService.sendRandomState(newValue); // Отправка отдельного пакета
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Переключать через:"),
                      SizedBox(
                        width: 100,
                        child: DropdownButton<int>(
                          value: currentPeriod,
                          items: periodOptions.map<DropdownMenuItem<int>>((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text("$value мин"),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              udpService.sendPeriod(newValue); // Отправка отдельного пакета
                            }
                          },
                        ),
                      ),
                    ],
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