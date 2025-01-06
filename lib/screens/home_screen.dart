import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../models/merge_item.dart';
import '../widgets/file_drop_zone.dart';
import '../widgets/text_input_dialog.dart';
import '../services/file_service.dart';
import 'package:path/path.dart' as path;

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
          // Get clean filename without incremental suffix
          final fileName = _getCleanFileName(file.path);
          
          // Check if file already exists in the list
          final exists = _items.any((item) => 
            item.isFile && item.originalFileName == fileName
          );
          
          if (!exists) {
            _items.insert(_items.length - 1, MergeItem(
              file: File(file.path),
              originalFileName: fileName
            ));
          }
        }
      }
    });
  }

  String _getCleanFileName(String filePath) {
    final fileName = path.basename(filePath);
    
    // Split filename and extension
    final lastDot = fileName.lastIndexOf('.');
    final nameWithoutExt = lastDot != -1 ? fileName.substring(0, lastDot) : fileName;
    final extension = lastDot != -1 ? fileName.substring(lastDot) : '';
    
    // Find all incremental numbers in the filename
    final numbers = RegExp(r'-\d+').allMatches(nameWithoutExt).toList();
    
    if (numbers.isEmpty) {
      return fileName;
    }
    
    // Remove only the last incremental number
    final lastNumber = numbers.last;
    final cleanName = nameWithoutExt.substring(0, lastNumber.start) + 
                     (numbers.length > 1 ? nameWithoutExt.substring(lastNumber.end) : '');
    
    return cleanName + extension;
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

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
      // Ensure there's always at least one placeholder
      if (!_items.any((item) => item.isPlaceholder)) {
        _items.add(MergeItem(isPlaceholder: true));
      }
    });
  }

    void _handleItemTap(MergeItem item) async {
    if (item.isText && !item.isPlaceholder) {
      _editTextBlock(item);
    } else if (item.isFile) {
      try {
        final content = await _fileService.getFileContent(item.file!);
        _textEditingController.text = content;
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return TextInputDialog(
                controller: _textEditingController,
                title: 'Edit ${item.displayName}',
                isEdit: true,
                onSave: () {
                  setState(() {
                    // Convert file to text block
                    final index = _items.indexOf(item);
                    _items[index] = MergeItem(
                      customText: _textEditingController.text,
                    );
                  });
                  _textEditingController.clear();
                  Navigator.pop(context);
                },
              );
            },
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _mergeFiles() async {
    if (_items.length < 2) return;

    setState(() {
      _isMerging = true;
    });

    String? savedFilePath = await _fileService.mergeFiles(
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
      onSuccess: (filePath) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Files merged successfully! Click to show in folder'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Show',
                textColor: Colors.white,
                onPressed: () => _fileService.openFileLocation(filePath),
              ),
            ),
          );
          setState(() {
            _items.clear();
            _items.add(MergeItem(isPlaceholder: true));
          });
        }
      },
    );

    setState(() {
      _isMerging = false;
    });
  }

  Future<void> _copyToClipboard() async {
    if (_items.length < 2) return;

    setState(() {
      _isMerging = true;
    });

    await _fileService.copyToClipboard(
      items: _items,
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error copying to clipboard: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      onSuccess: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Content copied to clipboard!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );

    setState(() {
      _isMerging = false;
    });
  }

void _resetAll() async {
  setState(() {
    // Clear all items
    _items.clear();
    // Add back initial placeholder
    _items.add(MergeItem(isPlaceholder: true));
    // Clear text controller
    _textEditingController.clear();
    // Reset drag state
    _isDragging = false;
    // Reset merge state
    _isMerging = false;
  });

  // Clear temporary files
  try {
    final tempDir = Directory(path.join(
      path.dirname(Platform.resolvedExecutable),
      'Drops'
    ));
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      await tempDir.create();
    }
  } catch (e) {
    print('Error clearing temporary files: $e');
  }
}

// Update the build method to include the reset button
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Droppy'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset All',
          onPressed: _resetAll,
        ),
      ],
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
          const SizedBox(height: 16), // Added padding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const SizedBox(width: 16),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _items.length >= 2 && !_isMerging ? _copyToClipboard : null,
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
                          'Copy to Clipboard',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}