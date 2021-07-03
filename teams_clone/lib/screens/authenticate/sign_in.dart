import 'package:flutter/material.dart';
import 'package:teams_clone/services/auth.dart';
import 'package:teams_clone/shared/constants.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  late double _w;
  late double _h;
  //text field state
  TextEditingController _email = TextEditingController();
  TextEditingController _password = TextEditingController();
  String _error = '';
  bool _signingIn = true;

  @override
  Widget build(BuildContext context) {
    _w = MediaQuery.of(context).size.width;
    _h = MediaQuery.of(context).size.height;
    return _loading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: _buildAppBar(),
            body: Form(
              key: _formKey,
              child: _buildColumn(),
            ),
          );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0.0,
      title: Text(
        _signingIn ? 'Sign in' : 'Register',
        style: APPBAR_TEXT_STYLE,
      ),
      actions: <Widget>[
        TextButton.icon(
          icon: Icon(Icons.person),
          label: Text(_signingIn ? 'Register' : 'Sign in'),
          onPressed: () => setState(() => (_signingIn = !_signingIn)),
          style: TextButton.styleFrom(primary: PURPLE_COLOR),
        )
      ],
    );
  }

  Column _buildColumn() {
    return Column(
      children: <Widget>[
        SizedBox(height: 20.0),
        _buildEmailTextField(),
        SizedBox(height: 20.0),
        _buildPasswordTextField(),
        SizedBox(height: 20.0),
        _buildSignInRegisterButton(),
        SizedBox(height: 12.0),
        _buildErrorText(),
      ],
    );
  }

  Padding _buildEmailTextField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _w * 0.05),
      child: TextFormField(
        decoration: textInputDecoration.copyWith(hintText: 'Enter email'),
        validator: (val) => val!.isEmpty ? 'Enter an email' : null,
        controller: _email,
      ),
    );
  }

  Padding _buildPasswordTextField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _w * 0.05),
      child: TextFormField(
        decoration: textInputDecoration.copyWith(hintText: 'Password'),
        obscureText: true,
        validator: (val) =>
            val!.length < 6 ? 'Enter a password 6+ characters long' : null,
        controller: _password,
      ),
    );
  }

  ElevatedButton _buildSignInRegisterButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: PURPLE_COLOR,
        minimumSize: Size(_w * 0.9, _h * 0.06),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5))),
      ),
      child: Text(
        _signingIn ? 'Sign in' : 'Register',
        style: TextStyle(color: Colors.white, fontSize: _w * 0.04),
      ),
      onPressed: () => _signingIn ? _signIn() : _register(),
    );
  }

  Text _buildErrorText() {
    return Text(
      _error,
      style: TextStyle(color: Colors.red, fontSize: 14.0),
    );
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      dynamic result = await _auth.signInWithEmailAndPassword(
          _email.text.trim(), _password.text);
      if (result == null)
        setState(() {
          _loading = false;
          _error = 'could not sign in with those credentials';
        });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      dynamic result = await _auth.registerWithEmailAndPassword(
          _email.text, _password.text, _email.text.split('@')[0]);
      if (result == null) {
        setState(() {
          _error = 'please supply a valid email';
          _loading = false;
        });
      }
    }
  }
}
