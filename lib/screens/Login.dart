import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Home.dart';

class ScreenArguments {
  final String username;
  final bool isLoggedIn;
  ScreenArguments(this.username, this.isLoggedIn);
}

class Login extends StatelessWidget {
  final Widget gameTvLogo = Container(
    child: Row(
      children: [
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/img/gametv-share.jpg',
              width: 600,
              height: 100,
              fit: BoxFit.cover,
            ),
          ],
        )),
      ],
    ),
  );

  final Widget loginForm = LoginSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [gameTvLogo, loginForm],
        ),
      ),
    );
  }
}

class LoginSection extends StatefulWidget {
  const LoginSection({Key? key}) : super(key: key);

  @override
  _LoginSectionState createState() => _LoginSectionState();
}

class _LoginSectionState extends State<LoginSection> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  bool _isObscure = true;
  String _username = "";
  String _password = "";
  late FocusNode _usernameFocusNode;
  late FocusNode _passwordFocusNode;
  String _usernameError = "";
  String _passwordError = "";
  bool _isUsernameValid = false;
  bool _isPasswordValid = false;
  late SharedPreferences storage;

  @override
  void initState() {
    super.initState();
    _usernameFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus) {
        setState(() {
          if (_username.isEmpty) {
            _usernameError = 'Please enter your username';
            _isUsernameValid = false;
          } else if (_username.length < 3) {
            _usernameError = 'Username too short, min 3 characters required';
            _isUsernameValid = false;
          } else if (_username.length > 10) {
            _usernameError = 'Username too long, max 10 characters required';
            _isUsernameValid = false;
          } else {
            _usernameError = "";
            _isUsernameValid = true;
          }
        });
      }
    });

    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        setState(() {
          if (_password.isEmpty) {
            _passwordError = 'Please enter your password';
            _isPasswordValid = false;
          } else if (_password.length < 3) {
            _passwordError = 'Password too short, min 3 characters required';
            _isPasswordValid = false;
          } else if (_password.length > 10) {
            _passwordError = 'Password too long, max 10 characters required';
            _isPasswordValid = false;
          } else {
            _passwordError = "";
            _isPasswordValid = true;
          }
        });
      }
    });
    _loadState();
  }

  void _loadState() async {
    storage = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formkey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 64.0, vertical: 16.0),
              child: TextFormField(
                autofocus: true,
                focusNode: _usernameFocusNode,
                decoration: InputDecoration(
                    hintText: "Enter your username",
                    labelText: "Username",
                    border: OutlineInputBorder(),
                    errorText:
                        _usernameError.length > 0 ? _usernameError : null,
                    hintStyle: TextStyle(color: Color(0x55FFFFFF))),
                style: TextStyle(color: Color(0xFFFFFFFF)),
                onChanged: (String _userName) {
                  _username = _userName;
                },
              )),
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 64.0, vertical: 16.0),
              child: TextFormField(
                obscureText: _isObscure,
                focusNode: _passwordFocusNode,
                decoration: InputDecoration(
                    hintText: "Enter your password",
                    labelText: "Password",
                    errorText:
                        _passwordError.length > 0 ? _passwordError : null,
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isObscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                    hintStyle: TextStyle(color: Color(0x55FFFFFF))),
                style: TextStyle(color: Color(0xFFFFFFFF)),
                onChanged: (String _passWord) {
                  _password = _passWord;
                },
              )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: _isUsernameValid && _isPasswordValid
                  ? () {
                      if (_username == "admin" && _password == "admin") {
                        // storage.setString("user", _username);
                        // storage.setBool("isLoggedIn", true);
                        Navigator.pushNamed(context, "/home",
                            arguments: ScreenArguments(_username, true));
                      } else if (_username == "user" && _password == "user") {
                        // storage.setString("user", _username);
                        // storage.setBool("isLoggedIn", true);
                        Navigator.pushNamed(context, "/home",
                            arguments: ScreenArguments(_username, true));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Username or password incorrect')));
                      }
                    }
                  : null,
              child: const Text("Submit"),
            ),
          )
        ],
      ),
    );
  }
}
