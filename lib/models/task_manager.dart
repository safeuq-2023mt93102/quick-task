import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../task_model.dart';
import 'dart:developer' as developer;

class TaskModel extends ChangeNotifier {
  TaskModel() {
    reloadTasks();
  }

  List<Task> _tasks = [];

  Future _loader = Future.value(true);

  Future get loader => _loader;

  List<Task> get tasks => List.unmodifiable(_tasks);

  Future reloadTasks() {
    _loader = ParseUser.currentUser().then((currentUser) {
      if (currentUser == null) {
        return Future.value(_tasks);
      }
      final QueryBuilder<Task> query = QueryBuilder<Task>(Task());
      return query.find();
    }).then((response) {
      _tasks = response;
      notifyListeners();
      return _tasks;
    });
    return _loader;
  }

  Future<Task> createTask(String title, DateTime dueDate) {
    final task = Task()
      ..title = title
      ..isCompleted = false
      ..dueDate = dueDate;
    notifyListeners();
    final int index = _tasks.length;
    _tasks.add(task);
    notifyListeners();

    return ParseUser.currentUser().then((currentUser) {
      if (currentUser == null) {
        return task;
      }
      task.user = currentUser;
      return task.save().then((response) {
        if (response.success) {
          final newTask = response.results!.first as Task;
          _tasks[index] = newTask;
          return newTask;
        }
        throw response.error?.message ?? 'Failed to create task';
      });
    });
  }

  Future<Task> updateTask(Task task, [int? index]) {
    index ??= _tasks.indexWhere((t) => t.objectId == task.objectId);
    if (index == -1) {
      return Future.error('Object index not found');
    }
    _tasks[index] = task;
    notifyListeners();

    developer.log("updateTask outside", error: task.toString());
    return task.save().then((response) {
      if (response.success) {
        var newTask = response.results!.first;
        if (index != -1) {
          _tasks[index!] = newTask;
        }
        developer.log("updateTask inside", error: newTask.toString());
        return newTask;
      }
      throw response.error?.message ?? 'Failed to update task';
    });
  }

  Future<void> deleteTasks(List<Task> tasksToDelete) {
    _tasks.removeWhere(
        (task) => tasksToDelete.any((t) => t.objectId == task.objectId));
    notifyListeners();
    return Future.wait(tasksToDelete.map((task) => task.delete()));
  }
}
