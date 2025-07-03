import 'package:flutter/material.dart';

class SidebarActionTile extends StatefulWidget {
  final IconData? icon;
  final String text;
  final VoidCallback onTap;
  final bool enabled;
  const SidebarActionTile({Key? key, required this.icon, required this.text, required this.onTap, this.enabled = true}) : super(key: key);

  @override
  State<SidebarActionTile> createState() => _SidebarActionTileState();
}

class _SidebarActionTileState extends State<SidebarActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15, color: Theme.of(context).colorScheme.onSurface);
    final hoverColor = Theme.of(context).colorScheme.primary.withOpacity(0.08);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _hovered && widget.enabled ? hoverColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: widget.icon != null
                      ? Center(child: Icon(widget.icon, size: 22))
                      : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.text,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 