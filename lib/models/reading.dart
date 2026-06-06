import '../core/formatters.dart';

class Reading {
  final String id;
  final String roomId;
  final DateTime month;
  final double prevElec;
  final double currElec;
  final double prevWater;
  final double currWater;
  final DateTime createdAt;

  /// Date when the previous electricity meter was read. Null for legacy data.
  final DateTime? prevElecDate;

  /// Date when the current electricity meter was read. Null for legacy data.
  final DateTime? currElecDate;

  /// Date when the previous water meter was read. Null for legacy data.
  final DateTime? prevWaterDate;

  /// Date when the current water meter was read. Null for legacy data.
  final DateTime? currWaterDate;

  const Reading({
    required this.id,
    required this.roomId,
    required this.month,
    required this.prevElec,
    required this.currElec,
    required this.prevWater,
    required this.currWater,
    required this.createdAt,
    this.prevElecDate,
    this.currElecDate,
    this.prevWaterDate,
    this.currWaterDate,
  });

  String get yearMonth => formatYearMonthKey(month);
  double get elecUsage => (currElec - prevElec).clamp(0, double.infinity);
  double get waterUsage => (currWater - prevWater).clamp(0, double.infinity);

  /// Number of days the electricity collection spans (curr date - prev date).
  int? get elecDaysSpan {
    if (prevElecDate == null || currElecDate == null) return null;
    return currElecDate!.difference(prevElecDate!).inDays;
  }

  /// Number of days the water collection spans (curr date - prev date).
  int? get waterDaysSpan {
    if (prevWaterDate == null || currWaterDate == null) return null;
    return currWaterDate!.difference(prevWaterDate!).inDays;
  }

  /// Days in the billing month.
  int get _monthDays => DateTime(month.year, month.month + 1, 0).day;

  /// Whether the electricity reading covers the full billing month.
  bool get isElecMonthComplete {
    final span = elecDaysSpan;
    if (span == null) return true; // Legacy data assumed complete
    return span >= _monthDays - 1;
  }

  /// Whether the water reading covers the full billing month.
  bool get isWaterMonthComplete {
    final span = waterDaysSpan;
    if (span == null) return true;
    return span >= _monthDays - 1;
  }

  /// Whether both electricity and water cover the full billing month.
  bool get isMonthComplete => isElecMonthComplete && isWaterMonthComplete;

  Reading copyWith({
    String? id,
    String? roomId,
    DateTime? month,
    double? prevElec,
    double? currElec,
    double? prevWater,
    double? currWater,
    DateTime? createdAt,
    DateTime? prevElecDate,
    DateTime? currElecDate,
    DateTime? prevWaterDate,
    DateTime? currWaterDate,
  }) => Reading(
    id: id ?? this.id,
    roomId: roomId ?? this.roomId,
    month: month ?? this.month,
    prevElec: prevElec ?? this.prevElec,
    currElec: currElec ?? this.currElec,
    prevWater: prevWater ?? this.prevWater,
    currWater: currWater ?? this.currWater,
    createdAt: createdAt ?? this.createdAt,
    prevElecDate: prevElecDate ?? this.prevElecDate,
    currElecDate: currElecDate ?? this.currElecDate,
    prevWaterDate: prevWaterDate ?? this.prevWaterDate,
    currWaterDate: currWaterDate ?? this.currWaterDate,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'yearMonth': yearMonth,
    'month': month.toIso8601String(),
    'prevElec': prevElec,
    'currElec': currElec,
    'prevWater': prevWater,
    'currWater': currWater,
    'createdAt': createdAt.toIso8601String(),
    if (prevElecDate != null) 'prevElecDate': prevElecDate!.toIso8601String(),
    if (currElecDate != null) 'currElecDate': currElecDate!.toIso8601String(),
    if (prevWaterDate != null) 'prevWaterDate': prevWaterDate!.toIso8601String(),
    if (currWaterDate != null) 'currWaterDate': currWaterDate!.toIso8601String(),
  };

  factory Reading.fromJson(Map<String, dynamic> j) => Reading(
    id: j['id'] as String,
    roomId: j['roomId'] as String,
    month: DateTime.parse(j['month'] as String),
    prevElec: (j['prevElec'] as num).toDouble(),
    currElec: (j['currElec'] as num).toDouble(),
    prevWater: (j['prevWater'] as num).toDouble(),
    currWater: (j['currWater'] as num).toDouble(),
    createdAt: DateTime.parse(j['createdAt'] as String),
    prevElecDate: j['prevElecDate'] != null
        ? DateTime.parse(j['prevElecDate'] as String)
        : null,
    currElecDate: j['currElecDate'] != null
        ? DateTime.parse(j['currElecDate'] as String)
        : null,
    prevWaterDate: j['prevWaterDate'] != null
        ? DateTime.parse(j['prevWaterDate'] as String)
        : null,
    currWaterDate: j['currWaterDate'] != null
        ? DateTime.parse(j['currWaterDate'] as String)
        : null,
  );
}
