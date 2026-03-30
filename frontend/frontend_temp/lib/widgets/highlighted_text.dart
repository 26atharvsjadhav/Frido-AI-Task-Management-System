import 'package:flutter/material.dart';

/// Renders [text] with every occurrence of [highlight] wrapped in
/// [highlightStyle]. Case-insensitive. Falls back to plain [Text] when
/// [highlight] is empty.
class HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle style;
  final TextStyle highlightStyle;
  final int? maxLines;
  final TextOverflow overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.highlight,
    required this.style,
    required this.highlightStyle,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final lowerHL = highlight.toLowerCase();
    int cursor = 0;

    while (cursor < text.length) {
      final idx = lower.indexOf(lowerHL, cursor);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(cursor), style: style));
        break;
      }
      if (idx > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, idx), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + highlight.length),
        style: highlightStyle,
      ));
      cursor = idx + highlight.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
