import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/merge_item.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class FileService {
  Future<String> generateMergedContent(List<MergeItem> items) async {
    final StringBuffer buffer = StringBuffer();

    for (final item in items) {
      if (item.isPlaceholder) continue;
      
      if (item.isFile) {
        final fileName = path.basename(item.filePath!);
        final cleanFileName = fileName.replaceAll(RegExp(r'-\d+(\.[^.]+)?$'), '');
        
        buffer.writeln('=== $cleanFileName ===');
        
        if (item.isPicked) {
          // For picked files, always read current content
          final file = File(item.filePath!);
          buffer.writeln(await file.readAsString());
        } else {
          // For dropped files, use cached content
          buffer.writeln(item.cachedContent);
        }
      } else if (item.isText && !item.isEmpty) {
        buffer.writeln(item.customText);
      }
      buffer.writeln(); // Add a blank line between items
    }

    return buffer.toString();
  }
  Future<String?> mergeFiles({
    required List<MergeItem> items,
    required Function(String) onError,
    required Function(String) onSuccess,
  }) async {
    try {
      // Generate a timestamp for unique filename
      final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save merged file as',
        fileName: 'merged_files_$timestamp.txt',
      );

      if (outputPath != null) {
        final content = await generateMergedContent(items);
        final outputFile = File(outputPath);
        await outputFile.writeAsString(content);
        onSuccess(outputPath);
        return outputPath;
      }
    } catch (e) {
      onError(e.toString());
    }
    return null;
  }

  Future<void> copyToClipboard({
    required List<MergeItem> items,
    required Function(String) onError,
    required Function() onSuccess,
  }) async {
    try {
      final content = await generateMergedContent(items);
      await Clipboard.setData(ClipboardData(text: content));
      onSuccess();
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> openFileLocation(String filePath) async {
    try {
      final Uri fileUri = Uri.file(filePath);
      if (Platform.isWindows) {
        Process.run('explorer.exe', ['/select,', filePath]);
      } else if (Platform.isMacOS) {
        Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        if (await File('/usr/bin/xdg-open').exists()) {
          Process.run('xdg-open', [path.dirname(filePath)]);
        }
      }
    } catch (e) {
      print('Error opening file location: $e');
    }
  }

  Future<String> getFileContent(String filePath) async {
    try {
      final file = File(filePath);
      return await file.readAsString();
    } catch (e) {
      throw 'Error reading file: $e';
    }
  }

  // Add methods to save and load session
  Future<void> saveSession(String path, List<MergeItem> items) async {
    try {
      final file = File(path);
      final sessionData = {
        'version': '1.0.0',  // For future compatibility
        'timestamp': DateTime.now().toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(sessionData));
    } catch (e) {
      throw 'Failed to save session: $e';
    }
  }

  Future<List<MergeItem>> loadSession(String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();
      final Map<String, dynamic> sessionData = jsonDecode(content);
      
      final List<dynamic> itemsData = sessionData['items'];
      final items = itemsData.map((item) => MergeItem.fromJson(item)).toList();
      
      // Verify files still exist for picked files
      for (var item in items) {
        if (item.isFile && item.isPicked) {
          final file = File(item.filePath!);
          if (!await file.exists()) {
            throw 'File not found: ${item.filePath}';
          }
        }
      }
      
      return items;
    } catch (e) {
      throw 'Failed to load session: $e';
    }
  }

  Future<void> exportSession(List<MergeItem> items) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Session As',
      fileName: 'droppy_session_$timestamp.json',
    );

    if (outputPath != null) {
      await saveSession(outputPath, items);
    }
  }

  Future<List<MergeItem>> importSession() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      return await loadSession(result.files.single.path!);
    }
    throw 'No session file selected';
  }
}
