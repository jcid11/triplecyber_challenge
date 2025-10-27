import 'package:cloud_firestore/cloud_firestore.dart';

class SignalingRepository {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> roomRef(String roomId) =>
      _db.collection('rooms').doc(roomId);

  Future<void> createRoom(String roomId, Map<String, dynamic> offer) async =>
      await roomRef(roomId).set({
        'offer': offer,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    final snap = await roomRef(roomId).get();
    return snap.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String roomId) =>
      roomRef(roomId).snapshots();

  Future<void> setAnswer(String roomId, Map<String, dynamic> answer) async =>
      await roomRef(roomId).update({'answer': answer, 'status': 'connected'});

  CollectionReference<Map<String, dynamic>> callerCandidates(String roomId) =>
      roomRef(roomId).collection('callerCandidates');

  CollectionReference<Map<String, dynamic>> calleeCandidates(String roomId) =>
      roomRef(roomId).collection('calleeCandidates');

  Future<void> addCallerCandidate(
    String roomId,
    Map<String, dynamic> c,
  ) async => await callerCandidates(roomId).add(c);

  Future<void> addCalleeCandidate(
    String roomId,
    Map<String, dynamic> c,
  ) async => await calleeCandidates(roomId).add(c);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCallerCandidates(
    String roomId,
  ) => callerCandidates(roomId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCalleeCandidates(
    String roomId,
  ) => calleeCandidates(roomId).snapshots();

  Future<void> deleteRoomDeep(String roomId) async {
    final fs = FirebaseFirestore.instance;
    final r = roomRef(roomId);

    // Read room first so we can compute duration from createdAt
    final roomSnap = await r.get();
    final createdAt = roomSnap.data()?['createdAt'] as Timestamp?;
    final clientNow = Timestamp.now();

    final batch = fs.batch();

    // Delete subcollections
    for (final name in const ['callerCandidates', 'calleeCandidates']) {
      final snap = await r.collection(name).get();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
    }

    // Prepare the room doc updates
    final updates = <String, Object?>{
      'hangUpAt': FieldValue.serverTimestamp(),
      'status': 'disconnected',
      'offer': FieldValue.delete(),
      'answer': FieldValue.delete(),
    };

    if (createdAt != null) {
      final durSec = clientNow.seconds - createdAt.seconds;
      updates['duration'] = _formatHms(Duration(seconds: durSec));
    }

    batch.update(r, updates);

    await batch.commit();
  }

  String _formatHms(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
