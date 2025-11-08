import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Этот класс наследуется от ChangeNotifier, чтобы оповещать виджеты
// об изменениях состояния.
class UdpService extends ChangeNotifier {
  RawDatagramSocket? _udp;
  Timer? _searchTimer; // Переменная для таймера
  String? curIP;
  String? brIP;
  bool found = false;
  bool searchF = false;
  bool configRequestedForCurrentIp = false;
  bool _isFirstSearchDone = false; // Флаг первого запуска
  int parseMode = 0;
  int port = 8888;
  final String _subNetMaskKey = 'saved_subnet_mask';
  final String _curIpKey = 'saved_cur_ip'; // Ключ для сохранения текущего IP
  List<String> ips = [];

  // Состояние UI-элементов
  String ledsText = "";
  bool powerValue = false;
  int briValue = 0;
  bool autoValue = false;
  bool rndValue = false;
  int prdValue = 0;
  bool offTValue = false;
  int offSValue = 0;
  bool favValue = false;
  int sclValue = 0;
  int spdValue = 0;
  int currentEffectIndex = 0;

  // Getter для безопасного доступа к списку IP-адресов
  List<String> get foundIps => ips;

  // Добавим Future, чтобы виджеты могли ждать загрузки
  Future<String> get curIp async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_curIpKey) ?? '';
  }

  // Метод для загрузки маски подсети
  Future<String> loadSubNetMask() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subNetMaskKey) ?? '255.255.255.0';
  }

  // Метод для сохранения маски подсети
  Future<void> saveSubNetMask(String subnetmask) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subNetMaskKey, subnetmask);
  }

  Future<void> initSearch() async {
    if (_isFirstSearchDone) {
      return;
    }
    await startSearch();
    _isFirstSearchDone = true;
  }

  // Метод для сохранения текущего IP
  Future<void> saveCurIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_curIpKey, ip);
    if (curIP != ip) {
      // Если IP действительно меняется
      curIP = ip;
      configRequestedForCurrentIp =
          false; // Сбрасываем флаг: для нового IP конфиг еще не запрашивали
      notifyListeners();
    }
  }

  // Метод для получения локального IP-адреса
  Future<String> getLocalIpAddress() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          return addr.address;
        }
      }
    }
    return "192.168.1.11";
  }

  // Метод для запуска поиска
  Future<void> startSearch() async {
    String? oldCurIP = curIP;
    final localIp = await getLocalIpAddress();
    final ipv4 = localIp.split('.').map(int.parse).toList();
    final maskString = await loadSubNetMask();
    final mask = maskString.split('.').map(int.parse).toList();

    brIP = null;

    for (int i = 0; i < 4; i++) {
      brIP = (brIP ?? '') + (ipv4[i] | (mask[i] ^ 0xFF)).toString();
      if (i != 3) {
        brIP = (brIP ?? '') + '.';
      }
    }
    found = false;

    searchF = true;
    parseMode = 0;
    ips.clear();

    notifyListeners();

    curIP = brIP;

    if (_udp == null) {
      _udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udp!.broadcastEnabled = true;
      _listenUdp();
    }
    sendData([0]);
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(seconds: 2), () {
      searchF = false; // Устанавливаем FALSE только здесь

      if (oldCurIP != null && ips.contains(oldCurIP)) {
        curIP = oldCurIP;
      } else if (ips.isNotEmpty) {
        curIP = ips.first;
      } else {
        curIP = null;
      }
      if (curIP != null && ips.isNotEmpty) {
        requestCfg();
      }

      notifyListeners();
      // Если ответы были, то таймер просто ничего не делает,
      // так как он уже не актуален.
    });
  }

  // Метод для прослушивания UDP
  void _listenUdp() {
    _udp!.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = _udp!.receive();
        if (datagram != null) {
          _receive(datagram.data);
        }
      }
    });
  }

  // Метод для запроса конфигурации
  void requestCfg() {
    parseMode = 1;
    configRequestedForCurrentIp = true; // Устанавливаем флаг перед отправкой
    sendData([1]);
    //notifyListeners(); // Оповещаем UI, что флаг изменился
  }

  // Метод для отправки данных
  void sendData(List<int> data) {
    List<int> buf = [];
    // Заголовки добавляются в список, а не в Uint8List
    buf.addAll(utf8.encode('GT'));
    buf.addAll(data);
    _sendDataBytes(Uint8List.fromList(buf));
  }

  // Метод для отправки байтов
  void _sendDataBytes(Uint8List data) {
    if (curIP != null && !curIP!.startsWith('n') && _udp != null) {
      _udp!.send(data, InternetAddress(curIP!), port);
      Future.delayed(const Duration(milliseconds: 15), () {
        _udp!.send(data, InternetAddress(curIP!), port);
      });
    }
  }

  // Метод для приема данных
  void _receive(Uint8List ubuf) {
    if (ubuf.length < 2 ||
        ubuf[0] != 'G'.codeUnitAt(0) ||
        ubuf[1] != 'T'.codeUnitAt(0)) {
      return;
    }

    List<int> data = ubuf.sublist(2).toList();
    if (data.isEmpty) return;

    //if (parseMode != data[0]) return;

    switch (data[0]) {
      case 0:
        if (brIP != null && data.length > 1) {
          String ip =
              brIP!.substring(0, brIP!.lastIndexOf('.') + 1) +
              data[1].toString();

          if (!ips.contains(ip)) {
            /*if (found ==false){
              ips.clear();
            }*/
            ips.add(ip);
            found = true;

            //notifyListeners();
          }
        }
        break;

      case 1:
        if (data.length > 9) {
          ledsText = (data[1] * 100 + data[2]).toString();
          powerValue = data[3] != 0;
          briValue = data[4];
          autoValue = data[5] != 0;
          rndValue = data[6] != 0;
          prdValue = data[7];
          offTValue = data[8] != 0;
          offSValue = data[9];
          searchF = false;
          notifyListeners();
        }
        break;

      case 4:
        if (data.length > 3) {
          favValue = data[1] != 0;
          sclValue = data[2];
          spdValue = data[3];
          notifyListeners();
        }
        break;
    }
  }

  void updatePowerAndBrightness(bool power, int brightness) {
    // 1. Обновляем локальные переменные состояния
    powerValue = power;
    briValue = brightness;

    // 2. Формируем и отправляем UDP пакет(ы)
    List<int> dataToSendPower = [2, 1, power ? 1 : 0];
    List<int> dataToSendBrightness = [2, 2, brightness];

    sendData(dataToSendBrightness);
    // Добавим небольшую задержку между отправкой двух пакетов, если это нужно устройству
    Future.delayed(const Duration(milliseconds: 100), () {
      sendData(dataToSendPower);
    });

    // 3. Уведомляем UI об изменении состояния
    notifyListeners();
  }

  void sendTimerSettings(bool timerEnabled, int minutes) {
    // Убедимся, что минуты в безопасном диапазоне
    int safeMinutes = minutes.clamp(0, 240);

    // Формируем массив данных для отправки [протокол, state, minutes]
    List<int> dataToSendOffTimer = [2, 7, timerEnabled ? 1 : 0];
    List<int> dataToSendOffTimerValue = [2, 8, safeMinutes];
    sendData(dataToSendOffTimer);
    Future.delayed(const Duration(milliseconds: 100), () {
      sendData(dataToSendOffTimerValue);
    });
    // Обновляем локальное состояние и UI
    offTValue = timerEnabled;
    offSValue = safeMinutes;
    notifyListeners();
  }

  void forceNextEffect() {
    List<int> dataToSend = [2, 6];
    sendData(dataToSend);
  }

  void sendAutoSwitchState(bool state) {
    autoValue = state;
    List<int> dataToSend = [2, 3, state ? 1 : 0];
    sendData(dataToSend);
    notifyListeners();
  }

  void sendRandomState(bool state) {
    rndValue = state;
    List<int> dataToSend = [2, 4, state ? 1 : 0];
    sendData(dataToSend);
    notifyListeners();
  }

  void sendPeriod(int minutes) {
    prdValue = minutes.clamp(1, 10);
    List<int> dataToSend = [
      2,
      5,
      prdValue,
    ]; // Пример протокола [5, ID_Period, Minutes]
    sendData(dataToSend);
    notifyListeners();
  }

  void sendEffectNumber(int effectNumber) {
    int safeEffectNumber = effectNumber.clamp(0, 23);

    List<int> dataToSend = [4, 0, safeEffectNumber];
    sendData(dataToSend);

    currentEffectIndex = safeEffectNumber;
    notifyListeners();
  }

  void sendFavoriteState(bool isFavorite) {
    favValue = isFavorite;
    List<int> dataToSend = [
      4,
      1,
      isFavorite ? 1 : 0,
    ];
    sendData(dataToSend);
    notifyListeners();
  }

  // Метод для отправки скорости
  void sendSpeed(int speed) {
    spdValue = speed.clamp(0, 255);
    List<int> dataToSend = [
      4,
      3,
      spdValue,
    ];
    sendData(dataToSend);
    notifyListeners();
  }

  // Метод для отправки масштаба
  void sendScale(int scale) {
    sclValue = scale.clamp(0, 255);
    List<int> dataToSend = [
      4,
      2,
      sclValue,
    ];
    sendData(dataToSend);
    notifyListeners();
  }

  // Метод для закрытия сокета при уничтожении сервиса
  @override
  void dispose() {
    _udp?.close();
    super.dispose();
  }
}
