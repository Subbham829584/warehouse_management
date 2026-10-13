import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:warehouse_management/core/constants.dart';

/// Resolves (or creates) the warehouse a signed-in user belongs to.
/// Replaces the old hard-coded warehouse id.
class WarehouseBootstrap {
  WarehouseBootstrap._();

  static Future<String> resolve(User user,
      {FirebaseFirestore? firestore,}) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final profileRef = db.collection(AppConstants.usersCol).doc(user.uid);

    final profile = await profileRef.get();
    final existing = profile.data()?['warehouseId'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    // First login: create a private warehouse owned by this user.
    final whRef = db.collection(AppConstants.warehousesCol).doc();
    await whRef.set({
      'name': '${user.displayName ?? user.email ?? 'My'} Warehouse',
      'ownerId': user.uid,
      'members': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await profileRef.set({
      'uid': user.uid,
      'email': user.email,
      'role': profile.data()?['role'] ?? 'staff',
      'warehouseId': whRef.id,
    }, SetOptions(merge: true),);
    return whRef.id;
  }
}
