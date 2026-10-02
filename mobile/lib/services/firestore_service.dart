import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_plan.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _firestore.collection('users');

  Stream<UserPlan?> streamUserPlan(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserPlan.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  Future<UserPlan?> getUserPlan(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserPlan.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<void> createUserPlan(UserPlan plan) async {
    await _usersRef.doc(plan.uid).set(plan.toMap(), SetOptions(merge: true));
  }

  Future<void> toggleTask({
    required String uid,
    required int dayNumber,
    required int taskIndex,
    required bool completed,
    required Map<String, int> currentDone,
  }) async {
    final updated = Map<String, int>.from(currentDone);
    final key = '$dayNumber:$taskIndex';
    if (completed) {
      updated[key] = 1;
    } else {
      updated.remove(key);
    }
    await _usersRef.doc(uid).update({'done': updated});
  }

  Future<void> updateWater({
    required String uid,
    required int dayNumber,
    required int glasses,
    required Map<String, int> currentWater,
  }) async {
    final updated = Map<String, int>.from(currentWater);
    updated['$dayNumber'] = glasses;
    await _usersRef.doc(uid).update({'water': updated});
  }

  Future<void> logWeight({
    required String uid,
    required String date,
    required double weight,
    required List<WeightEntry> currentWts,
  }) async {
    final updated = currentWts.where((e) => e.date != date).toList()
      ..add(WeightEntry(date: date, weight: weight));
    await _usersRef.doc(uid).update({
      'wts': updated.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> updateCustomPlan({
    required String uid,
    required Map<String, dynamic> customPlanMap,
  }) async {
    await _usersRef.doc(uid).update({'customPlan': customPlanMap});
  }

  /// Option 1: Keep Account & Clear All Data (Reset Start Date)
  Future<void> resetPlanDataAndStartDate({
    required String uid,
    required String newStartDate,
  }) async {
    await _usersRef.doc(uid).update({
      'startDate': newStartDate,
      'done': <String, int>{},
      'water': <String, int>{},
      'wts': <Map<String, dynamic>>[],
    });
  }

  /// Option 2: Delete Firestore Record & Delete Firebase Auth Account
  Future<void> deleteUserPlanAndAccount(String uid) async {
    await _usersRef.doc(uid).delete();
  }
}
