import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/task_model.dart';
import 'login_screen.dart';
import 'dart:developer' as developer;

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() {
    return _TasksScreenState();
  }
}

class _TasksScreenState extends State<TasksScreen> {
  bool _isLoggedIn = false;
  final Set<Task> _selectedTasks = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    _updateLoginState();
    super.initState();
  }

  void _updateLoginState() {
    ParseUser.currentUser()
        .then((user) => {setState(() => _isLoggedIn = user != null)});
  }

  void _showTaskModal(TaskModel taskManager, {Task? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    DateTime selectedDate = task?.dueDate ?? DateTime.now();
    final dateController = TextEditingController(
      text: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
    );

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task == null ? 'New Task' : 'Edit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Due Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  selectedDate = picked;
                  dateController.text =
                      '${picked.day}/${picked.month}/${picked.year}';
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isEmpty) return;
              Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((result) {
      if (result == true) {
        if (task != null) {
          task.title = titleController.text;
          task.dueDate = selectedDate;
          taskManager.updateTask(task).then((_) => null).catchError(
              (e) => showError('Error updating task: ${e.toString()}'));
        } else {
          taskManager
              .createTask(titleController.text, selectedDate)
              .then((_) => null)
              .catchError(
                  (e) => showError('Error creating task: ${e.toString()}'));
        }
      }
    });
  }

  Null showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    return null;
  }

  void _toggleTask(TaskModel taskModel, Task task, bool? value, [int? index]) {
    if (value == null) return;
    task.isCompleted = value;
    taskModel.updateTask(task, index).then((_) => null).catchError((e) {
      showError('Error updating task: ${e.toString()}');
    });
  }

  void _logout(TaskModel taskModel) {
    ParseUser.currentUser().then((user) {
      if (user != null) {
        return user.logout();
      }
    }).then((_) {
      setState(() {
        _isLoggedIn = false;
      });
      taskModel.reloadTasks();
    });
  }

  void _login(TaskModel taskModel) {
    Navigator.push(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()))
        .then((_) {
      _updateLoginState();
      taskModel.reloadTasks();
    });
  }

  void _deleteSelectedTasks(TaskModel taskModel) {
    taskModel.deleteTasks(_selectedTasks.toList()).then((_) {
      setState(() {
        _selectedTasks.clear();
        _isSelectionMode = false;
      });
    }).catchError((e) => showError('Error deleting tasks: ${e.toString()}'));
  }

  @override
  Widget build(BuildContext context) {
    var taskModel = context.watch<TaskModel>();
    return buildScaffold(context, taskModel);
  }

  Scaffold buildScaffold(BuildContext context, TaskModel taskModel) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedTasks.length} selected')
            : const Text('My Tasks'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedTasks.clear();
                    _isSelectionMode = false;
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteSelectedTasks(taskModel),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => (TaskModel taskModel) {
                taskModel.reloadTasks();
              }(taskModel),
            ),
          _isLoggedIn
              ? IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _logout(taskModel),
                )
              : IconButton(
                  icon: const Icon(Icons.login),
                  onPressed: () => _login(taskModel),
                ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _showTaskModal(taskModel),
              child: const Icon(Icons.add),
            ),
      body: taskModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : taskModel.tasks.isEmpty
              ? const Center(child: Text("No tasks"))
              : buildTaskList(taskModel),
    );
  }

  ListView buildTaskList(TaskModel taskModel) {
    return ListView.builder(
      itemCount: taskModel.tasks.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final task = taskModel.tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          color: _selectedTasks.contains(task)
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: InkWell(
            onLongPress: () {
              setState(() {
                _isSelectionMode = true;
                _selectedTasks.add(task);
              });
            },
            onTap: _isSelectionMode
                ? () {
                    setState(() {
                      if (_selectedTasks.contains(task)) {
                        _selectedTasks.remove(task);
                        if (_selectedTasks.isEmpty) {
                          _isSelectionMode = false;
                        }
                      } else {
                        _selectedTasks.add(task);
                      }
                    });
                  }
                : () => _showTaskModal(taskModel, task: task),
            child: ListTile(
              leading: _isSelectionMode
                  ? Checkbox(
                      value: _selectedTasks.contains(task),
                      onChanged: (selected) {
                        setState(() {
                          if (selected ?? false) {
                            _selectedTasks.add(task);
                          } else {
                            _selectedTasks.remove(task);
                            if (_selectedTasks.isEmpty) {
                              _isSelectionMode = false;
                            }
                          }
                        });
                      },
                    )
                  : Checkbox(
                      value: task.isCompleted,
                      onChanged: (value) =>
                          _toggleTask(taskModel, task, value, index),
                    ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: task.dueDate != null
                  ? Text(
                      'Due: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}
