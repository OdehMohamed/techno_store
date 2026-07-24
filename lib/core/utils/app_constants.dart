import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Techno Store';

  static const List<Color> maintenancePredefinedColors = [
    Color(0xff000000),
    Color(0xffffd700),
    Color(0xffc0c0c0),
    Color(0xff9c27b0),
    Color(0xffffffff),
    Color(0xff2196f3),
    Color(0xff000080),
    Color(0xfff44336),
    Color(0xff4caf50),
  ];

  static const List<String> maintenanceProblemList = [
    'Not Working',
    'Screen',
    'Battery',
    'Charging Base',
    'Service',
    'Check',
    'Selfie Camera',
    'Main Camera',
    'Internal Headset',
    'External Headset',
    'Microphone',
    'Touch Screen',
    'Fingerprint',
    'Device Back',
    'Software',
    'Open Gmail',
    'Open iCloud',
    'Volume Button',
    'Power Button',
  ];

  static const List<String> maintenanceAccessoryList = [
    'Charger',
    'Headphones',
    'Case',
    'Screen Protector',
    'SIM 1',
    'SIM 2',
    'Memory Card',
    'Cable',
    'Bag',
    'Other',
  ];

  static const List<String> maintenancePreCheckList = [
    'Scratches',
    'Cracks',
    'Liquid Damage',
    'Missing Parts',
    'Others',
  ];

  static const List<String> deviceBrandList = [
    'Apple',
    'Samsung',
    'Huawei',
    'Xiaomi',
    'Others',
  ];

  static const List<String> estimatedTimeList = [
    '30 min',
    '1 Hour',
    '2 Hours',
    '3 Hours',
    '4 Hours',
    '5 Hours',
    'Not determined',
  ];
}
