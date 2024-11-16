import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/merge_item.dart';
import 'package:path/path.dart' as path;

class FileService {
  Future<void> mergeFiles({
    required List<MergeItem> items,
    required Function(String) onError,
    required Function() onSuccess,
  }) async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save merged file as',
        fileName: 'merged_files.txt',
      );

      if (outputPath != null) {
        final outputFile = File(outputPath);
        final sink = outputFile.openWrite();

        for (final item in items) {
          // Skip placeholders and empty blocks
          if (item.isPlaceholder) continue;
          
          if (item.isFile) {
            sink.writeln('=== ${path.basename(item.file!.path)} ===');
            sink.writeln(await item.file!.readAsString());
          } else if (item.isText && !item.isEmpty) {
            sink.writeln(item.customText);
          }
          sink.writeln(); // Add a blank line between items
        }

        await sink.close();
        onSuccess();
      }
    } catch (e) {
      onError(e.toString());
    }
  }
}