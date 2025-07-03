import 'package:flutter/material.dart';

class NoteTagsEditor extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  const NoteTagsEditor({Key? key, required this.tags, required this.onAddTag, required this.onRemoveTag}) : super(key: key);

  @override
  State<NoteTagsEditor> createState() => _NoteTagsEditorState();
}

class _NoteTagsEditorState extends State<NoteTagsEditor> {
  final TextEditingController _tagInputController = TextEditingController();

  @override
  void dispose() {
    _tagInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pastelColors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.pink.shade100,
      Colors.teal.shade100,
      Colors.amber.shade100,
    ];
    final pastelColorsDark = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.pink.shade700,
      Colors.teal.shade700,
      Colors.amber.shade700,
    ];
    return Row(
      children: [
        ...widget.tags.asMap().entries.map((entry) {
          final tag = entry.value;
          final color = theme.brightness == Brightness.dark
              ? pastelColorsDark[entry.key % pastelColorsDark.length]
              : pastelColors[entry.key % pastelColors.length];
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Chip(
              label: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              onDeleted: () => widget.onRemoveTag(tag),
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide.none,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity(horizontal: -2, vertical: -2),
            ),
          );
        }),
        Container(
          width: 70,
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? const Color(0xFF23242A) : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _tagInputController,
            decoration: InputDecoration(
              hintText: 'Tag',
              filled: true,
              fillColor: theme.brightness == Brightness.dark ? const Color(0xFF23242A) : Colors.white,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            style: const TextStyle(fontSize: 12),
            onSubmitted: (value) {
              final cleanTag = value.trim();
              if (cleanTag.isNotEmpty && !widget.tags.contains(cleanTag)) {
                widget.onAddTag(cleanTag);
              }
              _tagInputController.clear();
            },
            onEditingComplete: () {
              final cleanTag = _tagInputController.text.trim();
              if (cleanTag.isNotEmpty && !widget.tags.contains(cleanTag)) {
                widget.onAddTag(cleanTag);
              }
              _tagInputController.clear();
            },
          ),
        ),
      ],
    );
  }
} 