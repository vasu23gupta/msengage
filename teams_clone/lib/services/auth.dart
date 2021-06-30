import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:teams_clone/services/database.dart';

/// Authentication and firebase user related functions.
class AuthService {
  /// Firebase auth instance.
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the firebase user stream.
  Stream<User?> get user => _auth.authStateChanges();

  // /// Send password reset email to [email].
  // Future<void> forgotPassword(String email) async =>
  //     await _auth.sendPasswordResetEmail(email: email);

  /// Sign in with email and password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  /// Register with email, password and username.
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      await user!.updateDisplayName(username);
      await user.reload();

      //create a new document for the user with the uid
      Response response =
          await UserDBService.addUser(username, email, user.uid);
      if (response.statusCode == 200)
        return user;
      else
        return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // //check entered password
  // Future<bool> validatePassword(String password) async {
  //   var firebaseUser = _auth.currentUser;
  //   var authCredentials = EmailAuthProvider.credential(
  //       email: firebaseUser!.email!, password: password);
  //   try {
  //     var authResult =
  //         await firebaseUser.reauthenticateWithCredential(authCredentials);
  //     return authResult.user != null;
  //   } catch (e) {
  //     print(e);
  //     return false;
  //   }
  // }

  /// Change password
  Future<void> updatePassword(String password) async {
    User? firebaseUser = _auth.currentUser;
    firebaseUser!.updatePassword(password);
  }

  /// Sign out
  static Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}
