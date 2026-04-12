import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

/// Generates a PDF document for a signed consent form and opens the
/// system print / share dialog via the `printing` package.
class ConsentPdfService {
  ConsentPdfService._();

  /// Build the PDF bytes for a consent form.
  static Future<Uint8List> generate({
    required ConsentForm form,
    required Patient patient,
    String clinicName = 'airaMD Clinic',
    Uint8List? signatureBytes,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansThaiRegular(),
        bold: await PdfGoogleFonts.notoSansThaiBold(),
      ),
    );

    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _header(clinicName),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          // Title
          pw.Center(
            child: pw.Text(
              'ใบยินยอมรับการรักษา / Consent Form',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 16),

          // Patient info
          _labelValue('ชื่อ-นามสกุล / Name', patient.fullName),
          _labelValue('วันเกิด / DOB', patient.dateOfBirth != null
              ? DateFormat('dd/MM/yyyy').format(patient.dateOfBirth!)
              : '-'),
          _labelValue('เลขบัตรประชาชน / ID', patient.nationalId ?? '-'),
          _labelValue('โทรศัพท์ / Phone', patient.phone ?? '-'),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // Procedure
          _labelValue('หัตถการ / Procedure', form.procedure ?? '-'),
          pw.SizedBox(height: 8),

          // Consent items
          pw.Text('รายการยินยอม / Consented Items:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          ...form.consentedItems.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16, bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('✓ ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(child: pw.Text(_consentItemLabel(item))),
                  ],
                ),
              )),
          pw.SizedBox(height: 12),

          // Notes
          if (form.notes != null && form.notes!.isNotEmpty) ...[
            _labelValue('หมายเหตุ / Notes', form.notes!),
            pw.SizedBox(height: 12),
          ],

          // Witness
          _labelValue('พยาน / Witness', form.witnessName ?? '-'),
          _labelValue('วันที่ลงนาม / Signed at', dateFmt.format(form.signedAt)),
          pw.SizedBox(height: 20),

          // Signature image
          if (signatureBytes != null) ...[
            pw.Text('ลายเซ็นผู้ป่วย / Patient Signature:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Container(
              width: 200,
              height: 80,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Image(pw.MemoryImage(signatureBytes), fit: pw.BoxFit.contain),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// Show system print/share dialog for a consent PDF.
  static Future<void> printOrShare({
    required ConsentForm form,
    required Patient patient,
    String clinicName = 'airaMD Clinic',
    Uint8List? signatureBytes,
  }) async {
    final bytes = await generate(
      form: form,
      patient: patient,
      clinicName: clinicName,
      signatureBytes: signatureBytes,
    );

    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: 'Consent_${patient.fullName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(form.signedAt)}',
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────

  static pw.Widget _header(String clinicName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(clinicName,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('airaMD',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ],
        ),
        pw.Divider(thickness: 1.5),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'เอกสารนี้สร้างโดย airaMD — ระบบจัดการคลินิกความงาม',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
            pw.Text(
              'หน้า ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 180,
            child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  static String _consentItemLabel(String code) {
    switch (code) {
      case 'GENERAL_CONSENT':
        return 'ยินยอมรับการรักษาตามหัตถการที่ระบุ / General treatment consent';
      case 'PHOTO_CONSENT':
        return 'ยินยอมให้ถ่ายภาพเพื่อบันทึกผลการรักษา / Photo consent';
      case 'ANESTHESIA_CONSENT':
        return 'ยินยอมรับการระงับความรู้สึก / Anesthesia consent';
      default:
        return code;
    }
  }
}
