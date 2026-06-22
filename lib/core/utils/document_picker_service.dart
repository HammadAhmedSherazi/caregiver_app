import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/selected_document.dart';

class DocumentPickerService {
  DocumentPickerService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'heic', 'webp'};
  static const _documentExtensions = {'pdf', 'doc', 'docx'};

  Future<SelectedDocument?> pickFromSource(DocumentSource source) async {
    return switch (source) {
      DocumentSource.camera => _pickImage(ImageSource.camera),
      DocumentSource.gallery => _pickImage(ImageSource.gallery),
      DocumentSource.files => _pickFile(),
    };
  }

  Future<SelectedDocument?> _pickImage(ImageSource source) async {
    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return SelectedDocument(
      fileName: _fileNameFromPath(file.name, file.path),
      filePath: kIsWeb ? null : file.path,
      bytes: bytes,
      sizeInBytes: bytes.length,
      isImage: true,
      mimeType: _mimeTypeForName(file.name),
    );
  }

  Future<SelectedDocument?> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [..._imageExtensions, ..._documentExtensions],
      withData: kIsWeb,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final fileName = file.name;
    final extension = fileName.split('.').last.toLowerCase();
    final isImage = _imageExtensions.contains(extension);

    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null && !kIsWeb) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null) return null;

    return SelectedDocument(
      fileName: fileName,
      filePath: kIsWeb ? null : file.path,
      bytes: bytes,
      sizeInBytes: file.size > 0 ? file.size : bytes.length,
      isImage: isImage,
      mimeType: file.extension != null ? _mimeTypeForName(fileName) : null,
    );
  }

  String _fileNameFromPath(String name, String path) {
    if (name.isNotEmpty) return name;
    return path.split('/').last.split(r'\').last;
  }

  String? _mimeTypeForName(String name) {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => null,
    };
  }
}
