// // webview_iframe_web.dart
// import 'dart:html' as html;
// import 'dart:ui' as ui;

// import 'package:flutter/widgets.dart';

// Widget buildWebIframe(String htmlContent) {
//   // ignore: undefined_prefixed_name
//   ui.platformViewRegistry.registerViewFactory(
//     'qr-preview-html',
//     (int viewId) {
//       final iframe = html.IFrameElement()
//         ..width = '100%'
//         ..height = '100%'
//         ..srcdoc = htmlContent
//         ..style.border = 'none';
//       return iframe;
//     },
//   );

//   return const HtmlElementView(viewType: 'qr-preview-html');
// }


import 'dart:html' as html;
import 'package:flutter/widgets.dart';
import 'dart:ui_web' as ui;

Widget buildWebIframe(String htmlContent) {
  ui.platformViewRegistry.registerViewFactory(
    'qr-preview-html',
    (int viewId) {
      final iframe = html.IFrameElement()
        ..width = '100%'
        ..height = '100%'
        ..srcdoc = htmlContent
        ..style.border = 'none';
      return iframe;
    },
  );

  return const HtmlElementView(viewType: 'qr-preview-html');
}
