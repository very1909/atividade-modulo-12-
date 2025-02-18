// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestão de Planetas',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomeScreen(),
    );
  }
}

// lib/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('planets.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE planets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        distance REAL NOT NULL,
        diameter INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertPlanet(Map<String, dynamic> planet) async {
    final db = await database;
    return await db.insert('planets', planet);
  }

  Future<List<Map<String, dynamic>>> getPlanets() async {
    final db = await database;
    return await db.query('planets');
  }

  Future<int> deletePlanet(int id) async {
    final db = await database;
    return await db.delete('planets', where: 'id = ?', whereArgs: [id]);
  }
}

// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'planet_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _planets = [];

  @override
  void initState() {
    super.initState();
    _loadPlanets();
  }

  Future<void> _loadPlanets() async {
    final planets = await DatabaseHelper.instance.getPlanets();
    setState(() {
      _planets = planets;
    });
  }

  Future<void> _deletePlanet(int id) async {
    await DatabaseHelper.instance.deletePlanet(id);
    _loadPlanets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planetas')),
      body: ListView.builder(
        itemCount: _planets.length,
        itemBuilder: (context, index) {
          final planet = _planets[index];
          return ListTile(
            title: Text(planet['name']),
            subtitle: Text('Distância: ${planet['distance']} UA'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletePlanet(planet['id']),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PlanetFormScreen()),
          );
          _loadPlanets();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// lib/screens/planet_form_screen.dart
import 'package:flutter/material.dart';
import '../database_helper.dart';

class PlanetFormScreen extends StatefulWidget {
  const PlanetFormScreen({super.key});

  @override
  _PlanetFormScreenState createState() => _PlanetFormScreenState();
}

class _PlanetFormScreenState extends State<PlanetFormScreen> {
  final _nameController = TextEditingController();
  final _distanceController = TextEditingController();
  final _diameterController = TextEditingController();

  Future<void> _savePlanet() async {
    if (_nameController.text.isEmpty ||
        _distanceController.text.isEmpty ||
        _diameterController.text.isEmpty) {
      return;
    }

    final planet = {
      'name': _nameController.text,
      'distance': double.parse(_distanceController.text),
      'diameter': int.parse(_diameterController.text),
    };

    await DatabaseHelper.instance.insertPlanet(planet);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Planeta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(controller: _distanceController, decoration: const InputDecoration(labelText: 'Distância (UA)')),
            TextField(controller: _diameterController, decoration: const InputDecoration(labelText: 'Diâmetro (km)')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _savePlanet, child: const Text('Salvar')),
          ],
        ),
      ),
    );
  }
}

// pubspec.yaml
name: crud_planetas_flutter
description: CRUD para gerenciar informações de planetas
version: 1.0.0+1

environment:
  sdk: ">=2.18.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.2.0+3
  path_provider: ^2.0.11

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
