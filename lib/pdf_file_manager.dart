import 'package:file_picker/file_picker.dart';
import 'dart:io';

class PdfFileManager {
  // Singleton instance
  static final PdfFileManager _instance = PdfFileManager._internal();
  factory PdfFileManager() => _instance;
  PdfFileManager._internal();

  // Private list to store PDF files
  final List<File> _pdfFiles = [];

  // Public getter to access the list of PDF files
  List<File> get pdfFiles => List.unmodifiable(_pdfFiles);

  // Method to pick and store a PDF file
  Future<void> pickAndStorePdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        _pdfFiles.add(file);
      }
    } catch (e) {
      print("Error picking file: $e"); // Log error for debugging
    }
  }

  // Method to remove a PDF file from the list
  void removeFile(File file) {
    _pdfFiles.remove(file);
  }
}
