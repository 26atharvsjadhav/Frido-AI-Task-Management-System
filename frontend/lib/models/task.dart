class Task {
  final int id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status;
  final int? blockedBy;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedBy,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as int,
        title: json['title'] as String,
        description: (json['description'] as String?) ?? '',
        dueDate: DateTime.parse(json['due_date'] as String),
        status: json['status'] as String,
        blockedBy: json['blocked_by'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'due_date':
            '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
        'status': status,
        'blocked_by': blockedBy,
      };

  /// Returns true if this task's blocker exists and is NOT yet "Done".
  bool isBlockedBy(List<Task> allTasks) {
    if (blockedBy == null) return false;
    try {
      final blocker = allTasks.firstWhere((t) => t.id == blockedBy);
      return blocker.status != 'Done';
    } catch (_) {
      return false; // blocker task was deleted
    }
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    int? blockedBy,
    bool clearBlockedBy = false,
  }) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        blockedBy: clearBlockedBy ? null : (blockedBy ?? this.blockedBy),
      );
}
