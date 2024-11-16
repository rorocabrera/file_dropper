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
  
  String get displayName => isFile 
    ? path.basename(file!.path) 
    : isPlaceholder ? 'Insert Text Block'
    : isEmpty ? 'Empty Text Block' 
    : 'Custom Text Block';
}