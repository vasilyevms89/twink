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

  static const int X_GRID_SIZE = 60; // Размер сетки по X

  @override
  State<CalibrationTab> createState() => _CalibrationTabState();
}

class _CalibrationTabState extends State<CalibrationTab> {
  CameraController? _controller;
  ImageProcessor? _imageProcessor;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  bool _isCalibrating = false;
  int _calibCount = 0;
  Timer? _calibrationTimer;
  int maxX = 0, maxY = 0; // Координаты найденного светодиода

  @override
  void initState() {
    super.initState();
    _requestCameraPermissionAndInitialize();
  }

  Future<void> _requestCameraPermissionAndInitialize() async {
    if (await Permission.camera.request().isGranted) {
      _initializeCamera();
    } else {
      // Обработка отказа в разрешении
      setState(() {
        // Показать сообщение об ошибке
      });
    }
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
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
        _controller!.value.isTakingPicture)
      return;

    final udpService = Provider.of<UdpService>(context, listen: false);

    setState(() {
      _isCalibrating = true;
      _calibCount = 0;
    });

    udpService.sendStartCalibration(); // Отправляем команду 3, 0
    await Future.delayed(const Duration(milliseconds: 2000));
    XFile baseFile = await _controller!.takePicture();
    Uint8List baseImageBytes = await baseFile.readAsBytes();

    _imageProcessor = ImageProcessor(CalibrationTab.X_GRID_SIZE);
    _imageProcessor!.captureBaseBrightness(baseImageBytes);
    // Запускаем таймер для пошаговой калибровки (как в Processing 400 мс)
    _calibrationTimer = Timer.periodic(const Duration(milliseconds: 400), (
      timer,
    ) async {
      try {
        // 1. Захват кадра
        XFile file = await _controller!.takePicture();
        Uint8List imageBytes = await file.readAsBytes();

        // 2. Обработка изображения на Dart (ваша логика)
        CalibrationResult result = _imageProcessor!.processFrameForDelta(
          imageBytes,
        );
        final int totalLeds = int.tryParse(udpService.ledsText) ?? 1;

        if (_calibCount > totalLeds) {
          _stopCalibration();
          // Отправляем финальные данные (Команда 3, 2)
          udpService.sendCalibrationStepData(
            totalLeds,
            _calibCount,
            result.maxX,
            result.maxY,
          );
          return;
        }
        // 3. Отправка шага калибровки
        udpService.sendCalibrationStepData(
          totalLeds,
          _calibCount,
          result.maxX,
          result.maxY,
        );

        setState(() {
          _calibCount++;
        });


      } catch (e) {
        print("Ошибка при калибровке: $e");
        _stopCalibration();
      }
    });
  }

  void _stopCalibration() {
    final udpService = Provider.of<UdpService>(context, listen: false);
    _calibrationTimer?.cancel();
    udpService.sendStopCalibration(); // Отправляем команду 3, 2
    setState(() {
      _isCalibrating = false;
      _calibCount = 0;
      _imageProcessor = null; // Очищаем процессор
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UdpService>(
      builder: (context, udpService, child) {
        if (udpService.ips.isEmpty) {
          return const Center(child: Text("Не найдены устройства"));
        }

        if (!_isCameraInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(
              child: CameraPreview(_controller!), // Виджет предпросмотра камеры
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: _isCalibrating ? null : _startCalibration,
                    child: const Text("Start"),
                  ),
                  Text('Progress: ${_calibCount}%'),
                  ElevatedButton(
                    onPressed: _isCalibrating ? _stopCalibration : null,
                    child: const Text("Stop"),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
