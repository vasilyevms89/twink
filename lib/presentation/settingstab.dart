import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twink/presentation/settingstab/ipselectorwidget.dart';
// import 'package:twink/presentation/settingstab/startsearchwidget.dart'; // Удален
import 'package:twink/presentation/settingstab/subnetmaskinputwidget.dart';
import 'package:twink/presentation/settingstab/ledamountwidget.dart';
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
    // Просто возвращаем Column напрямую
    return Column(
      // Выравнивание к верху, занимает минимальное пространство, необходимое детям
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch, // Для того чтобы виджеты занимали всю ширину
      children: [
        SubNetMaskInputWidget(initialValue: '192.168.110.1'),
        IpSelectorWidget(),

        Consumer<UdpService>(
          builder: (context, udpService, child) {
            // Если список найденных IP-адресов не пуст, показываем виджет
            if (udpService.ips.isNotEmpty) {
              return Column(

                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(),
                  LedAmountWidget(),
                  const Divider(),
                ],
              );
            } else {
              // В противном случае ничего не показываем
              return const SizedBox.shrink();
            }
          },
        ),


      ],
    );
  }
}