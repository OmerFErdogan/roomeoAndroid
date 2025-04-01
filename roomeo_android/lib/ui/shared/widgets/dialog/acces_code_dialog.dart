import 'package:flutter/material.dart';

class AccessCodeDialog extends StatefulWidget {
  @override
  _AccessCodeDialogState createState() => _AccessCodeDialogState();
}

class _AccessCodeDialogState extends State<AccessCodeDialog> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Access Code'),
      content: TextField(
        controller: _codeController,
        decoration: InputDecoration(
          hintText: 'Access code',
          border: OutlineInputBorder(),
        ),
        obscureText: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _codeController.text),
          child: Text('Join'),
        ),
      ],
    );
  }
}
