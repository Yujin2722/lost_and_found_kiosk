import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class UserGuidePdfPage extends StatefulWidget {
  const UserGuidePdfPage({super.key});

  @override
  State<UserGuidePdfPage> createState() => _UserGuidePdfPageState();
}

class _UserGuidePdfPageState extends State<UserGuidePdfPage> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    loadPdfFromAssets();
  }

  Future<void> loadPdfFromAssets() async {
    try {
      // Load PDF from assets
      final byteData = await rootBundle.load('assets/files/tutorial.pdf');

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tutorial.pdf');
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
        flush: true,
      );

      setState(() {
        localPath = file.path;
      });
    } catch (e) {
      print("Error loading PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Guide",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromRGBO(240, 86, 38, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          localPath == null
              ? const Center(child: CircularProgressIndicator())
              : PDFView(filePath: localPath!),
    );
  }
}
