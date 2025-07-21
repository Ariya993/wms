 import 'dart:async';
import 'dart:convert';
 
import 'dart:typed_data';
import 'dart:ui' as ui;  
import 'dart:html' as html;  
import 'package:pdf/pdf.dart';
 import 'package:printing/printing.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pdf/widgets.dart' as pw;
class PrintQRController {
  void printImageWeb(Uint8List imageBytes) async {
     final box =GetStorage();
     final base64Image = base64Encode(imageBytes);
 
  final labelWidth = box.read('label_width');
  final labelHeight = box.read('label_height');
   

  print("Label width: $labelWidth, height: $labelHeight");

  if (labelWidth == null || labelHeight == null) {
    print("Label size tidak valid, pastikan sudah diset di GetStorage");
    return;
  }
   final double? labelWidthRaw = double.tryParse(labelWidth.toString());
  final double? labelHeightRaw = double.tryParse(labelHeight.toString());
  if (labelWidthRaw == null || labelHeightRaw == null) {
    print("Gagal parsing ukuran label");
    return;
  }
  final pdf = pw.Document();
  print('Image bytes length: ${imageBytes.length}');

  final image = pw.MemoryImage(imageBytes);
pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(
        labelWidthRaw * PdfPageFormat.cm,
        labelHeightRaw * PdfPageFormat.cm,
      ).copyWith(
        marginLeft: 0,
        marginRight: 0,
        marginTop: 0.5 * PdfPageFormat.cm,
        marginBottom: 0,
      ),
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        );
      },
    ),
  );
  // pdf.addPage(
  //   pw.Page(
  //     pageFormat: PdfPageFormat(
  //       labelWidth * PdfPageFormat.cm,
  //       labelHeight * PdfPageFormat.cm,
  //       marginTop: 0.5 * PdfPageFormat.cm,
  //     ),
  //     build: (pw.Context context) {
  //       return pw.Center(
  //         child: pw.Image(image, fit: pw.BoxFit.contain),
  //       );
  //     },
  //   ),
  // );

  print("Membuka dialog print...");
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async {
      print("onLayout triggered...");
      return pdf.save();
    },
  );
  // await Printing.sharePdf(bytes: await pdf.save(), filename: 'qr.pdf');


  //   final Completer<ui.Image> completer = Completer();
  //   ui.decodeImageFromList(imageBytes, (ui.Image img) {
  //     completer.complete(img);
  //   });
  //   final ui.Image image = await completer.future;
  //   final width = box.read('label_width');
  //   print (width);
  //   final htmlContent = '''
  //   <html>
  //     <head>
  //       <style>
  //         @page {
  //           size: ${box.read('label_width')}cm ${box.read('label_height')}cm;
  //           margin: 0;
  //         }
  //         body {
  //           margin: 0;
  //           margin-top:0.5cm;
  //           padding: 0;
  //           width: ${box.read('label_width')}cm;
  //           height: ${box.read('label_height')}cm;
  //           display: flex;
  //           justify-content: center;
  //           align-items: center;
  //         }
  //         img {
  //           max-width: 100%;
  //           max-height: 100%;
  //         }
  //       </style>
  //     </head>
  //     <body>
  //       <img src="data:image/png;base64,$base64Image" onload="window.print(); setTimeout(() => window.close(), 100);" />
  //     </body>
  //   </html>
  // ''';

  //   final blob = html.Blob([htmlContent], 'text/html');
  //   final url = html.Url.createObjectUrlFromBlob(blob);
  //   html.window.open(url, '_blank');
  //   //  final newWindow = html.window.open(url, '_blank');

  //   // Optional: cleanup after print
  //   Future.delayed(Duration(seconds: 2), () {
  //     html.Url.revokeObjectUrl(url);
  //   });
   }
} 