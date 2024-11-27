import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

const keyApplicationId = 'kUCPjYcj2s3IhWWRWjwF1BfVNWoaBYQNx3EaNEFN';
const keyClientKey = 'olZHi00LGpSuAQi4wHHHFkpvvbmfSvwg78lMFXzG';
const keyParseServerUrl = 'https://parseapi.back4app.com';

Future<void> initParse() async {
  await Parse().initialize(
    keyApplicationId,
    keyParseServerUrl,
    clientKey: keyClientKey,
    debug: true,
    autoSendSessionId: true,
  );
}
