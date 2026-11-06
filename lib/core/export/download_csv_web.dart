import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

void downloadCsv(String csv, String filename) {
  final blob = web.Blob(
    [csv.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  Timer(const Duration(seconds: 10), () => web.URL.revokeObjectURL(url));
}
