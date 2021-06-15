import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:teams_clone/services/database.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  //auth change user stream
  Stream<User?> get user {
    //return _auth.authStateChanges().map(_userFromFirebaseUser);
    return _auth.authStateChanges();
  }

  //sign in anon
  Future signInAnon() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      return user;
      //return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future forgotPassword(String email) async =>
      await _auth.sendPasswordResetEmail(email: email);

  //sign in with email and password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return user;
      //return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  //register email pass
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      user!.sendEmailVerification();
      await user.updateDisplayName(username);
      await user.reload();

      //create a new document for the user with the uid
      Response response =
          await UserDBService.addUser(username, email, user.uid);
      if (response.statusCode == 200) {
        return user;
        //return _userFromFirebaseUser(user);
      } else
        return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  //check entered password
  Future<bool> validatePassword(String password) async {
    var firebaseUser = _auth.currentUser;
    var authCredentials = EmailAuthProvider.credential(
        email: firebaseUser!.email!, password: password);
    try {
      var authResult =
          await firebaseUser.reauthenticateWithCredential(authCredentials);
      return authResult.user != null;
    } catch (e) {
      print(e);
      return false;
    }
  }

  //change password
  Future<void> updatePassword(String password) async {
    var firebaseUser = _auth.currentUser;
    firebaseUser!.updatePassword(password);
  }

  //sign out
  static Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}
