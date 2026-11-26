import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tüm aktif etkinlikleri getir
  Stream<List<EventModel>> getOpenEvents() {
    return _firestore
        .collection('events')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => EventModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Yeni etkinlik oluştur
  Future<void> createEvent(EventModel event) async {
    await _firestore.collection('events').add(event.toMap());
  }

  // Etkinliğe katıl
  Future<void> joinEvent(String eventId, String userId, bool requiresApproval) async {
    if (requiresApproval) {
      await _firestore.collection('events').doc(eventId).update({
        'pendingUserIds': FieldValue.arrayUnion([userId])
      });
    } else {
      await _firestore.collection('events').doc(eventId).update({
        'approvedUserIds': FieldValue.arrayUnion([userId]),
        'currentCount': FieldValue.increment(1),
      });
    }
  }

  // Etkinlikten ayrıl
  Future<void> leaveEvent(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'approvedUserIds': FieldValue.arrayRemove([userId]),
      'currentCount': FieldValue.increment(-1),
    });
  }

  // --- EKSİK OLAN ONAY VE RED SİSTEMİ FONKSİYONLARI ---

  // Kurucuya ait olan ve onay bekleyen kullanıcısı olan etkinlikleri getir
  Stream<List<EventModel>> getEventRequests(String hostId) {
    return _firestore
        .collection('events')
        .where('hostId', isEqualTo: hostId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => EventModel.fromMap(doc.data(), doc.id))
        .where((event) => event.pendingUserIds.isNotEmpty)
        .toList());
  }

  // İsteği Onayla (Bekleyenlerden çıkar, Onaylananlara ekle, Sayıyı 1 artır)
  Future<void> approveRequest(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'pendingUserIds': FieldValue.arrayRemove([userId]),
      'approvedUserIds': FieldValue.arrayUnion([userId]),
      'currentCount': FieldValue.increment(1),
    });
  }

  // İsteği Reddet (Sadece bekleyenlerden çıkar)
  Future<void> rejectRequest(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'pendingUserIds': FieldValue.arrayRemove([userId]),
    });
  }
}