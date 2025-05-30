// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserModel {
  String uid;
  String username;
  int coins;
  List<String> ownedSkins;
  String selectedSkin;
  int highScore;
  List<String> achievements;
  DateTime lastLogin;

  UserModel({
    required this.uid,
    required this.username,
    required this.coins,
    required this.ownedSkins,
    required this.selectedSkin,
    required this.highScore,
    required this.achievements,
    required this.lastLogin,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'coins': coins,
        'ownedSkins': ownedSkins,
        'selectedSkin': selectedSkin,
        'highScore': highScore,
        'achievements': achievements,
        'lastLogin': lastLogin.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'],
        username: json['username'],
        coins: json['coins'],
        ownedSkins: List<String>.from(json['ownedSkins']),
        selectedSkin: json['selectedSkin'],
        highScore: json['highScore'],
        achievements: List<String>.from(json['achievements']),
        lastLogin: DateTime.parse(json['lastLogin']),
      );
}
