import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:instagram_v2/models/user_data.dart';
import 'package:instagram_v2/screens/home_screen.dart';
import 'package:instagram_v2/screens/login_screen.dart';
import 'package:instagram_v2/screens/splash_screen.dart';
import 'package:instagram_v2/services/database_service.dart';
import 'package:instagram_v2/utilities/constants.dart';
import 'package:provider/provider.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = Firestore.instance;
  static final _googleSignIn = GoogleSignIn();

  static Future<bool> signUpUser(
      BuildContext context, String name, String email, String password) async {
    try {
      AuthResult authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      FirebaseUser signedInUser = authResult.user;
      if (signedInUser != null) {
        signedInUser.sendEmailVerification();
      }
      if (signedInUser != null) {
        _firestore.collection('/users').document(signedInUser.uid).setData({
          'name': name,
          'email': email,
          'profileImageUrl': '',
          'type': 'Custom',
          'isActive': true
        });
        DatabaseService.followUser(
            currentUserId: signedInUser.uid, userId: signedInUser.uid);
        return true;
      }
      return false;
    } catch (e) {
      print(e);
    }
    return false;
  }

  static void logout() {
    _auth.signOut();
    if (_googleSignIn.currentUser != null) {
      _googleSignIn.signOut();
    }
  }

  static Future<int> login(
      String email, String password, BuildContext context) async {
    try {
      AuthResult authResult = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      FirebaseUser user = authResult.user;
      if (user != null) {
        if (user.isEmailVerified) {
          Provider
              .of<UserData>(context)
              .currentUserId = user.uid;
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomeScreen(user.uid)),
                  (Route<dynamic> route) => false);
          return 0;
        }
        else {
          return 1;
        }
      }
    } catch (e) {
      print(e);
    }
    return 2;
  }

  static Future<void> loginGoogle(BuildContext context) async {
    try {
      GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      AuthCredential authCredential = GoogleAuthProvider.getCredential(
          idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);
      AuthResult authResult = await _auth.signInWithCredential(authCredential);
      FirebaseUser user = authResult.user;
      if (user != null) {
        if (authResult.additionalUserInfo.isNewUser) {
          await _firestore.collection('/users').document(user.uid).setData({
            'name': user.displayName,
            'email': user.email,
            'profileImageUrl': user.photoUrl,
            'type': 'Google',
            'isActive': true
          });
          DatabaseService.followUser(currentUserId: user.uid, userId: user.uid);
        }
        Provider.of<UserData>(context).currentUserId = user.uid;
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomeScreen(user.uid)),
            (Route<dynamic> route) => false);
      }
    } catch (e) {
      print(e);
    }
  }

  static Future<bool> sendEmailResetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      //Navigator.of(context).pop();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<bool> checkExistEmail(String email) async {
    QuerySnapshot checkEmailSnapshot = await usersRef.where('email', isEqualTo: email).getDocuments();
    return checkEmailSnapshot.documents.isNotEmpty;
  }

  static Future<bool> checkLogin(String email, String password) async {
    try {
      FirebaseUser user = await _auth.currentUser();
      AuthCredential credential = EmailAuthProvider.getCredential(
          email: email, password: password);
      AuthResult result = await user.reauthenticateWithCredential(credential);
      if (result != null) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updatePassword(String newPassword) async {
    try {
      FirebaseUser user = await _auth.currentUser();
      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      return false;
    }
  }
}
