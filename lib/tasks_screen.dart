import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'task_model.dart';
import 'screens/login_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> _tasks = [];
  final _textController = TextEditingController();
  bool _isLoading = true;
  Set<Task> _selectedTasks = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = await ParseUser.currentUser() as ParseUser;
      final QueryBuilder<Task> query = QueryBuilder<Task>(Task(currentUser));
      // ..whereEqualTo('user', currentUser);
      final response = await query.find();

      setState(() {
        _tasks = response.cast<Task>();
        _isLoading = false;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTask(String title) async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    if (currentUser == null) return;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    final task = Task(currentUser)
      ..title = title
      ..isCompleted = false
      ..dueDate = pickedDate;

    try {
      await task.save();
      await _loadTasks();
      _textController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleTask(Task task, bool? value) async {
    if (value == null) return;

    task.isCompleted = value;
    try {
      await task.save();
      await _loadTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    if (currentUser != null) {
      await currentUser.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _deleteSelectedTasks() async {
    try {
      for (final task in _selectedTasks) {
        await task.delete();
      }
      setState(() {
        _selectedTasks.clear();
        _isSelectionMode = false;
      });
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting tasks: ${e.toString()}')),
      );
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Add a new task',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (_textController.text.isNotEmpty) {
                            _addTask(_textController.text);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
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
                              : null,
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
                                        _toggleTask(task, value),
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
                ),
              ],
            ),
    );
  }
}
