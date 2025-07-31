import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReviewHistoryScreen extends StatefulWidget {
  @override
  _ReviewHistoryScreenState createState() => _ReviewHistoryScreenState();
}

class _ReviewHistoryScreenState extends State<ReviewHistoryScreen> {
  final _userId = 'tim_mayabi';
  final _token = 'testtoken123';
  final _apiBase = 'https://your-api.azurewebsites.net';

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

  @override
  Widget build(BuildContext context) {
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
                    itemCount: _filtered.length,
                    itemBuilder: (_, index) {
                      final session = _filtered[index];
                      return ExpansionTile(
                        title: Text(session['summary']),
                        children: session['flashcards']
                            .map<Widget>((fc) => ListTile(
                                  title: Text(fc['question']),
                                  subtitle: Text(fc['answer']),
                                ))
                            .toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}