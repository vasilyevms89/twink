class EffectType {
  final int id;
  final String name;
  const EffectType(this.id, this.name);
}

class Palette {
  final int id;
  final String name;
  const Palette(this.id, this.name);
}

// Список типов эффектов
const List<EffectType> effectTypes = [
  EffectType(0, "Диагональный градиент"),
  EffectType(1, "Шум Перлина"),
  // В будущем новые эффекты можно добавлять сюда:
  // EffectType(2, "Новый эффект"),
];

// Список палитр
const List<Palette> palettes = [
  Palette(0, "Fire"), Palette(1, "Party"),
  Palette(2, "Raibow"), Palette(3, "Stripe"),
  Palette(4, "Sunset"), Palette(5, "Pepsi"),
  Palette(6, "Warm"), Palette(7, "Cold"),
  Palette(8, "Hot"), Palette(9, "Pink"),
  Palette(10, "Cyber"), Palette(11, "RedWhite"),
  // Новые палитры добавляются сюда
];