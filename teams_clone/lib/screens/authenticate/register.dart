// import 'package:flutter/material.dart';
// import 'package:teams_clone/services/auth.dart';
// import 'package:teams_clone/shared/constants.dart';

// class Register extends StatefulWidget {
//   final Function toggleView;
//   Register({required this.toggleView});

//   @override
//   _RegisterState createState() => _RegisterState();
// }

// class _RegisterState extends State<Register> {
//   final AuthService _auth = AuthService();
//   final _formKey = GlobalKey<FormState>();
//   bool _loading = false;
//   late double _w;
//   late double _h;
//   //text field state
//   TextEditingController _email = TextEditingController();
//   TextEditingController _password = TextEditingController();
//   String _error = '';

//   @override
//   Widget build(BuildContext context) {
//     _w = MediaQuery.of(context).size.width;
//     _h = MediaQuery.of(context).size.height;
//     return _loading
//         ? CircularProgressIndicator()
//         : Scaffold(
//             appBar: AppBar(
//               elevation: 0.0,
//               title: Text('Sign up'),
//               actions: <Widget>[
//                 TextButton.icon(
//                   icon: Icon(Icons.person),
//                   label: Text('Sign in'),
//                   onPressed: () => widget.toggleView(),
//                   style: TextButton.styleFrom(primary: PURPLE_COLOR),
//                 )
//               ],
//             ),
//             body: Form(
//               key: _formKey,
//               child: Column(
//                 children: <Widget>[
//                   SizedBox(height: 20.0),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: _w * 0.05),
//                     child: TextFormField(
//                       decoration:
//                           textInputDecoration.copyWith(hintText: 'E-mail'),
//                       validator: (val) =>
//                           val!.isEmpty ? 'Enter an email' : null,
//                       controller: _email,
//                     ),
//                   ),
//                   SizedBox(height: 20.0),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: _w * 0.05),
//                     child: TextFormField(
//                       decoration:
//                           textInputDecoration.copyWith(hintText: 'Password'),
//                       obscureText: true,
//                       validator: (val) => val!.length < 6
//                           ? 'Enter a password 6+ characters long'
//                           : null,
//                       controller: _password,
//                     ),
//                   ),
//                   SizedBox(height: 20.0),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       primary: PURPLE_COLOR,
//                       minimumSize: Size(_w * 0.9, _h * 0.06),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.all(Radius.circular(5))),
//                     ),
//                     child: Text(
//                       'Register',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     onPressed: () async {
//                       if (_formKey.currentState!.validate()) {
//                         setState(() => _loading = true);
//                         dynamic result =
//                             await _auth.registerWithEmailAndPassword(
//                                 email, password, email.split('@')[0]);
//                         if (result == null) {
//                           setState(() {
//                             error = 'please supply a valid email';
//                             _loading = false;
//                           });
//                         }
//                       }
//                     },
//                   ),
//                   SizedBox(
//                     height: 12.0,
//                   ),
//                   Text(
//                     error,
//                     style: TextStyle(color: Colors.red, fontSize: 14.0),
//                   )
//                 ],
//               ),
//             ),
//           );
//   }
// }
