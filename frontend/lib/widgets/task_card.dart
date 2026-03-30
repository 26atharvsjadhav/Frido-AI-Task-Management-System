import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import 'highlighted_text.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isBlocked;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.isBlocked,
    required this.searchQuery,
    required this.onTap,
    required this.onDelete,
  });

  // ─── Status helpers ──────────────────────────────────────────────────────────

  static Color statusColor(String status) => switch (status) {
        'To-Do' => const Color(0xFF6366F1),
        'In Progress' => const Color(0xFFF59E0B),
        'Done' => const Color(0xFF10B981),
        _ => Colors.grey,
      };

  static IconData statusIcon(String status) => switch (status) {
        'To-Do' => Icons.radio_button_unchecked,
        'In Progress' => Icons.pending_outlined,
        'Done' => Icons.check_circle_outline,
        _ => Icons.help_outline,
      };

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = statusColor(task.status);
    final tt = Theme.of(context).textTheme;
    final isDue = !isBlocked &&
        task.status != 'Done' &&
        task.dueDate.isBefore(DateTime.now());

    return Opacity(
      opacity: isBlocked ? 0.48 : 1.0,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isBlocked ? 0 : 2,
        shadowColor: Colors.black12,
        color: isBlocked ? const Color(0xFFF3F4F6) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isBlocked
              ? const BorderSide(color: Color(0xFFD1D5DB))
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: icon + title + status badge ──────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(statusIcon(task.status),
                          color: isBlocked ? Colors.grey : color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: HighlightedText(
                        text: task.title,
                        highlight: searchQuery,
                        maxLines: 2,
                        style: tt.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isBlocked ? Colors.grey : Colors.black87,
                          decoration: task.status == 'Done'
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: Colors.grey,
                        ),
                        highlightStyle: tt.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          backgroundColor: const Color(0xFFFFE082),
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: task.status, color: color),
                  ],
                ),

                // ── Description ──────────────────────────────────────────────
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Text(
                      task.description,
                      style: tt.bodySmall!.copyWith(
                        color: isBlocked
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Row 2: due date + blocked badge ──────────────────────────
                Row(
                  children: [
                    const SizedBox(width: 30),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: isDue
                          ? Colors.red.shade400
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(task.dueDate),
                      style: tt.bodySmall!.copyWith(
                        color: isDue
                            ? Colors.red.shade400
                            : Colors.grey.shade500,
                        fontWeight:
                            isDue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (isBlocked) ...[
                      Icon(Icons.lock_outline,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Blocked',
                        style: tt.bodySmall!.copyWith(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
