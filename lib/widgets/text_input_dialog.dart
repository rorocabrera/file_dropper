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
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Enter your text here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onSave,
                  child: Text(isEdit ? 'Save' : 'Insert'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}