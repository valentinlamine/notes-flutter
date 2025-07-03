import 'package:flutter/material.dart';

class TagFilterList extends StatelessWidget {
  final List<String> allTags;
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsSelected;
  const TagFilterList({Key? key, required this.allTags, required this.selectedTags, required this.onTagsSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: allTags.length,
      itemBuilder: (context, index) {
        final tag = allTags[index];
        return CheckboxListTile(
          value: selectedTags.contains(tag),
          title: Text(tag),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          onChanged: (checked) {
            final newTags = List<String>.from(selectedTags);
            if (checked == true) {
              newTags.add(tag);
            } else {
              newTags.remove(tag);
            }
            onTagsSelected(newTags);
          },
        );
      },
    );
  }
} 