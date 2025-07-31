import 'dart:convert';
import 'package:bibliascreen/review.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(BibleStudyApp());
}

class BibleStudyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Study Memory Companion',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
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
  final _apiBase = 'https://biblia-production-1c3d.up.railway.app';

  String _displayedSummary = '';
  String _summary = '';
  Timer? _typingTimer;
  List<Map<String, dynamic>> _flashcards = [];
  bool _loading = false;

  void animateSummary(String fullText) {
    _typingTimer?.cancel(); // Cancel any existing animation
    _displayedSummary = '';
    int index = 0;
    const duration = Duration(milliseconds: 30); // typing speed

    _typingTimer = Timer.periodic(duration, (timer) {
      if (index >= fullText.length) {
        timer.cancel();
      } else {
        setState(() {
          _displayedSummary += fullText[index];
        });
        index++;
      }
    });
  }

  Future<void> analyzeNotes() async {
    final url = Uri.parse('$_apiBase/analyze');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'user_id': _userId,
      'notes': _notesController.text,
    });

    setState(() {
      _loading = true;
      _summary = '';
      _displayedSummary = '';
      _flashcards = [];
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _summary = data['summary'];
        _loading = false;
      });
      animateSummary(data['summary']);

      // Wait for the animation to complete before showing flashcards
      Future.delayed(Duration(milliseconds: data['summary'].length * 30 + 300), () {
        setState(() {
          _flashcards = List<Map<String, dynamic>>.from(data['flashcards']);
        });
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _notesController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: '✍️ Enter your Bible study notes...',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => _notesController.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _loading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: analyzeNotes,
                        icon: Icon(Icons.insights),
                        label: Text('Analyze Notes'),
                      ),
                    ),
              const SizedBox(height: 24),
              if (_summary.isNotEmpty) ...[
                Text('📌 Summary', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(_displayedSummary),
                ),
                const SizedBox(height: 24),
                Text('🧠 Flashcards', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._flashcards.map((fc) => Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        title: Text(fc['question'], style: TextStyle(fontWeight: FontWeight.w600)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(fc['answer']),
                          )
                        ],
                      ),
                    )),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
