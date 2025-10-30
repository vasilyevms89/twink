import 'package:flutter/material.dart';
import 'package:twink/presentation/settingstab/iplistwidget.dart';
import 'package:twink/presentation/settingstab/startsearchwidget.dart';
import 'package:twink/presentation/settingstab/subnetmaskinputwidget.dart';
import 'package:twink/presentation/settingstab/ledamountwidget.dart';


class SKSettingsTab extends StatelessWidget {
  const SKSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SubNetMaskInputWidget(initialValue: '192.168.110.1'),
        Text('Маска подсети'),
        Divider(),
          LedAmountWidget(),
          Text('data'),
          IpListWidget(),
          StartSearchWidget(),

      ]
    );
  }
}
