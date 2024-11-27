import 'package:flutter/material.dart';
import 'screens/tasks_screen.dart';
import 'util/parse_util.dart';
import 'screens/login_screen.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initParse();

  final currentUser = await ParseUser.currentUser() as ParseUser?;
  final isLoggedIn = currentUser != null;

  runApp(MaterialApp(
    title: 'Tasks App',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: isLoggedIn ? const TasksScreen() : const LoginScreen(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasks App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TasksScreen(),
    );
  }
}
