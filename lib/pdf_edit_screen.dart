import 'package:flutter/material.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfEditScreen extends StatefulWidget {
  final File pdfFile;

  PdfEditScreen({required this.pdfFile});

  @override
  _PdfEditScreenState createState() => _PdfEditScreenState();
}

class _PdfEditScreenState extends State<PdfEditScreen> {
  final TextEditingController textController = TextEditingController();
  late File currentPdfFile;
  List<Map<String, dynamic>> textFields = []; // List to hold multiple fields
  GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey<SfPdfViewerState>(); // Key for reloading PDF Viewer

  @override
  void initState() {
    super.initState();
    currentPdfFile = widget.pdfFile;
  }

  Future<void> _saveAllFieldsToPdf() async {
    // wczytaj pdfa
    final PdfDocument document = PdfDocument(inputBytes: currentPdfFile.readAsBytesSync());
    final PdfPage page = document.pages[0]; // Assuming a single-page PDF for this example

    // wymiary pdfa
    double pdfPageWidth = page.size.width;
    double pdfPageHeight = page.size.height;

    // szerokows i wysokosc
    double viewerWidth = context.size!.width;
    double viewerHeight = context.size!.height;

    // calc skala
    double scaleX = pdfPageWidth / viewerWidth;
    double scaleY = pdfPageHeight / viewerHeight;

    for (var field in textFields) {
      // flutter ui coords to pdf cooords słabo działą
      double x = field['position'].dx * scaleX;
      double y = pdfPageHeight - (field['position'].dy * scaleY); // Flip Y-axis for PDF

      // Debugging info ale coś słabo poszło
      debugPrint("Placing text '${field['text']}' at PDF coordinates: x=$x, y=$y");

      // text element dla każdego pola
      PdfTextElement textElement = PdfTextElement(
        text: field['text'],
        font: PdfStandardFont(PdfFontFamily.helvetica, 12),
      );

      // tekst
      textElement.draw(
        page: page,
        bounds: Rect.fromLTWH(x, y, field['size'].width * scaleX, field['size'].height * scaleY),
      );
    }

    // Save the updated PDF and overwrite the existing file
    final List<int> bytes = await document.save();
    document.dispose();

    await currentPdfFile.writeAsBytes(bytes);

    // refresh pdf viewer
    setState(() {
      textFields.clear();
      _pdfViewerKey = GlobalKey(); // reload
    });
  }

  void _addTextField(String text) {
    // nowe pole
    setState(() {
      textFields.add({
        'text': text,
        'position': Offset(100, 100), // Default position
        'size': Size(150, 40), // Default size
      });
    });
  }

  void _editTextField(int index) {
    // okno z edycja pola
    textController.text = textFields[index]['text'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit text field'),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(hintText: 'Text'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                textController.clear();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  setState(() {
                    textFields[index]['text'] = textController.text;
                  });
                }
                Navigator.of(context).pop();
                textController.clear();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTextField(int index) {
    // delete teks z pola
    setState(() {
      textFields.removeAt(index);
    });
  }

  void _showTextFieldDialog() async {
    textController.text = ''; // nowe pole bez tekstu
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter text for new field'),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(hintText: 'Text'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                textController.clear();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  _addTextField(textController.text);
                }
                Navigator.of(context).pop();
                textController.clear();
              },
              child: Text('Add Text'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit PDF'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveAllFieldsToPdf, //zapisz do pdf
            tooltip: 'Save PDF with Changes',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTextFieldDialog, // dodaj pole z tekstem
        child: Icon(Icons.add),
        tooltip: 'Add Text Field',
      ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            currentPdfFile,
            key: _pdfViewerKey,
          ),
          ...textFields.asMap().entries.map((entry) {
            int index = entry.key;
            var field = entry.value;
            return Positioned(
              left: field['position'].dx,
              top: field['position'].dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  // zaktualizuj pozycje po przeciągnięciu
                  setState(() {
                    field['position'] = field['position'] + details.delta;
                  });
                },
                onSecondaryTapDown: (details) {
                  // Show context menu for editing or deleting the field
                  _showContextMenu(context, details.globalPosition, index);
                },
                child: Stack(
                  children: [
                    Container(
                      width: field['size'].width,
                      height: field['size'].height,
                      color: Colors.blue.withOpacity(0.3),
                      child: Center(
                        child: Text(
                          field['text'],
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -5,
                      bottom: -5,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          // zmiana rozmiaru pola
                          setState(() {
                            field['size'] = Size(
                              field['size'].width + details.delta.dx,
                              field['size'].height + details.delta.dy,
                            );
                          });
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeUpLeftDownRight,
                          child: Container(
                            width: 10,
                            height: 10,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position, int index) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Text('Edit Text'),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete Text Field'),
        ),
      ],
    );

    // praca na polu XD
    if (result == 'edit') {
      _editTextField(index);
    } else if (result == 'delete') {
      _deleteTextField(index);
    }
  }
}
