import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twink/services/udp_service.dart';

class IpSelectorWidget extends StatelessWidget {
  const IpSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UdpService>(
      builder: (context, udpService, child) {
        // --- Логика запроса конфигурации (при старте виджета) ---
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!udpService.configRequestedForCurrentIp && udpService.ips.isNotEmpty) {
            String targetIp = udpService.curIP ?? udpService.ips.first;
            if (udpService.curIP == null) {
              udpService.saveCurIp(targetIp).then((_) {
                udpService.requestCfg();
              });
            } else {
              udpService.requestCfg();
            }
          }
        });

        // --- Подготовка значения для DropdownButton ---
        String? currentValue = udpService.curIP;

        // Гарантируем, что currentValue всегда содержит IP из списка, если список не пуст
        if (udpService.ips.isNotEmpty) {
          if (currentValue == null || !udpService.ips.contains(currentValue)) {
            currentValue = udpService.ips.first;
          }
        } else {
          currentValue = null; // Если список пуст, value должен быть null
        }

        // --- Визуальное оформление в стиле TextField ---
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'IP адрес устройства', // Это будет ваш единственный хинт/лейбл
              suffixIcon: udpService.searchF
                  ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: const CircularProgressIndicator(strokeWidth: 2.0),
              )
                  : IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  udpService.startSearch();
                },
              ),
            ),
            isEmpty: currentValue == null, // InputDecorator использует это для управления лейблом
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                isExpanded: true,
                // !!! УДАЛИЛИ ХИНТ !!!
                // hint: const Text("Устройства не найдены"),

                onChanged: (String? newValue) {
                  if (newValue != null && newValue != udpService.curIP) {
                    udpService.saveCurIp(newValue).then((_) {
                      udpService.requestCfg();
                    });
                  }
                },

                items: udpService.ips.map<DropdownMenuItem<String>>((String ip) {
                  return DropdownMenuItem<String>(value: ip, child: Text(ip));
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}