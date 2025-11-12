import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

// import 'package:image/image.dart' as img; // Для обработки изображений
import 'package:twink/utils/image_processor.dart';
import 'package:twink/services/udp_service.dart';

class CalibrationTab extends StatefulWidget {
  const CalibrationTab({super.key});

  //60
  static const int X_GRID_SIZE = 100; // Размер сетки по X

  @override
  State<CalibrationTab> createState() => _CalibrationTabState();
}

class _CalibrationTabState extends State<CalibrationTab> {
  CameraController? _controller;
  ImageProcessor? _imageProcessor;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  bool _permissionDenied = false; //
  bool _isCalibrating = false;
  bool _isCapturing = false; // Добавлен флаг для управления съемкой
  int _calibCount = 0;
  Timer? _calibrationTimer;
  int _currentMaxX = 0;
  int _currentMaxY = 0;
  int maxX = 0;
  int maxY = 0;
  Offset? _ledPosition;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _requestCameraPermissionAndInitialize();
  }

  Future<void> _requestCameraPermissionAndInitialize() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeCamera();
    } else {
      // Обработка отказа в разрешении: обновляем состояние
      setState(() {
        _permissionDenied = true;
        _isCameraInitialized = false; // На всякий случай
      });
      // Опционально: можно открыть настройки приложения, если пользователь нажал "Никогда не спрашивать"
      /*if (status.isPermanentlyDenied) {
        openAppSettings();
      }*/
    }
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(
        cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      try {
        await _controller!.initialize();
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
      } on CameraException catch (e) {
        print("Ошибка инициализации камеры: $e");
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _calibrationTimer?.cancel();
    super.dispose();
  }

  Future<void> _startCalibration() async {
    if (!_isCameraInitialized ||
        _isCalibrating ||
        _controller == null ||
        _controller!.value.isTakingPicture ||
        _isCapturing)
      return;

    final udpService = Provider.of<UdpService>(context, listen: false);

    setState(() {
      _isCalibrating = true;
      _calibCount = 0;
    });
    try {
      udpService.sendStartCalibration(); // Отправляем команду 3, 0
      await Future.delayed(const Duration(milliseconds: 2000));
      if (_controller == null || _controller!.value.isTakingPicture) return;
      _isCapturing = true;
      XFile baseFile = await _controller!.takePicture();
      _isCapturing = false;
      Uint8List baseImageBytes = await baseFile.readAsBytes();

      _imageProcessor = ImageProcessor(CalibrationTab.X_GRID_SIZE);
      _imageProcessor!.captureBaseBrightness(baseImageBytes);
      _performCalibrationStep(udpService);
    } catch (e) {
      print("Ошибка при калибровке: $e");
      _stopCalibration();
    }
  }

  Future<void> _performCalibrationStep(UdpService udpService) async {
    // 0. Начальные проверки: если не калибруется, снимает или контроллер не готов - выходим.
    if (!_isCalibrating ||
        _isCapturing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    // Важно: Повторная проверка после задержки, так как состояние могло измениться
    // (пользователь мог нажать Stop во время задержки).
    if (!_isCalibrating || _controller == null || _imageProcessor == null) {
      // Если состояние изменилось, аккуратно вызываем stop и выходим.
      _stopCalibration();
      return;
    }

    try {
      // 1. Захват кадра
      _isCapturing = true;
      XFile file = await _controller!.takePicture();
      _isCapturing = false;

      // Чтение байтов (здесь нативный буфер освобождается плагином Camera)
      Uint8List imageBytes = await file.readAsBytes();

      // 2. Обработка изображения на Dart.
      // Проверка на null уже была выше, но здесь для надежности
      if (_imageProcessor == null) {
        _stopCalibration();
        return;
      }

      CalibrationResult result = _imageProcessor!.processFrameForDelta(
        imageBytes,
      );
      final int totalLeds = int.tryParse(udpService.ledsText) ?? 1;

      // 3. Обновление UI и состояния
      setState(() {
        // Защита от Null внутри setState
        _imageSize ??= Size(
          // Используем оператор ??= для установки значения, если оно null
          result.imageWidth.toDouble(),
          result.imageHeight.toDouble(),
        );

        final double sizeX = _imageSize!.width / CalibrationTab.X_GRID_SIZE;
        final double sizeY = _imageSize!.height / (_imageSize!.height ~/ sizeX);

        _ledPosition = Offset(
          result.maxX * sizeX + sizeX / 2, // Центр ячейки X
          result.maxY * sizeY + sizeY / 2, // Центр ячейки Y
        );
        _currentMaxX = result.maxX;
        _currentMaxY = result.maxY;
        _calibCount++; // Увеличиваем счетчик после обработки и отправки
      });
      // Задержка перед выполнением шага (400 мс между снимками),
      // чтобы дать системе "передохнуть" перед следующим запросом кадра.
      await Future.delayed(const Duration(milliseconds: 200));
      // 4. Отправка данных UDP (не блокирует)
      udpService.sendCalibrationStepData(
        totalLeds,
        _calibCount - 1, // Отправляем текущий счетчик
        result.maxX,
        result.maxY,
      );

      // 5. Проверка завершения
      if (_calibCount >= totalLeds) {
        await Future.delayed(const Duration(milliseconds: 1000));
        _stopCalibration(); // Завершаем процесс
        return;
      }

      // 6. Рекурсивный вызов для следующего шага
      _performCalibrationStep(udpService);
    } catch (e) {
      // Единый блок обработки ошибок
      print("Ошибка при калибровке: $e");
      _stopCalibration();
    }
  }

  void _stopCalibration() {
    final udpService = Provider.of<UdpService>(context, listen: false);


    udpService.sendStopCalibration(); // Отправляем команду 3, 2
    setState(() {
      _isCalibrating = false;
      _isCapturing = false; // Обязательно сбросить флаг
      _calibCount = 0;
      _imageProcessor = null; // Очищаем процессор
      _ledPosition = null; // <-- Сброс позиции при остановке
      _imageSize = null; // <-- Сброс размера
      _currentMaxX = 0; // <-- Сброс
      _currentMaxY = 0; // <-- Сброс
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<UdpService>(
      builder: (context, udpService, child) {
        if (udpService.ips.isEmpty) {
          return const Center(
            child: Text(
              "Устройства не найдены",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        // Проверяем, было ли отказано в разрешении
        if (_permissionDenied) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Необходимо предоставить разрешение на камеру для калибровки.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Кнопка для открытия настроек приложения
                      openAppSettings();
                    },
                    child: const Text("Открыть настройки разрешений"),
                  ),
                ],
              ),
            ),
          );
        }

        // Если разрешения в порядке, но инициализация еще идет
        if (!_isCameraInitialized ||
            _controller == null ||
            !_controller!.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        // Основной UI с превью камеры
        return Column(
          children: [
            Expanded(
              // Используем LayoutBuilder для получения размера доступного пространства
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // 1. Фон (CameraPreview)
                      Positioned.fill(child: CameraPreview(_controller!)),

                      // 2. Оверлей с красным контуром, если позиция найдена и идет калибровка
                      if (_ledPosition != null &&
                          _imageSize != null &&
                          _isCalibrating)
                        Positioned(
                          // Смещение 12.5 (половина от 25px размера) для центрирования
                          left:
                              (_ledPosition!.dx / _imageSize!.width) *
                                  constraints.maxWidth -
                              12.5,
                          top:
                              (_ledPosition!.dy / _imageSize!.height) *
                                  constraints.maxHeight -
                              12.5,
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red, // Цвет контура
                                width: 3, // Толщина контура
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                // Используем Column для размещения кнопок и текста координат
                children: [
                  Row(
                    // Строка для кнопок и прогресса
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          onPressed: _isCalibrating ? null : _startCalibration,
                          child: const Text("Старт"),
                        ),
                      ),
                      Builder(
                        // Вычисление и отображение процента
                        builder: (context) {
                          final int totalLeds =
                              int.tryParse(udpService.ledsText) ?? 1;
                          final int progressPercent = totalLeds > 0
                              ? ((_calibCount / totalLeds) * 100).toInt()
                              : 0;
                          return Text('Выполнено: $progressPercent%');
                        },
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          onPressed: _isCalibrating ? _stopCalibration : null,
                          child: const Text("Стоп"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Небольшой отступ
                  // Новый виджет с координатами, виден только во время калибровки
                  if (_isCalibrating)
                    Text('Координаты: X=$_currentMaxX, Y=$_currentMaxY'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
/*Дополнительный важный шаг (Capabilities)
Просто добавления ключа в Info.plist может быть недостаточно. Вам также нужно включить опцию "Networking" в настройках проекта Xcode.
Откройте ваш проект в Xcode: open ios/Runner.xcworkspace.
В навигаторе проекта слева выберите Runner.
Выберите вкладку Signing & Capabilities.
Нажмите кнопку + Capability в левом верхнем углу.
Найдите и дважды кликните по "Background Modes".
Установите галочку напротив "Local Networking".
После выполнения этих шагов вы будете уверены, что ваше iOS-приложение имеет все необходимые разрешения и настройки для работы с камерой и широковещательными UDP-сокетами.*/