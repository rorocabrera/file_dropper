import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../models/merge_item.dart';
import '../widgets/file_drop_zone.dart';
import '../widgets/text_input_dialog.dart';
import '../services/file_service.dart';

class FileManagerHome extends StatefulWidget {
  const FileManagerHome({super.key});

  @override
  State<FileManagerHome> createState() => _FileManagerHomeState();
}

class _FileManagerHomeState extends State<FileManagerHome> {
  final List<MergeItem> _items = [];
  bool _isDragging = false;
  bool _isMerging = false;
  final TextEditingController _textEditingController = TextEditingController();
  final FileService _fileService = FileService();

  @override
  void initState() {
    super.initState();
    // Add initial placeholder
    _items.add(MergeItem(isPlaceholder: true));
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _handleFileDrop(DropDoneDetails details) {
    setState(() {
      for (final file in details.files) {
        if (file.path.isNotEmpty) {
          _items.insert(_items.length - 1, MergeItem(file: File(file.path)));
        }
      }
    });
  }

  void _addNewPlaceholder() {
    setState(() {
      _items.add(MergeItem(isPlaceholder: true));
    });
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final MergeItem item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  void _insertTextBlock(int index, {bool isEmpty = false}) {
    if (isEmpty) {
      setState(() {
        // Replace placeholder with empty text block
        _items.removeAt(index);
        _items.insert(index, MergeItem(isEmpty: true));
        // Add new placeholder if there isn't one
        if (!_items.any((item) => item.isPlaceholder)) {
          _items.add(MergeItem(isPlaceholder: true));
        }
      });
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TextInputDialog(
          controller: _textEditingController,
          title: 'Insert Custom Text',
          onSave: () {
            setState(() {
              // Replace placeholder with actual text block
              _items.removeAt(index);
              if (_textEditingController.text.isNotEmpty) {
                _items.insert(index, MergeItem(
                  customText: _textEditingController.text,
                ));
              } else {
                _items.insert(index, MergeItem(isEmpty: true));
              }
              // Add new placeholder if there isn't one
              if (!_items.any((item) => item.isPlaceholder)) {
                _items.add(MergeItem(isPlaceholder: true));
              }
            });
            _textEditingController.clear();
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _editTextBlock(MergeItem item) {
    _textEditingController.text = item.customText ?? '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TextInputDialog(
          controller: _textEditingController,
          title: 'Edit Custom Text',
          isEdit: true,
          onSave: () {
            setState(() {
              if (_textEditingController.text.isNotEmpty) {
                item.customText = _textEditingController.text;
                item.isEmpty = false;
              }
            });
            _textEditingController.clear();
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _mergeFiles() async {
    if (_items.length < 2) return;

    setState(() {
      _isMerging = true;
    });

    await _fileService.mergeFiles(
      items: _items,
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error merging files: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      onSuccess: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Files merged successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _items.clear();
            _items.add(MergeItem(isPlaceholder: true)); // Add back initial placeholder
          });
        }
      },
    );

    setState(() {
      _isMerging = false;
    });
  }

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
      // Ensure there's always at least one placeholder
      if (!_items.any((item) => item.isPlaceholder)) {
        _items.add(MergeItem(isPlaceholder: true));
      }
    });
  }

  void _handleItemTap(MergeItem item) {
    if (item.isText && !item.isPlaceholder) {
      _editTextBlock(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Merger'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: FileDropZone(
                items: _items,
                isDragging: _isDragging,
                onDragDone: _handleFileDrop,
                onDraggingChanged: (isDragging) => setState(() => _isDragging = isDragging),
                onReorder: _handleReorder,
                onEdit: _editTextBlock,
                onRemove: _removeItem,
                onPlaceholderTap: (index) => _insertTextBlock(index, isEmpty: true),
                onItemTap: _handleItemTap,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addNewPlaceholder,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Text Block'),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: _items.length >= 2 && !_isMerging ? _mergeFiles : null,
                child: _isMerging
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Merge Files',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}