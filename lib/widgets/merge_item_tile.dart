import 'package:flutter/material.dart';
import '../models/merge_item.dart';

class MergeItemTile extends StatelessWidget {
  final MergeItem item;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const MergeItemTile({
    required Key key,
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onRemove,
    required this.onTap,
  }) : super(key: key);

  Color _getItemColor(MergeItem item) {
    if (item.isPlaceholder) {
      return Colors.grey.withOpacity(0.2);
    } else if (item.isText && !item.isEmpty) {
      return const Color(0xFFFFB74D).withOpacity(0.2); // Orange
    } else if (item.isFile) {
      return item.importMethod == FileImportMethod.picked 
          ? const Color(0xFF64B5F6).withOpacity(0.2) // Blue
          : const Color(0xFF81C784).withOpacity(0.2); // Green
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Stack(
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                item.isPlaceholder ? Icons.add :
                item.isFile ? Icons.file_present : 
                Icons.text_fields,
                color: (item.isEmpty || item.isPlaceholder) ? Colors.grey : null,
              ),
              title: Text(
                item.displayName,
                style: TextStyle(
                  color: (item.isEmpty || item.isPlaceholder) ? Colors.grey : null,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.isText && !item.isPlaceholder)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onEdit,
                    ),
                  if (!item.isPlaceholder)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onRemove,
                    ),
                ],
              ),
              onTap: onTap,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: _getItemColor(item),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
