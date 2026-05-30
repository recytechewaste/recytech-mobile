class WasteTypeMapper {
  static const Map<String, String> _yoloToBackendWasteType = {
    'pcb': 'PCB',
    'air_conditioner': 'Air Conditioner',
    'battery': 'Battery',
    'fan': 'Fan',
    'keyboard': 'Keyboard',
    'laptop': 'Laptop',
    'microwave': 'Microwave',
    'monitor': 'Monitor',
    'mouse': 'Mouse',
    'oven': 'Oven',
    'printer': 'Printer',
    'refrigerator': 'Refrigerator',
    'smartphone': 'Smartphone',
    'television': 'Television',
    'washing_machine': 'Washing Machine',
  };

  static String toBackendWasteType(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) return trimmedValue;

    final normalizedKey = trimmedValue
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    return _yoloToBackendWasteType[normalizedKey] ?? trimmedValue;
  }
}
