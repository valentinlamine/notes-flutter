import 'package:flutter/material.dart';

class SidebarActionTile extends StatelessWidget {
  final IconData? icon;
  final String text;
  final VoidCallback onTap;
  final bool enabled;
  const SidebarActionTile({Key? key, required this.icon, required this.text, required this.onTap, this.enabled = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15);
    return ListTile(
      leading: SizedBox(
        width: 24,
        height: 24,
        child: icon != null
            ? Center(child: Icon(icon, size: 22))
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      title: Text(
        text,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      enabled: enabled,
      onTap: enabled ? onTap : null,
      dense: true,
      visualDensity: VisualDensity.compact,
      minLeadingWidth: 28,
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
} 