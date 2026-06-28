import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class PayStubFileHelper {
  PayStubFileHelper._();

  static Future<void> saveAndOpen({
    required List<int> bytes,
    required String fileName,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await OpenFilex.open(
      file.path,
      type: 'application/pdf',
    );

    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }
}
