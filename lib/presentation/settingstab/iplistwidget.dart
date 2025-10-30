import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twink/services/udp_service.dart';

class IpListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UdpService>(
      builder: (context, udpService, child) {
        if (udpService.searchF) {
          return const CircularProgressIndicator();
        }
        return Column(
          children: udpService.ips.map((ip) => Text(ip)).toList(),
        );
      },
    );
  }
}