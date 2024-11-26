import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'tasks_screen.dart';

void main() async {
  // const keyApplicationId = 'kUCPjYcj2s3IhWWRWjwF1BfVNWoaBYQNx3EaNEFN';
  // const keyClientKey = 'olZHi00LGpSuAQi4wHHHFkpvvbmfSvwg78lMFXzG';
  // const keyParseServerUrl = 'https://parseapi.back4app.com';
  //
  // await Parse().initialize(keyApplicationId, keyParseServerUrl,
  //     clientKey: keyClientKey, debug: true);
  //
  // var firstObject = ParseObject('FirstClass')
  //   ..set('message', 'Hey, Parse is now connected!🙂');
  // await firstObject.save();
  //
  // print('done');

  runApp(const QuickTaskApp());
}

class QuickTaskApp extends StatelessWidget {
  const QuickTaskApp({super.key});

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
