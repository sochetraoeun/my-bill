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

  const Reading({
    required this.id,
    required this.roomId,
    required this.month,
    required this.prevElec,
    required this.currElec,
    required this.prevWater,
    required this.currWater,
    required this.createdAt,
  });

  String get yearMonth => formatYearMonthKey(month);
  double get elecUsage => (currElec - prevElec).clamp(0, double.infinity);
  double get waterUsage => (currWater - prevWater).clamp(0, double.infinity);

  Reading copyWith({
    String? id,
    String? roomId,
    DateTime? month,
    double? prevElec,
    double? currElec,
    double? prevWater,
    double? currWater,
    DateTime? createdAt,
  }) => Reading(
    id: id ?? this.id,
    roomId: roomId ?? this.roomId,
    month: month ?? this.month,
    prevElec: prevElec ?? this.prevElec,
    currElec: currElec ?? this.currElec,
    prevWater: prevWater ?? this.prevWater,
    currWater: currWater ?? this.currWater,
    createdAt: createdAt ?? this.createdAt,
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
  );
}
