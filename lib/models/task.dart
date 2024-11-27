import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class Task extends ParseObject implements ParseCloneable {
  Task() : super('Task') {
    final ParseACL acl = ParseACL()
      ..setPublicReadAccess(allowed: false)
      ..setPublicWriteAccess(allowed: false);

    setACL(acl);
  }

  Task.clone() : this();

  @override
  Task clone(Map<String, dynamic> map) {
    var clone = Task.clone()
      ..fromJson(map);
    if (clone.user != null) {
      clone._setUserAcl(clone.user!);
    }
    return clone;
  }

  String get title => get<String>('title') ?? '';

  set title(String title) => set<String>('title', title);

  bool get isCompleted => get<bool>('isCompleted') ?? false;

  set isCompleted(bool isCompleted) => set<bool>('isCompleted', isCompleted);

  DateTime? get dueDate => get<DateTime>('dueDate');

  set dueDate(DateTime? date) => set<DateTime?>('dueDate', date);

  ParseUser? get user => get<ParseUser>('user');

  set user(ParseUser? user) => _setUser(user);

  void _setUser(ParseUser? user) {
    if (user == null) {
      return;
    }
    set('user', user);
    _setUserAcl(user);
  }

  void _setUserAcl(ParseUser user) {
    final ParseACL acl = ParseACL()
      ..setReadAccess(userId: user.objectId!, allowed: true)
      ..setWriteAccess(userId: user.objectId!, allowed: true);
    setACL(acl);
  }
}
