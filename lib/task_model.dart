import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class Task extends ParseObject implements ParseCloneable {
  Task(ParseUser user) : super('Task') {
    final ParseACL acl = ParseACL()
      ..setPublicReadAccess(allowed: false)
      ..setPublicWriteAccess(allowed: false);

    setACL(acl);
    _setUser(user);
  }

  Task.clone() : super('Task');

  @override
  Task clone(Map<String, dynamic> map) => Task.clone()..fromJson(map);

  String get title => get<String>('title') ?? '';
  set title(String title) => set<String>('title', title);

  bool get isCompleted => get<bool>('isCompleted') ?? false;
  set isCompleted(bool isCompleted) => set<bool>('isCompleted', isCompleted);

  DateTime? get dueDate => get<DateTime>('dueDate');
  set dueDate(DateTime? date) => set<DateTime?>('dueDate', date);

  ParseUser get user => get<ParseUser>('user')!;

  void _setUser(ParseUser user) {
    set('user', user);
    final ParseACL acl = ParseACL()
      ..setReadAccess(userId: user.objectId!, allowed: true)
      ..setWriteAccess(userId: user.objectId!, allowed: true);
    setACL(acl);
  }
}
