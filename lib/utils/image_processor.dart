import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'dart:math';

class CalibrationResult {
  final int maxX;
  final int maxY;
  final int calibCount;

  CalibrationResult({required this.maxX, required this.maxY, required this.calibCount});
}

class ImageProcessor {
  final int X_GRID_SIZE;
  List<int>? _baseBrightnessMap; // Базовая карта яркости (состояние)

  ImageProcessor(this.X_GRID_SIZE);

  // Метод для создания карты яркости из изображения
  List<int> _makeBrightnessMap(img.Image image) {
    final int size = image.width ~/ X_GRID_SIZE;
    final int Y_GRID_SIZE = image.height ~/ size;
    List<int> brightnessMap = List.filled(X_GRID_SIZE * Y_GRID_SIZE, 0);

    for (int y = 0; y < Y_GRID_SIZE; y++) {
      for (int x = 0; x < X_GRID_SIZE; x++) {
        int sum = 0;
        for (int yy = 0; yy < size; yy++) {
          for (int xx = 0; xx < size; xx++) {
            final pixel = image.getPixelSafe(x * size + xx, y * size + yy);
            // Используем среднее значение RGB для яркости, как в вашем Processing коде
            sum += (pixel.r + pixel.g + pixel.b) ~/ 3;
          }
        }
        sum ~/= (size * size);
        brightnessMap[y * X_GRID_SIZE + x] = sum;
      }
    }
    return brightnessMap;
  }

  // Метод для захвата базовой яркости
  void captureBaseBrightness(Uint8List imageBytes) {
    img.Image? image = img.decodeImage(imageBytes);
    if (image != null) {
      _baseBrightnessMap = _makeBrightnessMap(image);
    }
  }

  // Метод для обработки текущего кадра и поиска дельты
  CalibrationResult processFrameForDelta(Uint8List imageBytes) {
    if (_baseBrightnessMap == null) {
      // Этого не должно произойти, если логика в виджете правильная
      return CalibrationResult(maxX: 0, maxY: 0, calibCount: 0);
    }

    img.Image? currentImage = img.decodeImage(imageBytes);
    if (currentImage == null) {
      return CalibrationResult(maxX: 0, maxY: 0, calibCount: 0);
    }

    List<int> currentMap = _makeBrightnessMap(currentImage);
    int maxDelta = 0;
    int maxIndex = 0;

    // Находим разницу (дельту) яркости
    for (int i = 0; i < currentMap.length; i++) {
      int delta = currentMap[i] - _baseBrightnessMap![i];
      delta = max(delta, 0); // Разница не может быть отрицательной

      if (delta > maxDelta) {
        maxDelta = delta;
        maxIndex = i;
      }
    }

    final int Y_GRID_SIZE = currentImage.height ~/ (currentImage.width ~/ X_GRID_SIZE);
    final int maxX = maxIndex % X_GRID_SIZE;
    final int maxY = maxIndex ~/ X_GRID_SIZE;
    final int totalCells = X_GRID_SIZE * Y_GRID_SIZE;

    return CalibrationResult(maxX: maxX, maxY: maxY, calibCount: totalCells);
  }
}