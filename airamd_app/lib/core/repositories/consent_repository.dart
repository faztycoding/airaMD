import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import '../models/models.dart';
import 'base_repository.dart';

class ConsentTemplateRepository extends BaseRepository {
  ConsentTemplateRepository(SupabaseClient client)
      : super(client, 'consent_form_templates');

  Future<List<ConsentFormTemplate>> list({
    required String clinicId,
    bool activeOnly = true,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('clinic_id', clinicId);

    if (activeOnly) query = query.eq('is_active', true);

    final data = await query.order('name', ascending: true);
    return data.map(ConsentFormTemplate.fromJson).toList();
  }

  Future<ConsentFormTemplate?> get(String id) async {
    final data = await getById(id);
    return data != null ? ConsentFormTemplate.fromJson(data) : null;
  }

  Future<ConsentFormTemplate> create(ConsentFormTemplate template) async {
    final data = await insert(template.toInsertJson());
    return ConsentFormTemplate.fromJson(data);
  }

  /// Update a template. Bumps [version] on every edit so signed consents can
  /// reference the exact template revision the patient agreed to.
  Future<ConsentFormTemplate> updateTemplate(
      ConsentFormTemplate template) async {
    final json = template.toUpdateJson()..['version'] = template.version + 1;
    final data = await update(template.id, json);
    return ConsentFormTemplate.fromJson(data);
  }

  Future<void> deleteTemplate(String id) => delete(id);
}

class ConsentFormRepository extends BaseRepository {
  ConsentFormRepository(SupabaseClient client)
      : super(client, 'consent_forms');

  Future<List<ConsentForm>> getByPatient({
    required String patientId,
    int? limit,
  }) async {
    var query = client
        .from(tableName)
        .select()
        .eq('patient_id', patientId)
        .order('signed_at', ascending: false);

    if (limit != null) query = query.limit(limit);

    final data = await query;
    return data.map(ConsentForm.fromJson).toList();
  }

  Future<ConsentForm> create(ConsentForm form) async {
    final data = await insert(form.toInsertJson());
    return ConsentForm.fromJson(data);
  }

  /// Upload an archived consent PDF to the `consent-pdfs` bucket and return the
  /// storage path. Path convention: {clinicId}/{patientId}/{fileName}.
  Future<String> uploadPdf({
    required String clinicId,
    required String patientId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$clinicId/$patientId/$fileName';
    await client.storage.from(AppConstants.bucketConsentPdfs).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );
    return path;
  }

  /// Create a short-lived signed URL to view an archived consent PDF.
  Future<String> signedPdfUrl(String path, {int expiresIn = 3600}) {
    return client.storage
        .from(AppConstants.bucketConsentPdfs)
        .createSignedUrl(path, expiresIn);
  }
}
