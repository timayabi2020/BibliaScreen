import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For formatting timestamps

class ReviewHistoryScreen extends StatefulWidget {
  @override
  _ReviewHistoryScreenState createState() => _ReviewHistoryScreenState();
}

class _ReviewHistoryScreenState extends State<ReviewHistoryScreen> {
  final _userId = 'tim_mayabi';
  final _token = 'testtoken123';
  final _apiBase = 'https://biblia-production-1c3d.up.railway.app';

  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _filtered = [];
  String _filter = '';

  @override
  void initState() {
    super.initState();
    fetchSessions();
  }

  void fetchSessions() async {
    final url = Uri.parse('$_apiBase/review?user_id=$_userId');
    final headers = {'Authorization': 'Bearer $_token'};

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      setState(() {
        _sessions = data;
        _filtered = data;
      });
    } else {
      print('Review fetch error: ${response.body}');
    }
  }

  void applyFilter(String keyword) {
    setState(() {
      _filter = keyword;
      _filtered = _sessions
          .where((s) => s['summary']
              .toLowerCase()
              .contains(keyword.toLowerCase()))
          .toList();
    });
  }

  String formatTimestamp(dynamic ts) {
    if (ts == null || ts == '') return '🕒 Unknown';
    try {
      final dt = DateTime.parse(ts);
      return DateFormat.yMMMEd().add_jm().format(dt); // e.g., Jul 31, 2025 8:03 PM
    } catch (e) {
      return '🕒 Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cardColor = brightness == Brightness.dark ? Colors.grey[900] : Colors.white;
    final summaryColor = brightness == Brightness.dark ? Colors.yellow[100] : Colors.yellow[50];

    return Scaffold(
      appBar: AppBar(
        title: Text('Review History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: applyFilter,
              decoration: InputDecoration(
                labelText: 'Filter by keyword in summary...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(child: Text("No sessions found."))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    itemBuilder: (_, index) {
                      final session = _filtered[index];
                      final summary = session['summary'];
                      final flashcards = List<Map<String, dynamic>>.from(session['flashcards']);
                      final timestamp = formatTimestamp(session['timestamp']);

                      return Card(
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(timestamp, style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Text('📌 Summary',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: summaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  summary,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: brightness == Brightness.dark
                                            ? Colors.black
                                            : Colors.black87,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text('🧠 Flashcards',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              ...flashcards.map((fc) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: ExpansionTile(
                                      collapsedShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      title: Text(fc['question'],
                                          style: TextStyle(fontWeight: FontWeight.w600)),
                                      children: [
                                        ListTile(
                                          title: Text(fc['answer']),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
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
