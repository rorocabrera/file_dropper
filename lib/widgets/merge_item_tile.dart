import 'package:flutter/material.dart';
import '../models/merge_item.dart';

class MergeItemTile extends StatelessWidget {
  final MergeItem item;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  final int index;

  const MergeItemTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onRemove,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Card(
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
    );
  }
}