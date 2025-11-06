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
        // Вызывается после построения кадра, чтобы не менять состояние во время build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Если есть текущий IP и для него еще не запрашивали конфигурацию
          if (udpService.curIP != null &&
              !udpService.configRequestedForCurrentIp) {
            udpService.requestCfg();
          } else if (udpService.curIP == null && udpService.ips.isNotEmpty) {
            // Если curIP вообще не установлен, устанавливаем первый и запрашиваем конфиг
            udpService.saveCurIp(udpService.ips.first).then((_) {
              udpService.requestCfg();
            });
          }
        });

        // --- Подготовка значения для DropdownButton ---
        String? currentValue = udpService.curIP;
        final isListEmpty = udpService.ips.isEmpty;

        // Если текущего IP нет или он не в списке, и список не пуст, берем первый IP
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
              border: const OutlineInputBorder(),
              labelText: 'IP адрес устройства',
              // Это ваш основной лейбл/хинт
              isDense: true,
              // Делает поле ввода более компактным
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              // Отступы
              // Кнопка поиска / Индикатор загрузки
              suffixIcon: udpService.searchF
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        // Кнопка принудительного сканирования
                        udpService.startSearch();
                      },
                    ),
            ),
            isEmpty: isListEmpty,
            // InputDecorator использует это для управления лейблом
            child: DropdownButtonHideUnderline(
              child: isListEmpty
                  ? Container() // !!! Используем пустой контейнер, чтобы не конфликтовать с labelText !!!
                  : DropdownButton<String>(
                      value: currentValue,
                      isExpanded: true,
                      // Хинт не нужен, т.к. его роль выполняет labelText в InputDecorator
                      onChanged: (String? newValue) {
                        if (newValue != null && newValue != udpService.curIP) {
                          udpService.saveCurIp(newValue);
                          udpService
                              .requestCfg(); // Перезапрос конфига при смене IP
                        }
                      },
                      items: udpService.ips.map<DropdownMenuItem<String>>((
                        String ip,
                      ) {
                        return DropdownMenuItem<String>(
                          value: ip,
                          child: Text(ip),
                        );
                      }).toList(),
                    ),
            ),
          ),
        );
      },
    );
  }
}
