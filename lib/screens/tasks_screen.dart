import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../task_model.dart';
import 'login_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  Set<Task> _selectedTasks = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() => _isLoading = true);

    ParseUser.currentUser().then((currentUser) {
      final QueryBuilder<Task> query =
          QueryBuilder<Task>(Task(currentUser as ParseUser));
      return query.find();
    }).then((response) {
      setState(() {
        _tasks = response.cast<Task>();
        _isLoading = false;
      });
    }).catchError((e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    });
  }

  void _showTaskModal({Task? task, ParseUser? currentUser}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final dateController = TextEditingController(
      text: task?.dueDate != null
          ? '${task!.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
          : '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    );
    DateTime selectedDate = task?.dueDate ?? DateTime.now();

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
          task.save().then((_) {
            return _loadTasks();
          }).catchError((e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating task: ${e.toString()}')),
            );
          });
        } else if (currentUser != null) {
          final newTask = Task(currentUser)
            ..title = titleController.text
            ..isCompleted = false
            ..dueDate = selectedDate;

          newTask.save().then((_) {
            return _loadTasks();
          }).catchError((e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error creating task: ${e.toString()}')),
            );
          });
        }
      }
    });
  }

  void _toggleTask(Task task, bool? value) {
    if (value == null) return;

    task.isCompleted = value;
    task.save().then((_) {
      return _loadTasks();
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: ${e.toString()}')),
      );
    });
  }

  void _logout() {
    ParseUser.currentUser().then((currentUser) {
      if (currentUser != null) {
        return currentUser.logout();
      }
    }).then((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  void _deleteSelectedTasks() {
    Future.wait(_selectedTasks.map((task) => task.delete())).then((_) {
      setState(() {
        _selectedTasks.clear();
        _isSelectionMode = false;
      });
      return _loadTasks();
    }).catchError((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting tasks: ${e.toString()}')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _deleteSelectedTasks,
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                ParseUser.currentUser().then((currentUser) {
                  if (currentUser != null) {
                    _showTaskModal(currentUser: currentUser as ParseUser);
                  }
                });
              },
              child: const Icon(Icons.add),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _tasks.length,
              padding: const EdgeInsets.all(8.0),
              itemBuilder: (context, index) {
                final task = _tasks[index];
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
                        : () => _showTaskModal(task: task),
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
                              onChanged: (value) => _toggleTask(task, value),
                            ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
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
            ),
    );
  }
}
