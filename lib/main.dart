import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/addTask': (context) => AddTaskScreen(),
        '/taskList': (context) => TaskListScreen(),
      },
    );
  }
}

class Task {
  int id;
  String title;

  Task({required this.id, required this.title});

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title};
  }
}

class DatabaseHelper {
  late Database _database;

  Future open() async {
    _database = await openDatabase(
      'tasks.db',
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT)',
        );
      },
    );
  }

  Future<int> insert(Task task) async {
    await open(); // Ensure database is open
    return await _database.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasks() async {
    await open(); // Ensure database is open
    List<Map<String, dynamic>> maps = await _database.query('tasks');
    return List.generate(maps.length, (i) {
      return Task(id: maps[i]['id'], title: maps[i]['title']);
    });
  }

  Future<int> update(Task task) async {
    await open(); // Ensure database is open
    return await _database.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(int taskId) async {
    await open(); // Ensure database is open
    return await _database.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/addTask');
              },
              child: Text('Adicionar Tarefa'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/taskList');
              },
              child: Text('Tarefas Cadastradas'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _taskController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _databaseHelper.open();
  }

  void _addTask() {
    Task task = Task(
      id: DateTime.now().millisecondsSinceEpoch,
      title: _taskController.text,
    );
    _databaseHelper.insert(task).then((id) => {
          _taskController.clear(),
          Navigator.pop(context),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _taskController,
              decoration: InputDecoration(labelText: 'Descreva a tarefa'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addTask,
              child: Text('Adicionar tarefa'),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _refreshTaskList();
  }

  Future<void> _refreshTaskList() async {
    await _databaseHelper.open(); // Ensure database is open
    _databaseHelper.getTasks().then((tasks) {
      setState(() {
        _tasks = tasks;
      });
    });
  }

  void _deleteTask(int taskId) {
    _databaseHelper.delete(taskId).then((value) {
      _refreshTaskList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task List'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_tasks[index].title),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditTaskScreen(task: _tasks[index]),
                      ),
                    ).then((value) {
                      _refreshTaskList();
                    });
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteTask(_tasks[index].id);
                    },
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

class EditTaskScreen extends StatefulWidget {
  final Task task;

  EditTaskScreen({required this.task});

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final TextEditingController _taskController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _taskController.text = widget.task.title;
  }

  void _updateTask() {
    Task updatedTask = Task(
      id: widget.task.id,
      title: _taskController.text,
    );

    _databaseHelper.update(updatedTask).then((value) {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar tarefa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _taskController,
              decoration: InputDecoration(labelText: 'Editar tarefa'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateTask,
              child: Text('Atualizar Tarefa'),
            ),
          ],
        ),
      ),
    );
  }
}
