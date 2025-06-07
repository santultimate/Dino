import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static final FirebaseService _instance = FirebaseService._internal(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );

  factory FirebaseService() => _instance;

  FirebaseService._internal(this._auth, this._db);

  UserModel? _cachedUser;
  StreamSubscription<UserModel?>? _userSubscription;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<void> initialize() async {
    if (_auth.currentUser != null) {
      await _setupUserListener(_auth.currentUser!.uid);
    }
  }

  // AUTH ----------------------------------------------------------------------------

  Future<UserModel?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      await _createUserData(userCredential.user!);
      await _setupUserListener(userCredential.user!.uid);
      return _cachedUser;
    } catch (e) {
      _logError('Connexion anonyme', e);
      return null;
    }
  }

  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _setupUserListener(userCredential.user!.uid);
      return _cachedUser;
    } catch (e) {
      _logError('Connexion email', e);
      return null;
    }
  }

  Future<UserModel?> signUpWithEmail(
      String email, String password, String username) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _createUserData(userCredential.user!, username: username);
      await _setupUserListener(userCredential.user!.uid);
      return _cachedUser;
    } catch (e) {
      _logError('Inscription', e);
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _cachedUser = null;
    await _userSubscription?.cancel();
  }

  // USER DATA ------------------------------------------------------------------------

  Future<void> _createUserData(User user, {String username = 'Joueur'}) async {
    final userRef = _db.collection('users').doc(user.uid);
    final exists = (await userRef.get()).exists;

    if (!exists) {
      final newUser = UserModel(
        uid: user.uid,
        username: username,
        email: user.email,
        coins: 100,
        ownedSkins: ['default'],
        selectedSkin: 'default',
        highScores: {},
        achievements: [],
        lastLogin: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await userRef.set(newUser.toJson());
    }
  }

  Future<void> _setupUserListener(String uid) async {
    await _userSubscription?.cancel();
    _userSubscription = _db.collection('users').doc(uid).snapshots().map(
      (snap) {
        if (!snap.exists) return null;
        return UserModel.fromJson(snap.data()!);
      },
    ).listen(
      (user) {
        _cachedUser = user;
        debugPrint('👤 Utilisateur mis à jour: ${user?.username}');
      },
      onError: (e) => _logError('User listener', e),
    );
  }

  Future<UserModel?> getUserData({bool forceRefresh = false}) async {
    if (_cachedUser != null && !forceRefresh) return _cachedUser;
    if (_auth.currentUser == null) return null;

    try {
      final snap = await _db.collection('users').doc(_auth.currentUser!.uid).get();
      _cachedUser = snap.exists ? UserModel.fromJson(snap.data()!) : null;
      return _cachedUser;
    } catch (e) {
      _logError('Récupération user', e);
      return null;
    }
  }

  Future<void> updateUserData(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).update(user.toJson());
      _cachedUser = user;
    } catch (e) {
      _logError('Mise à jour user', e);
      throw Exception('Échec de la mise à jour');
    }
  }

  // SCORES --------------------------------------------------------------------------

  Future<void> saveScore({
    required int score,
    required String mode,
    required Map<String, dynamic> gameData,
  }) async {
    if (_auth.currentUser == null) return;

    try {
      final batch = _db.batch();
      final userId = _auth.currentUser!.uid;
      final scoresRef = _db.collection('users').doc(userId).collection('scores');
      final userRef = _db.collection('users').doc(userId);

      batch.set(scoresRef.doc(), {
        'score': score,
        'mode': mode,
        'timestamp': FieldValue.serverTimestamp(),
        ...gameData,
      });

      final currentHigh = _cachedUser?.highScores[mode] ?? 0;
      if (score > currentHigh) {
        batch.update(userRef, {
          'highScores.$mode': score,
          'lastPlayed': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      _logError('Sauvegarde score', e);
    }
  }

  Future<List<ScoreEntry>> getLeaderboard(String mode, {int limit = 10}) async {
    try {
      final query = await _db
          .collectionGroup('scores')
          .where('mode', isEqualTo: mode)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => ScoreEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _logError('Récupération leaderboard', e);
      return [];
    }
  }

  // UTILS --------------------------------------------------------------------------

  void _logError(String context, dynamic error) {
    debugPrint('❌ FirebaseService ($context): $error');
    // FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
  }
}

class ScoreEntry {
  final int score;
  final String mode;
  final DateTime timestamp;
  final String? userId;

  ScoreEntry({
    required this.score,
    required this.mode,
    required this.timestamp,
    this.userId,
  });

  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    return ScoreEntry(
      score: json['score'] ?? 0,
      mode: json['mode'] ?? 'inconnu',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: json['userId'],
    );
  }
}
