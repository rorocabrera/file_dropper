import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../models/merge_item.dart';
import 'merge_item_tile.dart';

class FileDropZone extends StatelessWidget {
  final List<MergeItem> items;
  final bool isDragging;
  final Function(DropDoneDetails) onDragDone;
  final Function(bool) onDraggingChanged;
  final Function(int, int) onReorder;
  final Function(MergeItem) onEdit;
  final Function(String) onRemove;
  final Function(int) onPlaceholderTap;
  final Function(MergeItem) onItemTap;

  const FileDropZone({
    super.key,
    required this.items,
    required this.isDragging,
    required this.onDragDone,
    required this.onDraggingChanged,
    required this.onReorder,
    required this.onEdit,
    required this.onRemove,
    required this.onPlaceholderTap,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: onDragDone,
      onDragEntered: (_) => onDraggingChanged(true),
      onDragExited: (_) => onDraggingChanged(false),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDragging ? Colors.blue : Colors.grey,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: items.isEmpty
            ? const Center(
                child: Text(
                  'Drop files here',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              )
            : ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: items.length,
                padding: const EdgeInsets.all(8),
                onReorder: onReorder,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return MergeItemTile(
                    key: Key(item.id),
                    item: item,
                    index: index,
                    onEdit: () => onEdit(item),
                    onRemove: () => onRemove(item.id),
                    onTap: item.isPlaceholder 
                      ? () => onPlaceholderTap(index)
                      : () => onItemTap(item),
                  );
                },
              ),
      ),
    );
  }
}