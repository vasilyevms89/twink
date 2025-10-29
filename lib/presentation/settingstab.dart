import 'package:flutter/material.dart';
import 'package:twink/classes/subnetmaskinput.dart';
import 'package:twink/classes/ledamount.dart';


class SKSettingsTab extends StatelessWidget {
  const SKSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IpAddressInput(initialValue: '192.168.110.1'),
        Text('Маска подсети'),
        Divider(),
          LedAmount(),
          Text('data'),


      ]
    );
  }
}
