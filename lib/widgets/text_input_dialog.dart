import 'package:flutter/material.dart';

class TextInputDialog extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final VoidCallback onSave;
  final bool isEdit;

  const TextInputDialog({
    super.key,
    required this.controller,
    required this.title,
    required this.onSave,
    this.isEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Enter your text here...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onSave,
          child: Text(isEdit ? 'Save' : 'Insert'),
        ),
      ],
    );
  }
}