import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(GardeMonPoidsApp());
}

class GardeMonPoidsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GardeMonPoids',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginScreen(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('fr', 'FR'),
      ],
      locale: const Locale('fr', 'FR'),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();
    final enteredUsername = _usernameController.text.trim();
    final enteredPassword = _passwordController.text.trim();

    if (enteredUsername.isEmpty || enteredPassword.isEmpty) {
      // Display an error if any field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final storedUsername = prefs.getString('username');
    final storedPassword = prefs.getString('password');

    if (storedUsername == null && storedPassword == null) {
      // No user exists, create a new account
      await prefs.setString('username', enteredUsername);
      await prefs.setString('password', enteredPassword);
      _navigateToHome();
    } else if (enteredUsername == storedUsername &&
        enteredPassword == storedPassword) {
      // Successful login if credentials match
      _navigateToHome();
    } else {
      // If credentials do not match an existing user, create a new user and log in
      await prefs.setString('username', enteredUsername);
      await prefs.setString('password', enteredPassword);
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GardeMonPoids - Connexion')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Nom d\'utilisateur',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              child: Text('Se connecter'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  List<WeightEntry> _weightEntries = [];
  DateTime _selectedDate = DateTime.now();
  late String _currentUser;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting().then((_) {
      _loadWeightEntries();
      _updateDateField();
    });
  }

  void _updateDateField() {
    _dateController.text = DateFormat('dd/MM/yyyy', 'fr_FR').format(_selectedDate);
  }

  Future<void> _loadWeightEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    _currentUser = username; // Store the current user
    final entriesJson = prefs.getString('$username-weightEntries') ?? '[]';
    setState(() {
      _weightEntries = (jsonDecode(entriesJson) as List)
          .map((e) => WeightEntry.fromJson(e))
          .toList();
      _weightEntries.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _saveWeightEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = jsonEncode(_weightEntries.map((e) => e.toJson()).toList());
    await prefs.setString('$_currentUser-weightEntries', entriesJson);
  }

  void _addWeightEntry() {
    if (_weightController.text.isNotEmpty) {
      setState(() {
        _weightEntries.insert(0, WeightEntry(
          weight: double.parse(_weightController.text),
          date: _selectedDate,
        ));
        _weightController.clear();
        _selectedDate = DateTime.now();
        _updateDateField();
      });
      _saveWeightEntries();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateField();
      });
    }
  }

  void _removeWeightEntry(int index) {
    setState(() {
      _weightEntries.removeAt(index);
    });
    _saveWeightEntries();
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GardeMonPoids'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40.0),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Bienvenue, $_currentUser sur GardeMonPoids',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Poids (kg)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addWeightEntry,
                  child: Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _weightEntries.isEmpty
                ? Center(child: Text('Aucune donnée disponible'))
                : Column(
              children: [
                Expanded(child: WeightChart(entries: _weightEntries)),
                Expanded(child: WeightEntryList(
                  entries: _weightEntries,
                  onRemove: _removeWeightEntry,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeightEntryList extends StatelessWidget {
  final List<WeightEntry> entries;
  final Function(int) onRemove;

  WeightEntryList({required this.entries, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          title: Text('${entry.weight} kg'),
          subtitle: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(entry.date)),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => onRemove(index),
          ),
        );
      },
    );
  }
}

class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;

  WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'Aucune donnée à afficher',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < entries.length) {
                    final date = entries[value.toInt()].date;
                    return Text(
                      DateFormat('dd/MM').format(date),
                      style: TextStyle(
                        color: Color(0xff68737d),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()} kg',
                    style: TextStyle(
                      color: Color(0xff67727d),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          minX: 0,
          maxX: entries.length.toDouble() - 1,
          minY: entries.isNotEmpty
              ? entries.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 1
              : 0,
          maxY: entries.isNotEmpty
              ? entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 1
              : 0,
          lineBarsData: [
            LineChartBarData(
              spots: entries.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.weight);
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.blue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class WeightEntry {
  final double weight;
  final DateTime date;

  WeightEntry({required this.weight, required this.date});

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      weight: json['weight'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }
}
