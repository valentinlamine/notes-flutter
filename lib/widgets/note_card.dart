import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../services/notes_provider.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({
    Key? key,
    required this.note,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: Markdown(
                  data: note.content,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  styleSheet: MarkdownStyleSheet(
                    p: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              if (note.tags.isNotEmpty) const Divider(),
              Wrap(
                spacing: 4,
                children: note.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Modifié le ${DateFormat('dd/MM/yyyy à HH:mm').format(note.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open, size: 20),
                    tooltip: 'Afficher dans le Finder',
                    onPressed: () async {
                      final provider = Provider.of<NotesProvider>(context, listen: false);
                      await provider.revealInFinder(note);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 