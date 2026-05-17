import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reading.dart';
import 'readings_repository.dart';

/// Reading docs are stored at `readings/{id}` with these fields:
/// `roomId`, `yearMonth`, `month` (Timestamp), `prevElec`, `currElec`,
/// `prevWater`, `currWater`, `createdAt` (Timestamp).
class FirestoreReadingsRepository implements ReadingsRepository {
  FirestoreReadingsRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('readings');

  Reading _fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final j = snap.data()!;
    DateTime parse(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      return DateTime.now();
    }

    return Reading(
      id: snap.id,
      roomId: j['roomId'] as String,
      month: parse(j['month']),
      prevElec: (j['prevElec'] as num).toDouble(),
      currElec: (j['currElec'] as num).toDouble(),
      prevWater: (j['prevWater'] as num).toDouble(),
      currWater: (j['currWater'] as num).toDouble(),
      createdAt: parse(j['createdAt']),
    );
  }

  Map<String, dynamic> _toMap(Reading r) => {
    'roomId': r.roomId,
    'yearMonth': r.yearMonth,
    'month': Timestamp.fromDate(r.month),
    'prevElec': r.prevElec,
    'currElec': r.currElec,
    'prevWater': r.prevWater,
    'currWater': r.currWater,
    'createdAt': Timestamp.fromDate(r.createdAt),
  };

  @override
  Stream<List<Reading>> watchAll() => _col
      .orderBy('month', descending: true)
      .snapshots()
      .map((qs) => qs.docs.map(_fromSnap).toList());

  @override
  Future<List<Reading>> getAll() async {
    final qs = await _col.orderBy('month', descending: true).get();
    return qs.docs.map(_fromSnap).toList();
  }

  @override
  Future<void> upsert(Reading reading) =>
      _col.doc(reading.id).set(_toMap(reading));

  @override
  Future<void> delete(String id) => _col.doc(id).delete();

  @override
  Future<void> deleteByRoom(String roomId) async {
    final qs = await _col.where('roomId', isEqualTo: roomId).get();
    if (qs.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in qs.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> clear() async {
    final qs = await _col.get();
    final batch = _db.batch();
    for (final d in qs.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}
