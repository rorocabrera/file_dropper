import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

enum FileImportMethod {
  dropped,
  picked,
}

class MergeItem {
  final String id = UniqueKey().toString();
  String? filePath;
  String? customText;
  String? originalFileName;
  String? cachedContent;  // Store content for dropped files
  FileImportMethod? importMethod;
  bool isEmpty;
  bool isPlaceholder;
  DateTime? lastModified;  // Track when the file was last modified
  
  MergeItem({
    this.filePath,
    this.customText,
    this.originalFileName,
    this.cachedContent,
    this.importMethod,
    this.isEmpty = false,
    this.isPlaceholder = false,
    this.lastModified,
  });
  
  bool get isFile => filePath != null;
  bool get isText => customText != null || isEmpty || isPlaceholder;
  bool get isDropped => importMethod == FileImportMethod.dropped;
  bool get isPicked => importMethod == FileImportMethod.picked;
  bool get isEditable => isDropped || isText;
  
  String get displayName {
    if (isFile) {
      return originalFileName ?? path.basename(filePath!);
    } else if (isPlaceholder) {
      return 'Insert Text Block';
    } else if (isEmpty) {
      return 'Empty Text Block';
    } else {
      final text = customText ?? '';
      final firstLine = text.split('\n').first.trim();
      if (firstLine.isEmpty) return 'Custom Text Block';
      
      final words = firstLine.split(' ');
      if (words.length <= 7) return firstLine;
      
      final shortTitle = words.take(7).join(' ');
      return shortTitle.length > 30 ? '${shortTitle.substring(0, 27)}...' : shortTitle;
    }
  }

  // For serialization
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'customText': customText,
      'originalFileName': originalFileName,
      'cachedContent': cachedContent,
      'importMethod': importMethod?.toString(),
      'isEmpty': isEmpty,
      'isPlaceholder': isPlaceholder,
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  // For deserialization
  factory MergeItem.fromJson(Map<String, dynamic> json) {
    return MergeItem(
      filePath: json['filePath'],
      customText: json['customText'],
      originalFileName: json['originalFileName'],
      cachedContent: json['cachedContent'],
      importMethod: json['importMethod'] != null 
          ? FileImportMethod.values.firstWhere(
              (e) => e.toString() == json['importMethod']
            )
          : null,
      isEmpty: json['isEmpty'] ?? false,
      isPlaceholder: json['isPlaceholder'] ?? false,
      lastModified: json['lastModified'] != null 
          ? DateTime.parse(json['lastModified'])
          : null,
    );
  }
}
