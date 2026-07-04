class MaintenanceDeviceModel {
  // Owner/User Information
  final String? userId; // رقم هاتف المستخدم صاحب الجهاز

  // Customer Information
  final String name;
  final String phoneNumber;

  // Device Information
  final String? brand;
  final String model;
  final String colorHex;
  final String? imeiNumber;
  // pin, patternLock, notesHidden intentionally NOT on this model — they
  // live in maintenanceDevices/{id}/private/sensitive per
  // docs/ai-workflow/ADR-001-sensitive-data-separation.md. Use
  // MaintenanceDeviceSensitiveDataService to read/write them.

  // Maintenance Information
  final List<String> problems;
  final String status; // pending, in_progress, completed, delivered
  final List<String> accessories;
  final List<String> deviceStatusReceived;

  // Pricing & Timeline
  final double? price;
  final String? estimatedTime;
  final String? additionalNotes; // ملاحظات عامة للعميل

  // Device Images
  final List<String>? imagesBeforeReceiving; // URLs in Firebase Storage
  final List<String>? imagesAfterDelivery; // URLs in Firebase Storage

  // Assignment
  final String? assignedTechnicianId; // معرف الفني المكلف بالصيانة

  // Employee Information
  final String receivedByEmployee; // الموظف الذي استلم الجهاز (required)
  final String?
      deliveredByEmployee; // الموظف الذي سلّم الجهاز (required when status = delivered)
  final String?
      maintenanceEmployee; // موظف الصيانة (required when status = fixed or delivered)
  final List<String>? installedPartCodes; // أكواد القطع التي تم تركيبها

  // Metadata
  final DateTime receivedAt;
  final DateTime? deliveredAt;
  final DateTime?
      fixedAt; // الوقت الذي تم فيه إصلاح الجهاز (يمكن حسابه عند تحديث الحالة إلى fixed)
  final DateTime?
      timeToFix; // الوقت المستغرق للصيانة (يمكن حسابه عند تحديث الحالة إلى fixed)
  final DateTime? updatedAt;
  final String? id; // Document ID

  MaintenanceDeviceModel({
    this.userId,
    required this.name,
    required this.phoneNumber,
    this.brand,
    required this.model,
    required this.colorHex,
    this.imeiNumber,
    required this.problems,
    this.status = 'pending', // القيمة الافتراضية
    required this.accessories,
    required this.deviceStatusReceived,
    this.price,
    this.estimatedTime,
    this.additionalNotes,
    this.imagesBeforeReceiving,
    this.imagesAfterDelivery,
    this.assignedTechnicianId,
    required this.receivedByEmployee,
    this.deliveredByEmployee,
    this.maintenanceEmployee,
    this.installedPartCodes,
    required this.receivedAt,
    this.deliveredAt,
    this.fixedAt,
    this.timeToFix,
    this.updatedAt,
    this.id,
  });

  // Convert to JSON for Firebase/API
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'brand': brand,
      'model': model,
      'colorHex': colorHex,
      'imeiNumber': imeiNumber,
      'problems': problems,
      'status': status,
      'accessories': accessories,
      'deviceStatusReceived': deviceStatusReceived,
      'price': price,
      'estimatedTime': estimatedTime,
      'additionalNotes': additionalNotes,
      'imagesBeforeReceiving': imagesBeforeReceiving,
      'imagesAfterDelivery': imagesAfterDelivery,
      'assignedTechnicianId': assignedTechnicianId,
      'receivedByEmployee': receivedByEmployee,
      'deliveredByEmployee': deliveredByEmployee,
      'maintenanceEmployee': maintenanceEmployee,
      'installedPartCodes': installedPartCodes,
      'receivedAt': receivedAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'fixedAt': fixedAt?.toIso8601String(),
      'timeToFix': timeToFix?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory MaintenanceDeviceModel.fromJson(
      Map<String, dynamic> json, String documentId) {
    return MaintenanceDeviceModel(
      id: documentId,
      userId: json['userId'] as String?,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String,
      colorHex: json['colorHex'] as String,
      imeiNumber: json['imeiNumber'] as String?,
      problems:
          (json['problems'] as List<dynamic>).map((e) => e as String).toList(),
      status: json['status'] as String? ?? 'pending',
      accessories: (json['accessories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      deviceStatusReceived: (json['deviceStatusReceived'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      estimatedTime: json['estimatedTime'] as String?,
      additionalNotes: json['additionalNotes'] as String?,
      imagesBeforeReceiving: (json['imagesBeforeReceiving'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imagesAfterDelivery: (json['imagesAfterDelivery'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      assignedTechnicianId: json['assignedTechnicianId'] as String?,
      receivedByEmployee: json['receivedByEmployee'] as String,
      deliveredByEmployee: json['deliveredByEmployee'] as String?,
      maintenanceEmployee: json['maintenanceEmployee'] as String?,
      installedPartCodes: (json['installedPartCodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      fixedAt: json['fixedAt'] != null
          ? DateTime.parse(json['fixedAt'] as String)
          : null,
      timeToFix: json['timeToFix'] != null
          ? DateTime.parse(json['timeToFix'] as String)
          : null,
    );
  }

  // Create from Map (for Firestore documents)
  factory MaintenanceDeviceModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return MaintenanceDeviceModel(
      id: documentId,
      userId: map['userId'] as String?,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      brand: map['brand'] as String?,
      model: map['model'] as String,
      colorHex: map['colorHex'] as String,
      imeiNumber: map['imeiNumber'] as String?,
      problems:
          (map['problems'] as List<dynamic>).map((e) => e as String).toList(),
      status: map['status'] as String? ?? 'pending',
      accessories: (map['accessories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      deviceStatusReceived: (map['deviceStatusReceived'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      estimatedTime: map['estimatedTime'] as String?,
      additionalNotes: map['additionalNotes'] as String?,
      imagesBeforeReceiving: (map['imagesBeforeReceiving'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imagesAfterDelivery: (map['imagesAfterDelivery'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      assignedTechnicianId: map['assignedTechnicianId'] as String?,
      receivedByEmployee: map['receivedByEmployee'] as String,
      deliveredByEmployee: map['deliveredByEmployee'] as String?,
      maintenanceEmployee: map['maintenanceEmployee'] as String?,
      installedPartCodes: (map['installedPartCodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      receivedAt: DateTime.parse(map['receivedAt'] as String),
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.parse(map['deliveredAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      fixedAt: map['fixedAt'] != null
          ? DateTime.parse(map['fixedAt'] as String)
          : null,
      timeToFix: map['timeToFix'] != null
          ? DateTime.parse(map['timeToFix'] as String)
          : null,
    );
  }

  // Copy with method for updates
  MaintenanceDeviceModel copyWith({
    String? userId,
    String? name,
    String? phoneNumber,
    String? brand,
    String? model,
    String? colorHex,
    String? imeiNumber,
    List<String>? problems,
    String? status,
    List<String>? accessories,
    List<String>? deviceStatusReceived,
    double? price,
    String? estimatedTime,
    String? additionalNotes,
    List<String>? imagesBeforeReceiving,
    List<String>? imagesAfterDelivery,
    String? assignedTechnicianId,
    String? receivedByEmployee,
    String? deliveredByEmployee,
    String? maintenanceEmployee,
    List<String>? installedPartCodes,
    DateTime? receivedAt,
    DateTime? deliveredAt,
    DateTime? updatedAt,
    DateTime? fixedAt,
    DateTime? timeToFix,
    String? id,
  }) {
    return MaintenanceDeviceModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      colorHex: colorHex ?? this.colorHex,
      imeiNumber: imeiNumber ?? this.imeiNumber,
      problems: problems ?? this.problems,
      status: status ?? this.status,
      accessories: accessories ?? this.accessories,
      deviceStatusReceived: deviceStatusReceived ?? this.deviceStatusReceived,
      price: price ?? this.price,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      imagesBeforeReceiving:
          imagesBeforeReceiving ?? this.imagesBeforeReceiving,
      imagesAfterDelivery: imagesAfterDelivery ?? this.imagesAfterDelivery,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      receivedByEmployee: receivedByEmployee ?? this.receivedByEmployee,
      deliveredByEmployee: deliveredByEmployee ?? this.deliveredByEmployee,
      maintenanceEmployee: maintenanceEmployee ?? this.maintenanceEmployee,
      installedPartCodes: installedPartCodes ?? this.installedPartCodes,
      receivedAt: receivedAt ?? this.receivedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fixedAt: fixedAt ?? this.fixedAt,
      timeToFix: timeToFix ?? this.timeToFix,
      id: id ?? this.id,
    );
  }

  @override
  String toString() {
    return 'NewDeviceMaintenanceModel(userId: $userId, name: $name, phoneNumber: $phoneNumber, model: $model, status: $status, timeToFix: $timeToFix, id: $id)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MaintenanceDeviceModel &&
        other.userId == userId &&
        other.name == name &&
        other.phoneNumber == phoneNumber &&
        other.model == model &&
        other.installedPartCodes == installedPartCodes &&
        other.timeToFix == timeToFix &&
        other.id == id;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        name.hashCode ^
        phoneNumber.hashCode ^
        model.hashCode ^
        installedPartCodes.hashCode ^
        timeToFix.hashCode ^
        id.hashCode;
  }
}
