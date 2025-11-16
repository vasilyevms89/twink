import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twink/presentation/effectstab/effectcontrolsliderwidget.dart';
import 'package:twink/services/udp_service.dart';
import 'package:twink/utils/effect_constants.dart';

class EffectSelectorWidget extends StatefulWidget {
  const EffectSelectorWidget({super.key});

  @override
  State<EffectSelectorWidget> createState() => _EffectSelectorWidgetState();
}

class _EffectSelectorWidgetState extends State<EffectSelectorWidget> {
  int _calculateControllerEffectNumber(int effectTypeId, int paletteId) {
    // Формула: effectNumber = paletteId + (effectTypeId * 12)
    return paletteId + (effectTypeId * palettes.length);
  }

  EffectType _getEffectTypeFromControllerValue(int controllerValue) {
    // Используем palettes.length
    int typeId = controllerValue ~/ palettes.length;
    // Используем effectTypes.length
    return effectTypes.firstWhere(
      (e) => e.id == typeId.clamp(0, effectTypes.length - 1),
    );
  }

  Palette _getPaletteFromControllerValue(int controllerValue) {
    // Используем palettes.length
    int paletteId = controllerValue % palettes.length;
    // Используем palettes.length
    return palettes.firstWhere(
      (p) => p.id == paletteId.clamp(0, palettes.length - 1),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<UdpService>(
      builder: (context, udpService, child) {
        final int maxIndex = (effectTypes.length * palettes.length) - 1;
        final int currentControllerValue = udpService.currentEffectIndex.clamp(0, maxIndex);

        EffectType selectedEffectType = _getEffectTypeFromControllerValue(currentControllerValue);
        Palette selectedPalette = _getPaletteFromControllerValue(currentControllerValue);

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Выбор эффекта и палитры',
              isDense: true,
            ),
            isEmpty: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Тип эффекта:"),
                      // !!! ОБЕРТЫВАЕМ В SIZEDBOX ДЛЯ ОДИНАКОВОЙ ШИРИНЫ !!!
                      SizedBox(
                        width: 220, // Задаем фиксированную ширину
                        child: DropdownButton<EffectType>(
                          value: selectedEffectType,
                          isExpanded: true, // Растягивает DropdownButton на всю ширину SizedBox
                          items: effectTypes.map((EffectType type) {
                            return DropdownMenuItem<EffectType>(
                              value: type,
                              child: Text(type.name),
                            );
                          }).toList(),
                          onChanged: (EffectType? newValue) {
                            if (newValue != null) {
                              int newControllerValue = _calculateControllerEffectNumber(newValue.id, selectedPalette.id);

                              udpService.sendEffectNumber(newControllerValue);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Палитра:"),
                      // !!! ОБЕРТЫВАЕМ В SIZEDBOX ДЛЯ ОДИНАКОВОЙ ШИРИНЫ !!!
                      SizedBox(
                        width: 220, // Используем ту же ширину
                        child: DropdownButton<Palette>(
                          value: selectedPalette,
                          isExpanded: true, // Растягивает DropdownButton на всю ширину SizedBox
                          items: palettes.map((Palette palette) {
                            return DropdownMenuItem<Palette>(
                              value: palette,
                              child: Text(palette.name),
                            );
                          }).toList(),
                          onChanged: (Palette? newValue) {
                            if (newValue != null) {
                              int newControllerValue = _calculateControllerEffectNumber(selectedEffectType.id, newValue.id);
                              udpService.sendEffectNumber(newControllerValue);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  // !!! ВСТАВЛЯЕМ ДОЧЕРНИЙ ВИДЖЕТ СЮДА !!!
                  const EffectControlSlidersWidget(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
