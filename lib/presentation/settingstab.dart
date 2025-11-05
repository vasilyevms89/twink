import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twink/presentation/settingstab/ipselectorwidget.dart';
import 'package:twink/presentation/settingstab/startsearchwidget.dart';
import 'package:twink/presentation/settingstab/subnetmaskinputwidget.dart';
import 'package:twink/presentation/settingstab/ledamountwidget.dart';
import 'package:twink/services/udp_service.dart';

class SKSettingsTab extends StatefulWidget {
  const SKSettingsTab({super.key});

  @override
  State<SKSettingsTab> createState() => _SKSettingsTabState();
}

class _SKSettingsTabState extends State<SKSettingsTab> {
  late final udpService = Provider.of<UdpService>(context, listen: false);

  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      // Вызываем initSearch только один раз
      Provider.of<UdpService>(context, listen: false).initSearch();
      _isInit = true; // Устанавливаем флаг, что инициализация прошла
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        // !!! ИСПРАВЛЕНИЕ: Выравниваем содержимое к началу !!!
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch, // Чтобы виджеты занимали всю ширину
        children: [
          SubNetMaskInputWidget(initialValue: '192.168.110.1'),
          LedAmountWidget(),
          const Divider(),
          IpSelectorWidget(),
        ],
      ),
    );
  }
}
