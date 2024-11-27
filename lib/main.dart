import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/task_model.dart';
import 'screens/tasks_screen.dart';
import 'util/parse_util.dart';
import 'screens/login_screen.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initParse();

  runApp(MaterialApp(
    title: 'QuickTask',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: ChangeNotifierProvider(
        create: (context) => TaskModel(),
        child: Consumer<TaskModel>(
            builder: (_, taskModel, __) => const TasksScreen())),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickTask',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TasksScreen(),
    );
  }
}
