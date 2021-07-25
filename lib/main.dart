import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/Login.dart';
import 'screens/Home.dart';

void main() {
  runApp(GamersHubApp());
}

class GamersHubApp extends StatefulWidget {
  const GamersHubApp({Key? key}) : super(key: key);

  @override
  _GamersHubAppState createState() => _GamersHubAppState();
}

class _GamersHubAppState extends State<GamersHubApp> {
  late String user;
  late bool isLoggedIn;
  late Future<SharedPreferences> _preferences;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() async {
    _preferences = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        child: MaterialApp(
          title: 'Gamers Hub',
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            if (settings.name == '/') {
              return MaterialPageRoute(builder: (context) => Login());
            } else if (settings.name == '/home') {
              final args = settings.arguments as ScreenArguments;
              return MaterialPageRoute(
                  builder: (context) =>
                      Home(user: args.username, isLoggedIn: args.isLoggedIn));
            }
          },
          theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF2E2D32)),
        ),
        value: SystemUiOverlayStyle.light);
  }
}
