import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../task_model.dart';
import 'dart:developer' as developer;

class TaskManager {
  static final TaskManager _instance = TaskManager._internal();

  factory TaskManager() => _instance;

  TaskManager._internal();

  List<Task> _tasks = [];

  List<Task> get tasks => List.unmodifiable(_tasks);

  Future<List<Task>> loadTasks() {
    return ParseUser.currentUser().then((currentUser) {
      if (currentUser == null) {
        throw 'No user logged in';
      }
      final QueryBuilder<Task> query = QueryBuilder<Task>(Task());
      return query.find();
    }).then((response) {
      _tasks = response;
      return _tasks;
    });
  }

  Future<Task> createTask(String title, DateTime dueDate) {
    return ParseUser.currentUser().then((currentUser) {
      if (currentUser == null) {
        throw 'No user logged in';
      }
      final task = Task()
        ..user = currentUser
        ..title = title
        ..isCompleted = false
        ..dueDate = dueDate;
      return task.save().then((response) {
        if (response.success) {
          final newTask = response.results!.first as Task;
          _tasks.add(newTask);
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

  Future<Task> toggleTaskCompletion(Task task) {
    task.isCompleted = !task.isCompleted;
    return updateTask(task);
  }

  Future<void> deleteTasks(List<Task> tasksToDelete) {
    return Future.wait(tasksToDelete.map((task) => task.delete())).then((_) {
      _tasks.removeWhere(
          (task) => tasksToDelete.any((t) => t.objectId == task.objectId));
    });
  }
}
