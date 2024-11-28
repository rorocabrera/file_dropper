import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/merge_item.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class FileService {
Future<String> generateMergedContent(List<MergeItem> items) async {
  final StringBuffer buffer = StringBuffer();

  for (final item in items) {
    if (item.isPlaceholder) continue;
    
    if (item.isFile) {
      final filePath = item.file!.path;
      final fileName = path.basename(filePath);
      // Clean up the filename by removing temporary path and incremental numbers
      final cleanFileName = fileName.replaceAll(RegExp(r'-\d+(\.[^.]+)?$'), '');
      
      buffer.writeln('=== $cleanFileName ===');
      buffer.writeln(await item.file!.readAsString());
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

  Future<String> getFileContent(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      throw 'Error reading file: $e';
    }
  }
}