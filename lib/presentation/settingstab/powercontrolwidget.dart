import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twink/services/udp_service.dart';

class PowerControlWidget extends StatefulWidget {
  const PowerControlWidget({super.key});

  @override
  State<PowerControlWidget> createState() => _PowerControlWidgetState();
}

class _PowerControlWidgetState extends State<PowerControlWidget> {
  // Константы для логики
  static const int minBrightness = 0;
  static const int midBrightness = 127;
  static const int maxBrightness = 255;

  @override
  Widget build(BuildContext context) {
    return Consumer<UdpService>(
      builder: (context, udpService, child) {
        // Текущие значения из сервиса
        bool currentPower = udpService.powerValue;
        int currentBrightness = udpService.briValue;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Управление питанием и яркостью',
              isDense: true,
            ),
            isEmpty: false, // Всегда есть что отобразить
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Питание:"),
                      Switch(
                        value: currentPower,
                        onChanged: (bool newPowerValue) {
                          // Логика 1: Если включаем питание, а яркость нулевая -> ставим середину
                          int brightnessToSend = currentBrightness;
                          if (newPowerValue == true &&
                              currentBrightness == minBrightness) {
                            brightnessToSend = midBrightness;
                          }


                          // Отправляем новое состояние в сервис
                          udpService.updatePowerAndBrightness(newPowerValue, brightnessToSend);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Яркость:"),
                      Expanded(
                        child: Slider(
                          value: currentBrightness.toDouble(),
                          min: minBrightness.toDouble(),
                          max: maxBrightness.toDouble(),
                          divisions: 255,
                          label: currentBrightness.round().toString(),
                          onChanged: (double newBrightnessDouble) {
                            int newBrightness = newBrightnessDouble.round();

                            // Логика 2: Если слайдер не в нуле, включаем питание
                            bool powerToSend = currentPower;
                            if (newBrightness > minBrightness &&
                                currentPower == false) {
                              powerToSend = true;
                            }
                            // Логика 3: Если слайдер в нуле, выключаем питание
                            else if (newBrightness == minBrightness &&
                                currentPower == true) {
                              powerToSend = false;
                            }

                            // Отправляем новое состояние в сервис

                            udpService.updatePowerAndBrightness(powerToSend, newBrightness);
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
