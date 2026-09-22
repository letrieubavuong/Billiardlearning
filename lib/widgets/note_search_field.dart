import 'package:flutter/material.dart';

class NoteSearchField extends StatelessWidget {
  const NoteSearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Tìm kiếm bài viết…',
  });

  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: hintText,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: TextField(
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
