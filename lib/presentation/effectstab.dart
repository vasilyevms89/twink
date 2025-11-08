import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twink/presentation/effectstab/effectcontrolsliderwidget.dart';
import 'package:twink/presentation/effectstab/effectselectorwidget.dart';
import 'package:twink/services/udp_service.dart';
import 'package:twink/presentation/effectstab/effectgeneralsettingswidget.dart';

class EffectsTab extends StatelessWidget {
  const EffectsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Используем Consumer для проверки наличия IP-адресов
    return Consumer<UdpService>(
      builder: (context, udpService, child) {
        if (udpService.ips.isEmpty) {
          // Если устройств нет, показываем центрированный текст
          return const Center(
            child: Text(
              "Не найдены устройства",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        } else {
          // Если устройства есть, показываем настройки
          return ListView(
            padding: const EdgeInsets.only(top: 8.0),
            children: const [
              EffectGeneralSettingsWidget(),
              EffectSelectorWidget(),
              EffectControlSlidersWidget(),
            ],
          );
        }
      },
    );
  }
}