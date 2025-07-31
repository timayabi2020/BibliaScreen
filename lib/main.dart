import 'dart:convert';
import 'package:bibliascreen/review.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(BibleStudyApp());
}

class BibleStudyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Study Memory Companion',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: BibleNotesScreen(),
      routes: {
        '/review': (_) => ReviewHistoryScreen(),
      },
    );
  }
}

class BibleNotesScreen extends StatefulWidget {
  @override
  _BibleNotesScreenState createState() => _BibleNotesScreenState();
}

class _BibleNotesScreenState extends State<BibleNotesScreen> {
  final _notesController = TextEditingController();
  final _userId = 'tim_mayabi';
  final _token = 'testtoken123';
  final _apiBase = 'https://biblia-production-1c3d.up.railway.app';

  String _summary = '';
  List<Map<String, dynamic>> _flashcards = [];
  bool _loading = false;

  Future<void> analyzeNotes() async {
    final url = Uri.parse('$_apiBase/analyze');
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'user_id': _userId,
      'notes': _notesController.text,
    });

    setState(() => _loading = true);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _summary = data['summary'];
        _flashcards = List<Map<String, dynamic>>.from(data['flashcards']);
        _loading = false;
      });
    } else {
      print('Error: ${response.body}');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bible Study Companion'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/review'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _notesController,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Enter your Bible study notes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: analyzeNotes,
                    child: Text('Analyze Notes'),
                  ),
            const SizedBox(height: 20),
            if (_summary.isNotEmpty) ...[
              Text('📝 Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_summary),
              SizedBox(height: 16),
              Text('🧠 Flashcards:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._flashcards.map((fc) => Card(
                    child: ListTile(
                      title: Text(fc['question']),
                      subtitle: Text(fc['answer']),
                    ),
                  )),
            ]
          ],
        ),
      ),
    );
  }
}