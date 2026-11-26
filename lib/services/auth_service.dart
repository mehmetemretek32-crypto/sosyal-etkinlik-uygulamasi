import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String department,
    required int grade,
    required List<String> interests,
    String bio = '',
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!cleanEmail.endsWith('@ogr.cumhuriyet.edu.tr') &&
        !cleanEmail.endsWith('@cumhuriyet.edu.tr')) {
      throw Exception('Sadece kampüs e-postası ile kayıt olabilirsiniz.');
    }

    final UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final User? user = credential.user;
    if (user == null) throw Exception('Kullanıcı oluşturulamadı.');
    await user.sendEmailVerification();

    final newUser = UserModel(
      uid: user.uid,
      fullName: fullName.trim(),
      email: cleanEmail,
      department: department.trim(),
      grade: grade,
      bio: bio.trim(),
      interests: interests,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
  }

  Future<User?> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    return credential.user;
  }

  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}