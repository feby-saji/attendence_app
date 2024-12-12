import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

importExcelSheet(BuildContext context) async {
  print('//importing excel sheet');
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
  );

  if (result != null) {
    return result;
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No file selected')),
    );
  }
}
