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
  ///
  /// [templateContent] is the full legal text the patient agreed to. The
  /// literal `{clinic_name}` placeholder is replaced with [clinicName] so the
  /// rendered document always shows the real clinic name.
  static Future<Uint8List> generate({
    required ConsentForm form,
    required Patient patient,
    String clinicName = 'airaMD Clinic',
    String? templateContent,
    String? documentTitle,
    String? doctorName,
    String? doctorLicenseNo,
    List<String> acknowledgedItems = const [],
    Uint8List? signatureBytes,
    Uint8List? doctorSignatureBytes,
    Uint8List? witnessSignatureBytes,
    Uint8List? witness2SignatureBytes,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansThaiRegular(),
        bold: await PdfGoogleFonts.notoSansThaiBold(),
      ),
    );

    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final title = documentTitle ??
        form.procedure ??
        'ใบยินยอมรับการรักษา / Consent Form';
    final legalBody = (templateContent ?? '')
        .replaceAll('{clinic_name}', clinicName)
        .trim();

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
              title,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
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

          // Full legal consent text — split per line so MultiPage can
          // paginate between paragraphs (a single Text taller than one page
          // cannot span and throws "Widget won't fit into the page").
          if (legalBody.isNotEmpty) ...[
            for (final line in legalBody.split('\n'))
              if (line.trim().isEmpty)
                pw.SizedBox(height: 6)
              else
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Text(
                    line,
                    style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
            pw.SizedBox(height: 14),
          ] else ...[
            _labelValue('หัตถการ / Procedure', form.procedure ?? '-'),
            pw.SizedBox(height: 8),
          ],

          // Acknowledged risk items
          if (acknowledgedItems.isNotEmpty) ...[
            pw.Text('ข้าพเจ้ารับทราบความเสี่ยงต่อไปนี้ / Acknowledged:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.SizedBox(height: 4),
            ...acknowledgedItems.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 16, bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('[x] ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(
                          child: pw.Text(item,
                              style: const pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                )),
            pw.SizedBox(height: 12),
          ],

          // Legacy consent items (general/photo/anesthesia)
          if (form.consentedItems.isNotEmpty) ...[
            pw.Text('รายการยินยอม / Consented Items:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.SizedBox(height: 4),
            ...form.consentedItems.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 16, bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('[x] ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(child: pw.Text(_consentItemLabel(item))),
                    ],
                  ),
                )),
            pw.SizedBox(height: 12),
          ],

          if (form.notes != null && form.notes!.isNotEmpty) ...[
            _labelValue('หมายเหตุ / Notes', form.notes!),
            pw.SizedBox(height: 8),
          ],
          _labelValue('วันที่ลงนาม / Signed at', dateFmt.format(form.signedAt)),
          pw.SizedBox(height: 24),

          // Signature blocks — mirrors the paper form layout:
          // Row 1: ผู้รับการรักษา | แพทย์ผู้ให้คำแนะนำ/การรักษา
          // Row 2: พยาน | พยาน
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _signatureBlock(
                  'ผู้รับการรักษา / Patient',
                  signatureBytes,
                  subtitle: form.signedNameTyped ?? patient.fullName,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _signatureBlock(
                  'แพทย์ผู้ให้คำแนะนำ/การรักษา / Doctor',
                  doctorSignatureBytes,
                  subtitle: doctorName != null
                      ? (doctorLicenseNo != null && doctorLicenseNo.isNotEmpty
                          ? '$doctorName  (ว.$doctorLicenseNo)'
                          : doctorName)
                      : null,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _signatureBlock(
                  'พยาน / Witness',
                  witnessSignatureBytes,
                  subtitle: form.witnessName,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _signatureBlock(
                  'พยาน / Witness',
                  witness2SignatureBytes,
                  subtitle: form.witness2Name,
                ),
              ),
            ],
          ),
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
    String? templateContent,
    String? documentTitle,
    String? doctorName,
    String? doctorLicenseNo,
    List<String> acknowledgedItems = const [],
    Uint8List? signatureBytes,
    Uint8List? doctorSignatureBytes,
    Uint8List? witnessSignatureBytes,
    Uint8List? witness2SignatureBytes,
  }) async {
    final bytes = await generate(
      form: form,
      patient: patient,
      clinicName: clinicName,
      templateContent: templateContent,
      documentTitle: documentTitle,
      doctorName: doctorName,
      doctorLicenseNo: doctorLicenseNo,
      acknowledgedItems: acknowledgedItems,
      signatureBytes: signatureBytes,
      doctorSignatureBytes: doctorSignatureBytes,
      witnessSignatureBytes: witnessSignatureBytes,
      witness2SignatureBytes: witness2SignatureBytes,
    );

    // Use the iOS/Android share sheet (Save to Files / email / AirDrop /
    // Print) instead of the print-preview dialog. The print preview hangs on
    // "Loading Preview" on the iOS Simulator and is print-centric; the share
    // sheet is the true "export PDF" the clinic expects and works everywhere.
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'Consent_${patient.fullName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(form.signedAt)}.pdf',
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

  static pw.Widget _signatureBlock(String label, Uint8List? bytes,
      {String? subtitle}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          height: 70,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600)),
          ),
          alignment: pw.Alignment.center,
          child: bytes != null
              ? pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain)
              : pw.SizedBox(),
        ),
        pw.SizedBox(height: 4),
        if (subtitle != null && subtitle.isNotEmpty)
          pw.Text(subtitle,
              style: const pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.center),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center),
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
