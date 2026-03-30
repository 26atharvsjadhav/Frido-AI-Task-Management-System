import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _statusFilter = 'All';

  // ─── Getters ────────────────────────────────────────────────────────────────

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  // ─── Load ────────────────────────────────────────────────────────────────────

  Future<void> loadTasks() async {
    _set(loading: true, error: null);

    try {
      _tasks = await _api.getTasks(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _statusFilter == 'All' ? null : _statusFilter,
      );
    } catch (e) {
      _errorMessage = _clean(e);
    } finally {
      _set(loading: false);
    }
  }

  // ─── Filter helpers ──────────────────────────────────────────────────────────

  /// Called by the debounced search; just stores the value.
  /// Caller is responsible for calling loadTasks() after debounce.
  void setSearchQuery(String query) {
    _searchQuery = query;
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    loadTasks();
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────────

  Future<bool> createTask(Map<String, dynamic> data) async {
    _set(saving: true, error: null);

    try {
      final task = await _api.createTask(data);
      _tasks.add(task);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _clean(e);
      notifyListeners();
      return false;
    } finally {
      _set(saving: false);
    }
  }

  Future<bool> updateTask(int id, Map<String, dynamic> data) async {
    _set(saving: true, error: null);

    try {
      final updated = await _api.updateTask(id, data);
      final idx = _tasks.indexWhere((t) => t.id == id);
      if (idx != -1) _tasks[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _clean(e);
      notifyListeners();
      return false;
    } finally {
      _set(saving: false);
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      await _api.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _clean(e);
      notifyListeners();
      return false;
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  void _set({bool? loading, bool? saving, String? error}) {
    if (loading != null) _isLoading = loading;
    if (saving != null) _isSaving = saving;
    if (error != null || error == null) _errorMessage = error;
    notifyListeners();
  }

  String _clean(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
}
