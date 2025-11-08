import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twink/presentation/settingstab/ipselectorwidget.dart';
import 'package:twink/presentation/settingstab/subnetmaskinputwidget.dart';
import 'package:twink/presentation/settingstab/ledamountwidget.dart';
import 'package:twink/presentation/settingstab/powercontrolwidget.dart';
import 'package:twink/presentation/settingstab/offtimercontrolwidget.dart'; // Добавлен импорт
import 'package:twink/services/udp_service.dart';

class SKSettingsTab extends StatefulWidget {
  const SKSettingsTab({super.key});

  @override
  State<SKSettingsTab> createState() => _SKSettingsTabState();
}

class _SKSettingsTabState extends State<SKSettingsTab> {
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      Provider.of<UdpService>(context, listen: false).initSearch();
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // !!! ИСПОЛЬЗУЕМ ListView ДЛЯ РЕШЕНИЯ ПРОБЛЕМЫ С КЛАВИАТУРОЙ !!!
    return ListView(
      padding: const EdgeInsets.only(top: 8.0),
      children: [
        SubNetMaskInputWidget(initialValue: '192.168.110.1'),
        IpSelectorWidget(),
        // Consumer для условного отображения LedAmountWidget
        Consumer<UdpService>(
          builder: (context, udpService, child) {
            if (udpService.ips.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LedAmountWidget(),
                  const Divider(),
                  PowerControlWidget(),
                  OffTimerControlWidget(),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),


         // Ваш новый виджет
      ],
    );
  }
}