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
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<UdpService>(context, listen: false).startSearch()
    );



  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SubNetMaskInputWidget(initialValue: '192.168.110.1'),
        LedAmountWidget(),
        Divider(),


          IpSelectorWidget(),


      ]
    );
  }
}
