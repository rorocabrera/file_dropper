import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class MergeItem {
  final String id = UniqueKey().toString();
  File? file;
  String? customText;
  bool isEmpty;
  bool isPlaceholder;
  
  MergeItem({
    this.file, 
    this.customText, 
    this.isEmpty = false,
    this.isPlaceholder = false,
  });
  
  bool get isFile => file != null;
  bool get isText => customText != null || isEmpty || isPlaceholder;
  
  String get displayName {
    if (isFile) {
      return path.basename(file!.path);
    } else if (isPlaceholder) {
      return 'Insert Text Block';
    } else if (isEmpty) {
      return 'Empty Text Block';
    } else {
      // Get first line or first few words
      final text = customText ?? '';
      final firstLine = text.split('\n').first.trim();
      if (firstLine.isEmpty) return 'Custom Text Block';
      
      // Take first 30 characters or first 3 words, whichever is shorter
      final words = firstLine.split(' ');
      if (words.length <= 7) return firstLine;
      
      final shortTitle = words.take(7).join(' ');
      return shortTitle.length > 30 ? '${shortTitle.substring(0, 27)}...' : shortTitle;
    }
  }
}