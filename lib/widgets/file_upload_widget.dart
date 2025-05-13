import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileUploadWidget extends StatefulWidget {
  final Function(PlatformFile?) onFileSelected;
  final String label;

  const FileUploadWidget({
    super.key,
    required this.onFileSelected,
    required this.label,
  });

  @override
  _FileUploadWidgetState createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  PlatformFile? selectedFile;

  void selectFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null) {
      setState(() => selectedFile = result.files.first);
      widget.onFileSelected(selectedFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: selectFile,
          child: Text(widget.label),
        ),
        if (selectedFile != null) Text(selectedFile!.name),
      ],
    );
  }
}
