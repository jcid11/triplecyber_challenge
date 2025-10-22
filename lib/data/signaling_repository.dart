import 'package:cloud_firestore/cloud_firestore.dart';

class SignalingRepository {
  final _db = FirebaseFirestore.instance;


  DocumentReference<Map<String, dynamic>> roomRef(String roomId) =>
      _db.collection('rooms').doc(roomId);


  Future<void> createRoom(String roomId, Map<String, dynamic> offer) async {
    await roomRef(roomId).set({
      'offer': offer,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    final snap = await roomRef(roomId).get();
    return snap.data();
  }


  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String roomId) {
    return roomRef(roomId).snapshots();
  }


  Future<void> setAnswer(String roomId, Map<String, dynamic> answer) async {
    await roomRef(roomId).update({'answer': answer, 'status': 'connected'});
  }


  CollectionReference<Map<String, dynamic>> callerCandidates(String roomId) =>
      roomRef(roomId).collection('callerCandidates');


  CollectionReference<Map<String, dynamic>> calleeCandidates(String roomId) =>
      roomRef(roomId).collection('calleeCandidates');


  Future<void> addCallerCandidate(String roomId, Map<String, dynamic> c) async {
    await callerCandidates(roomId).add(c);
  }


  Future<void> addCalleeCandidate(String roomId, Map<String, dynamic> c) async {
    await calleeCandidates(roomId).add(c);
  }


  Stream<QuerySnapshot<Map<String, dynamic>>> watchCallerCandidates(String roomId) =>
      callerCandidates(roomId).snapshots();


  Stream<QuerySnapshot<Map<String, dynamic>>> watchCalleeCandidates(String roomId) =>
      calleeCandidates(roomId).snapshots();


  Future<void> deleteRoomDeep(String roomId) async {
    final r = roomRef(roomId);
    final caller = await r.collection('callerCandidates').get();
    for (final d in caller.docs) {
      await d.reference.delete();
    }
    final callee = await r.collection('calleeCandidates').get();
    for (final d in callee.docs) {
      await d.reference.delete();
    }
    await r.delete();
  }
}