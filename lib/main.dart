import 'package:flutter/material.dart';
import 'pdf_list_screen.dart';

void main() {
  runApp(PdfEditorApp());
}

class PdfEditorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Editor App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PdfListScreen(),
    );
  }
}
