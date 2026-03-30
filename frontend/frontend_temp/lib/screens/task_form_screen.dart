import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  /// Pass a [task] to enter edit mode; omit for create mode.
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  // ─── Form state ──────────────────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String _status = 'To-Do';
  int? _blockedBy;
  bool _loadingDraft = true;

  // ─── Constants ───────────────────────────────────────────────────────────────

  static const _draftKey = 'new_task_draft';
  static const _statuses = ['To-Do', 'In Progress', 'Done'];

  bool get _isEdit => widget.task != null;

  // ─── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _fillFromTask(widget.task!);
      _loadingDraft = false;
    } else {
      _loadDraft();
    }
    // Auto-save draft as user types (create mode only)
    _titleController.addListener(_saveDraft);
    _descController.addListener(_saveDraft);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_saveDraft)
      ..dispose();
    _descController
      ..removeListener(_saveDraft)
      ..dispose();
    super.dispose();
  }

  // ─── Draft helpers ────────────────────────────────────────────────────────────

  void _fillFromTask(Task t) {
    _titleController.text = t.title;
    _descController.text = t.description;
    _dueDate = t.dueDate;
    _status = t.status;
    _blockedBy = t.blockedBy;
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw != null) {
        final m = json.decode(raw) as Map<String, dynamic>;
        setState(() {
          _titleController.text = (m['title'] as String?) ?? '';
          _descController.text = (m['description'] as String?) ?? '';
          if (m['due_date'] != null) {
            _dueDate = DateTime.parse(m['due_date'] as String);
          }
          _status = (m['status'] as String?) ?? 'To-Do';
          _blockedBy = m['blocked_by'] as int?;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingDraft = false);
    }
  }

  Future<void> _saveDraft() async {
    if (_isEdit) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _draftKey,
      json.encode({
        'title': _titleController.text,
        'description': _descController.text,
        'due_date': _dueDate.toIso8601String(),
        'status': _status,
        'blocked_by': _blockedBy,
      }),
    );
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  // ─── Date picker ─────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
      _saveDraft();
    }
  }

  // ─── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TaskProvider>();
    if (provider.isSaving) return; // Guard against double-tap

    final payload = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'due_date': DateFormat('yyyy-MM-dd').format(_dueDate),
      'status': _status,
      'blocked_by': _blockedBy,
    };

    final success = _isEdit
        ? await provider.updateTask(widget.task!.id, payload)
        : await provider.createTask(payload);

    if (!mounted) return;

    if (success) {
      if (!_isEdit) await _clearDraft();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Something went wrong'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingDraft) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Task' : 'New Task',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (_, provider, __) {
          // Exclude self from "Blocked By" options when editing
          final others = provider.tasks
              .where((t) => !_isEdit || t.id != widget.task!.id)
              .toList();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Card 1: title + description ─────────────────────────────
                _Card(children: [
                  _Label('Title'),
                  TextFormField(
                    controller: _titleController,
                    decoration: _dec('Enter task title'),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _Label('Description'),
                  TextFormField(
                    controller: _descController,
                    decoration: _dec('Optional — describe the task'),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ]),

                const SizedBox(height: 12),

                // ── Card 2: due date ─────────────────────────────────────────
                _Card(children: [
                  _Label('Due Date'),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              color: colors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMMM d, yyyy').format(_dueDate),
                            style: const TextStyle(fontSize: 15),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right,
                              color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 12),

                // ── Card 3: status + blocked by ──────────────────────────────
                _Card(children: [
                  _Label('Status'),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: _dec(null),
                    items: _statuses
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                      _saveDraft();
                    },
                  ),
                  const SizedBox(height: 16),
                  _Label('Blocked By  (optional)'),
                  DropdownButtonFormField<int?>(
                    value: _blockedBy,
                    decoration: _dec('None'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ...others.map((t) => DropdownMenuItem<int?>(
                            value: t.id,
                            child: Text(
                              t.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() => _blockedBy = v);
                      _saveDraft();
                    },
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Save button ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: provider.isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: colors.primary.withOpacity(0.45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: provider.isSaving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Text('Saving…',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          )
                        : Text(
                            _isEdit ? 'Update Task' : 'Create Task',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Small helpers ────────────────────────────────────────────────────────────

  InputDecoration _dec(String? hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      );
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.3,
          ),
        ),
      );
}
