import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
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
  final FileService _fileService = FileService();
  List<MergeItem> _items = [MergeItem(isPlaceholder: true)];
  bool _isDragging = false;
  bool _isMerging = false;
  final TextEditingController _textEditingController = TextEditingController();

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

  void _handleFileDrop(DropDoneDetails details) async {
    setState(() {
      for (final xFile in details.files) {
        final originalPath = xFile.path;
        
        // Check if this is a temporary path
        if (originalPath.contains('/var/folders/') && originalPath.contains('/Drops/')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File is being imported from a temporary location. Content will be cached.'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        if (originalPath.isNotEmpty) {
          final fileName = _getCleanFileName(originalPath);
          
          final exists = _items.any((item) => 
            item.isFile && item.originalFileName == fileName
          );
          
          if (!exists) {
            // Read and cache the content immediately for dropped files
            try {
              final file = File(originalPath);
              final content = file.readAsStringSync();
              _items.insert(_items.length - 1, MergeItem(
                filePath: originalPath,
                originalFileName: fileName,
                cachedContent: content,
                importMethod: FileImportMethod.dropped,
                lastModified: DateTime.now(),
              ));
            } catch (e) {
              print('Error caching file content: $e');
            }
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
        final content = await _fileService.getFileContent(item.filePath!); // Changed from item.file!
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
              content: Text('Error reading file: $e'),
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

  Future<void> _saveSession() async {
    try {
      await _fileService.exportSession(_items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSession() async {
    try {
      final loadedItems = await _fileService.importSession();
      setState(() {
        _items = loadedItems;
        if (!_items.any((item) => item.isPlaceholder)) {
          _items.add(MergeItem(isPlaceholder: true));
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session loaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  // Add a method to handle file picking as an alternative
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        for (final file in result.files) {
          if (file.path != null && file.path!.isNotEmpty) {
            final fileName = _getCleanFileName(file.path!);
            
            final exists = _items.any((item) => 
              item.isFile && item.originalFileName == fileName
            );
            
            if (!exists) {
              _items.insert(_items.length - 1, MergeItem(
                filePath: file.path!,
                originalFileName: fileName,
                importMethod: FileImportMethod.picked,
                lastModified: DateTime.now(),
              ));
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Droppy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Session',
            onPressed: _items.length > 1 ? _saveSession : null,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Load Session',
            onPressed: _loadSession,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to Clipboard',
            onPressed: _items.length > 1 ? _copyToClipboard : null,
          ),
          IconButton(
            icon: const Icon(Icons.merge_type),
            tooltip: 'Merge Files',
            onPressed: _items.length > 1 ? _mergeFiles : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset All',
            onPressed: _items.length > 1 ? _resetAll : null,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFiles,
        tooltip: 'Pick Files',
        child: const Icon(Icons.add),
      ),
    );
  }
}
