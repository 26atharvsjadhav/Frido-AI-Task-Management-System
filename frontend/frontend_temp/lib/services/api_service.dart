import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  /// Android emulator → 10.0.2.2 maps to your host machine's localhost.
  /// Physical device   → replace with your machine's local IP, e.g. 192.168.x.x
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Singleton
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final Map<String, String> _headers = {'Content-Type': 'application/json'};

  // ─── GET /tasks ─────────────────────────────────────────────────────────────

  Future<List<Task>> getTasks({String? search, String? status}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final uri = Uri.parse('$baseUrl/tasks')
        .replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load tasks (${response.statusCode})');
  }

  // ─── POST /tasks ─────────────────────────────────────────────────────────────

  Future<Task> createTask(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/'),
      headers: _headers,
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return Task.fromJson(json.decode(response.body) as Map<String, dynamic>);
    }
    final detail = _extractDetail(response.body);
    throw Exception(detail ?? 'Failed to create task (${response.statusCode})');
  }

  // ─── PUT /tasks/{id} ─────────────────────────────────────────────────────────

  Future<Task> updateTask(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(json.decode(response.body) as Map<String, dynamic>);
    }
    final detail = _extractDetail(response.body);
    throw Exception(detail ?? 'Failed to update task (${response.statusCode})');
  }

  // ─── DELETE /tasks/{id} ──────────────────────────────────────────────────────

  Future<void> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task (${response.statusCode})');
    }
  }

  // ─── Helper ─────────────────────────────────────────────────────────────────

  String? _extractDetail(String body) {
    try {
      final decoded = json.decode(body) as Map<String, dynamic>;
      return decoded['detail']?.toString();
    } catch (_) {
      return null;
    }
  }
}
