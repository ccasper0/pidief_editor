import 'package:flutter/material.dart';
import 'dart:io';
import 'pdf_file_manager.dart'; // Import PdfFileManager
import 'pdf_edit_screen.dart';

class PdfListScreen extends StatefulWidget {
  @override
  _PdfListScreenState createState() => _PdfListScreenState();
}

class _PdfListScreenState extends State<PdfListScreen> {
  final PdfFileManager pdfFileManager = PdfFileManager();

  // Function to pick and store a new PDF file
  Future<void> _pickAndStorePdf() async {
    await pdfFileManager.pickAndStorePdf();
    setState(() {
      // Refresh UI after adding a new file
    });
  }

  // Function to display context menu on right-click
  void _showContextMenu(BuildContext context, Offset position, File pdfFile) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Text('Edit'),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    );

    // Handle menu selection
    if (result == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfEditScreen(pdfFile: pdfFile),
        ),
      );
    } else if (result == 'delete') {
      setState(() {
        pdfFileManager.removeFile(pdfFile);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfFiles = pdfFileManager.pdfFiles;

    return Scaffold(
      appBar: AppBar(
        title: Text('Uploaded PDFs'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickAndStorePdf,
            child: Text('Upload PDF'),
          ),
          Expanded(
            child: pdfFiles.isNotEmpty
                ? ListView.builder(
              itemCount: pdfFiles.length,
              itemBuilder: (context, index) {
                final pdfFile = pdfFiles[index];
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onSecondaryTapDown: (details) {
                      _showContextMenu(context, details.globalPosition, pdfFile);
                    },
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfEditScreen(pdfFile: pdfFile),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(pdfFile.path.split('/').last),
                      ),
                    ),
                  ),
                );
              },
            )
                : Center(
              child: Text('No PDFs uploaded yet.'),
            ),
          ),
        ],
      ),
    );
  }
}
