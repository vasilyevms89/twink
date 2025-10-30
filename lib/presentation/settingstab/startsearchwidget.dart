import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twink/services/udp_service.dart';

class StartSearchWidget extends StatelessWidget {
  const StartSearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final udpService = Provider.of<UdpService>(context, listen: false);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            udpService.startSearch();
          },
          child: const Text('Начать поиск'),
        ),
        ElevatedButton(
          onPressed: () {
            udpService.requestCfg();
          },
          child: const Text('Запросить конфигурацию'),
        ),
      ],
    );
  }
}