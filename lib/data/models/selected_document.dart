import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum DocumentSource { camera, gallery, files }

class SelectedDocument extends Equatable {
  const SelectedDocument({
    required this.fileName,
    required this.sizeInBytes,
    required this.isImage,
    this.filePath,
    this.bytes,
    this.mimeType,
  });

  final String fileName;
  final String? filePath;
  final Uint8List? bytes;
  final int sizeInBytes;
  final bool isImage;
  final String? mimeType;

  bool get isWithinSizeLimit => sizeInBytes <= maxFileSizeBytes;

  static const maxFileSizeBytes = 10 * 1024 * 1024;

  String get formattedSize {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  File? get file {
    final path = filePath;
    if (path == null) return null;
    return File(path);
  }

  @override
  List<Object?> get props =>
      [fileName, filePath, bytes, sizeInBytes, isImage, mimeType];
}
