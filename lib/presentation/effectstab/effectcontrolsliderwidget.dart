import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twink/services/udp_service.dart';

class EffectControlSlidersWidget extends StatelessWidget {
  const EffectControlSlidersWidget({super.key});

  static const int minVal = 0;
  static const int maxVal = 255;

  @override
  Widget build(BuildContext context) {
    return Consumer<UdpService>(
      builder: (context, udpService, child) {
        bool isFavorite = udpService.favValue;
        int currentScale = udpService.sclValue;
        int currentSpeed = udpService.spdValue;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Настройка скорости и масштаба',
              isDense: true,
            ),
            isEmpty: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Переключатель "Избранное"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Любимый эффект:"),
                      Switch(
                        value: isFavorite,
                        onChanged: (bool newValue) {
                          udpService.sendFavoriteState(newValue);
                        },
                      ),
                    ],
                  ),

                  // Слайдер Скорости
                  Row(
                    children: [
                      const Text("Скорость:"),
                      Expanded(
                        child: Slider(
                          value: currentSpeed.toDouble(),
                          min: minVal.toDouble(),
                          max: maxVal.toDouble(),
                          divisions: 255,
                          label: currentSpeed.round().toString(),
                          onChanged: (double newValue) {
                            udpService.sendSpeed(newValue.round());
                          },
                        ),
                      ),
                      Text(currentSpeed.toString()),
                    ],
                  ),

                  // Слайдер Масштаба
                  Row(
                    children: [
                      const Text("Масштаб:"),
                      Expanded(
                        child: Slider(
                          value: currentScale.toDouble(),
                          min: minVal.toDouble(),
                          max: maxVal.toDouble(),
                          divisions: 255,
                          label: currentScale.round().toString(),
                          onChanged: (double newValue) {
                            udpService.sendScale(newValue.round());
                          },
                        ),
                      ),
                      Text(currentScale.toString()),
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