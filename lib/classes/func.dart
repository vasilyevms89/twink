import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// Объявим переменные, которые используются в функциях.
// Замените "subnet" и "dropIP" на реальные объекты вашего UI.
// KetaiNet.getIP() заменен на получение IP-адреса хоста.
// udp заменен на RawDatagramSocket.

RawDatagramSocket? udp;
String? curIP;
String? brIP;
bool found = false;
bool searchF = false;
int parseMode = 0;
int port = 8080; // Используйте ваш порт
final String _subNetMaskKey = 'saved_subnet_mask'; // Ключ для сохранения в SharedPreferences
List<String> ips = [];

Future<String> loadSubNetMask() async {
  final prefs = await SharedPreferences.getInstance();
  final savedIp = prefs.getString(_subNetMaskKey);

  // Если есть сохранённый IP-адрес, используем его
  if (savedIp != null) {
    return savedIp;
  } else {
    // Иначе используем значение по умолчанию
    return '255.255.255.0';
  }
}

// Асинхронная функция для сохранения значения в SharedPreferences
Future<void> saveSubNetMask(String subnetmask) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_subNetMaskKey, subnetmask);
}
// Предполагается, что у вас есть какой-то способ получать UI-данные
// или управлять ими. Например, text-контроллер.
// String subnetText;

// Функция для получения локального IP-адреса.
// В отличие от Ketai, в Dart это асинхронная операция.
Future<String> getLocalIpAddress() async {
  for (var interface in await NetworkInterface.list()) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4) {
        return addr.address;
      }
    }
  }
  return "127.0.0.1";
}

Future<void> startSearch() async {
  final localIp = await getLocalIpAddress();
  final ipv4 = localIp.split('.').map(int.parse).toList();
  // final mask = subnetText.split('.').map(int.parse).toList(); // Если у вас есть subnetText
  final String maskString = await loadSubNetMask(); // Пример
  final mask = maskString.split('.').map(int.parse).toList();
  found = false;
  curIP = "";
  brIP = "";

  for (int i = 0; i < 4; i++) {
    brIP = (brIP ?? '') + (ipv4[i] | (mask[i] ^ 0xFF)).toString();
    if (i != 3) {
      brIP = (brIP ?? '') + '.';
    }
  }

  searchF = true;
  parseMode = 0;

  // выводим однократно
  ips.clear();
  ips.add("searching...");
  // dropIP.selected = 0; // Зависит от вашего UI
  // ui(); // Зависит от вашего UI
  ips.clear();

  curIP = brIP;

  udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

  sendData([0]);
  // actionTmr = DateTime.now().millisecondsSinceEpoch;
}

void requestCfg() {
  parseMode = 1;
  final buf = [1];
  sendData(buf);
}

void sendData(List<int> data) {
  List<int> buf = utf8.encode('GT');
  buf.addAll(data);
  sendDataBytes(Uint8List.fromList(buf));
}

void sendDataBytes(Uint8List data) {
  if (curIP != null && !curIP!.startsWith('n') && udp != null) {
    udp!.send(data, InternetAddress(curIP!), port);
    Future.delayed(Duration(milliseconds: 15), () {
      udp!.send(data, InternetAddress(curIP!), port);
    });
  }
}