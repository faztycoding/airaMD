import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_empty_state.dart';
import '../../core/widgets/aira_feedback.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';
import '../../core/services/audit_service.dart';
import '../../core/localization/app_localizations.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  final String? patientId;
  const PatientFormScreen({super.key, this.patientId});

  bool get isEdit => patientId != null && patientId != 'new';

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _initialized = false;

  // ─── Controllers ─────────────────────────────────────────
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _lineIdCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _passportCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();
  final _allergySymptomsCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _dob;
  GenderType? _gender;
  PatientStatus _status = PatientStatus.normal;
  SmokingType _smoking = SmokingType.none;
  AlcoholType _alcohol = AlcoholType.none;
  PreferredChannel _channel = PreferredChannel.none;
  bool _isRetinoids = false;
  bool _isAnticoagulant = false;
  String? _identityErrorText;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _nicknameCtrl.dispose();
    _phoneCtrl.dispose();
    _lineIdCtrl.dispose();
    _facebookCtrl.dispose();
    _instagramCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _nationalIdCtrl.dispose();
    _passportCtrl.dispose();
    _allergyCtrl.dispose();
    _allergySymptomsCtrl.dispose();
    _conditionsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _populateFromPatient(Patient p) {
    if (_initialized) return;
    _initialized = true;
    _firstNameCtrl.text = p.firstName;
    _lastNameCtrl.text = p.lastName;
    _nicknameCtrl.text = p.nickname ?? '';
    _phoneCtrl.text = p.phone ?? '';
    _lineIdCtrl.text = p.lineId ?? '';
    _facebookCtrl.text = p.facebook ?? '';
    _instagramCtrl.text = p.instagram ?? '';
    _emailCtrl.text = p.email ?? '';
    _addressCtrl.text = p.address ?? '';
    _nationalIdCtrl.text = p.nationalId ?? '';
    _passportCtrl.text = p.passportNo ?? '';
    _allergyCtrl.text = (p.drugAllergies).join(', ');
    _allergySymptomsCtrl.text = p.allergySymptoms ?? '';
    _conditionsCtrl.text = (p.medicalConditions).join(', ');
    _notesCtrl.text = p.notes ?? '';
    _dob = p.dateOfBirth;
    _gender = p.gender;
    _status = p.status;
    _smoking = p.smoking;
    _alcohol = p.alcohol;
    _channel = p.preferredChannel;
    _isRetinoids = p.isUsingRetinoids;
    _isAnticoagulant = p.isOnAnticoagulant;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasIdentityDocument) {
      setState(() => _identityErrorText = context.l10n.requireIdOrPassport);
      return;
    }
    if (_identityErrorText != null) {
      setState(() => _identityErrorText = null);
    }
    setState(() => _loading = true);

    final clinicId = ref.read(currentClinicIdProvider);
    if (clinicId == null) {
      if (mounted) {
        AiraFeedback.error(
          context,
          context.l10n.isThai
              ? 'ไม่พบข้อมูลคลินิกสำหรับบัญชีนี้ กรุณาเข้าสู่ระบบใหม่อีกครั้ง'
              : 'Clinic context is unavailable for this account. Please sign in again.',
        );
      }
      setState(() => _loading = false);
      return;
    }
    final allergies = _allergyCtrl.text.trim().isEmpty
        ? <String>[]
        : _allergyCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final conditions = _conditionsCtrl.text.trim().isEmpty
        ? <String>[]
        : _conditionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final patient = Patient(
      id: widget.isEdit ? widget.patientId! : '',
      clinicId: clinicId,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      nickname: _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
      dateOfBirth: _dob,
      gender: _gender,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      lineId: _lineIdCtrl.text.trim().isEmpty ? null : _lineIdCtrl.text.trim(),
      facebook: _facebookCtrl.text.trim().isEmpty ? null : _facebookCtrl.text.trim(),
      instagram: _instagramCtrl.text.trim().isEmpty ? null : _instagramCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      nationalId: _nationalIdCtrl.text.trim().isEmpty ? null : _nationalIdCtrl.text.trim(),
      passportNo: _passportCtrl.text.trim().isEmpty ? null : _passportCtrl.text.trim(),
      status: _status,
      drugAllergies: allergies,
      allergySymptoms: _allergySymptomsCtrl.text.trim().isEmpty ? null : _allergySymptomsCtrl.text.trim(),
      medicalConditions: conditions,
      smoking: _smoking,
      alcohol: _alcohol,
      isUsingRetinoids: _isRetinoids,
      isOnAnticoagulant: _isAnticoagulant,
      preferredChannel: _channel,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      if (widget.isEdit) {
        await ref.read(patientListProvider.notifier).updatePatient(patient);
        ref.invalidate(patientByIdProvider(widget.patientId!));
      } else {
        await ref.read(patientListProvider.notifier).addPatient(patient);
      }
      ref.invalidate(patientCountProvider);

      // Audit log
      ref.read(auditServiceProvider).log(
        action: widget.isEdit ? 'UPDATE_PATIENT' : 'CREATE_PATIENT',
        entityType: 'patients',
        entityId: patient.id,
        newData: {'name': '${patient.firstName} ${patient.lastName}'},
      );

      if (mounted) {
        AiraFeedback.success(
          context,
          widget.isEdit ? context.l10n.editSuccess : context.l10n.addPatientSuccess,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AiraFeedback.error(context, context.l10n.saveFailed('$e'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    // Load existing patient for edit
    if (widget.isEdit) {
      final patientAsync = ref.watch(patientByIdProvider(widget.patientId!));
      return patientAsync.when(
        data: (patient) {
          if (patient == null) {
            return Scaffold(
              backgroundColor: AiraColors.cream,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AiraEmptyState(
                    icon: Icons.person_off_rounded,
                    title: context.l10n.patientNotFound,
                    subtitle: context.l10n.isThai
                        ? 'ไม่พบข้อมูลผู้รับบริการที่ต้องการแก้ไขในระบบแล้ว'
                        : 'The patient record you are trying to edit is no longer available.',
                    accentColor: AiraColors.gold,
                  ),
                ),
              ),
            );
          }
          _populateFromPatient(patient);
          return _buildForm(topPad);
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AiraColors.woodMid))),
        error: (e, _) => Scaffold(
          backgroundColor: AiraColors.cream,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AiraEmptyState(
                icon: Icons.error_outline_rounded,
                title: context.l10n.isThai ? 'โหลดข้อมูลผู้รับบริการไม่สำเร็จ' : 'Unable to load patient record',
                subtitle: '$e',
                accentColor: AiraColors.terra,
              ),
            ),
          ),
        ),
      );
    }

    return _buildForm(topPad);
  }

  Widget _buildForm(double topPad) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════
          // Premium Hero Header with airaClinic branding
          // ═══════════════════════════════════════════════════════
          AiraPremiumHeader(
            title: widget.isEdit
                ? l.editPatientInfo
                : l.newPatientRegistration,
            loading: _loading,
            onBack: () => context.pop(),
            onSave: _save,
            saveLabel: l.save,
            steps: premiumSteps([
              (1, l.personalInfo),
              (2, l.contact),
              (3, l.idDoc),
              (4, l.medicalInfo),
            ]),
          ),
          // ═══════════════════════════════════════════════════════
          // Form Body
          // ═══════════════════════════════════════════════════════
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    children: [
                      // ─── Section 1: Personal Info ───
                      AiraSectionHeader(
                        step: 1,
                        icon: Icons.person_rounded,
                        title: l.personalInformation,
                        subtitle: l.patientNameDesc,
                      ),
                      AiraPremiumCard(
                        accentColor: AiraColors.woodMid,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _field('ชื่อ *', _firstNameCtrl, required: true, icon: Icons.badge_rounded)),
                              const SizedBox(width: 14),
                              Expanded(child: _field('นามสกุล *', _lastNameCtrl, required: true)),
                            ],
                          ),
                          _field('ชื่อเล่น', _nicknameCtrl, icon: Icons.face_rounded),
                          Row(
                            children: [
                              Expanded(child: _dobPicker()),
                              const SizedBox(width: 14),
                              Expanded(child: _genderPicker()),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ─── Section 2: Contact ───
                      AiraSectionHeader(
                        step: 2,
                        icon: Icons.contact_phone_rounded,
                        title: l.contactInformation,
                        subtitle: l.contactDesc,
                      ),
                      AiraPremiumCard(
                        accentColor: AiraColors.sage,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  'เบอร์โทร *',
                                  _phoneCtrl,
                                  required: true,
                                  keyboard: TextInputType.phone,
                                  icon: Icons.phone_rounded,
                                  validator: _validatePhone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _field(
                                  'Email',
                                  _emailCtrl,
                                  keyboard: TextInputType.emailAddress,
                                  icon: Icons.email_rounded,
                                  validator: _validateEmail,
                                ),
                              ),
                            ],
                          ),
                          _field('ที่อยู่', _addressCtrl, maxLines: 2, icon: Icons.location_on_rounded),
                          _channelPicker(),
                          // ── Dynamic social fields based on selected channel ──
                          if (_channel == PreferredChannel.line)
                            _field('LINE ID', _lineIdCtrl, icon: Icons.chat_rounded),
                          if (_channel == PreferredChannel.facebook)
                            _field('ชื่อ Facebook / URL', _facebookCtrl, icon: Icons.facebook_rounded),
                          if (_channel == PreferredChannel.instagram)
                            _field('Instagram @username', _instagramCtrl, icon: Icons.camera_alt_rounded),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ─── Section 3: Status & ID ───
                      AiraSectionHeader(
                        step: 3,
                        icon: Icons.verified_user_rounded,
                        title: l.statusAndId,
                        subtitle: l.statusAndIdDesc,
                      ),
                      AiraPremiumCard(
                        accentColor: AiraColors.gold,
                        children: [
                          _statusPicker(),
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  'เลขบัตรประชาชน',
                                  _nationalIdCtrl,
                                  icon: Icons.credit_card_rounded,
                                  keyboard: TextInputType.text,
                                  onChanged: _handleIdentityChanged,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _field(
                                  'Passport',
                                  _passportCtrl,
                                  icon: Icons.flight_rounded,
                                  keyboard: TextInputType.text,
                                  onChanged: _handleIdentityChanged,
                                ),
                              ),
                            ],
                          ),
                          if (_identityErrorText != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _identityErrorText!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AiraColors.terra,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ─── Section 4: Medical History ───
                      AiraSectionHeader(
                        step: 4,
                        icon: Icons.medical_information_rounded,
                        title: l.medicalHistory,
                        subtitle: l.medicalDesc,
                      ),
                      AiraPremiumCard(
                        accentColor: AiraColors.terra,
                        children: [
                          _field('แพ้ยา (คั่นด้วย ,)', _allergyCtrl, hint: 'เช่น Penicillin, Lidocaine', icon: Icons.warning_amber_rounded),
                          _field('อาการแพ้', _allergySymptomsCtrl, icon: Icons.sick_rounded),
                          _field('โรคประจำตัว (คั่นด้วย ,)', _conditionsCtrl, hint: 'เช่น ไมเกรน, เบาหวาน', icon: Icons.healing_rounded),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(child: _smokingPicker()),
                              const SizedBox(width: 14),
                              Expanded(child: _alcoholPicker()),
                            ],
                          ),
                          const Divider(height: 20, color: AiraColors.creamDk),
                          _switchRow('ใช้ Retinoids อยู่', _isRetinoids, (v) => setState(() => _isRetinoids = v)),
                          _switchRow('ทานยาต้านการแข็งตัวของเลือด', _isAnticoagulant, (v) => setState(() => _isAnticoagulant = v)),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ─── Notes ───
                      AiraSectionHeader(
                        step: 0,
                        icon: Icons.edit_note_rounded,
                        title: l.additionalNotes,
                        subtitle: l.specialNotes,
                      ),
                      AiraPremiumCard(
                        accentColor: AiraColors.muted,
                        children: [
                          _field('บันทึกเพิ่มเติม', _notesCtrl, maxLines: 3, icon: Icons.notes_rounded),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ═══ Save Button ═══
                      AiraPremiumSaveButton(
                        label: widget.isEdit
                            ? l.saveChanges
                            : l.registerPatient,
                        loading: _loading,
                        onTap: _save,
                      ),
                      const SizedBox(height: 16),
                      const AiraBrandingFooter(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────

  bool get _hasIdentityDocument =>
      _nationalIdCtrl.text.trim().isNotEmpty ||
      _passportCtrl.text.trim().isNotEmpty;

  void _handleIdentityChanged(String _) {
    if (_identityErrorText != null && _hasIdentityDocument) {
      setState(() => _identityErrorText = null);
    }
  }

  String? _validatePhone(String? value) {
    final cleaned = (value ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) {
      return context.l10n.isThai
          ? 'กรุณากรอกเบอร์โทร'
          : 'Please enter a phone number';
    }
    if (cleaned.length < 8) {
      return context.l10n.isThai
          ? 'กรุณากรอกเบอร์โทรให้ถูกต้อง'
          : 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null; // Email is optional
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return context.l10n.invalidEmail;
    }
    return null;
  }

  String _plainLabel(String label) => label.replaceAll('*', '').trim();

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
    String? hint,
    IconData? icon,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: airaFieldTextStyle,
        decoration: airaFieldDecoration(label: label, hint: hint, prefixIcon: icon),
        onChanged: onChanged,
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? 'กรุณากรอก${_plainLabel(label)}'
                    : null
                : null),
      ),
    );
  }

  Widget _dobPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AiraTapEffect(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _dob ?? DateTime(1990),
            firstDate: DateTime(1920),
            lastDate: DateTime.now(),
          );
          if (picked != null) setState(() => _dob = picked);
        },
        child: InputDecorator(
          decoration: airaFieldDecoration(
            label: 'วันเกิด',
            prefixIcon: Icons.cake_rounded,
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: AiraColors.woodMid),
          ),
          child: Text(
            _dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'เลือกวันเกิด',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _dob != null ? AiraColors.charcoal : AiraColors.muted.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }

  Widget _genderPicker() => _dropdownRow<GenderType>('เพศ', _gender, GenderType.values, (v) => setState(() => _gender = v), (v) => v.label());
  Widget _smokingPicker() => _dropdownRow<SmokingType>('สูบบุหรี่', _smoking, SmokingType.values, (v) => setState(() => _smoking = v), (v) => v.label());
  Widget _alcoholPicker() => _dropdownRow<AlcoholType>('แอลกอฮอล์', _alcohol, AlcoholType.values, (v) => setState(() => _alcohol = v), (v) => v.label());
  Widget _channelPicker() => _dropdownRow<PreferredChannel>('ช่องทางที่ต้องการ', _channel, PreferredChannel.values, (v) => setState(() => _channel = v), (v) => v.label());

  Widget _statusPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.patientStatus, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: PatientStatus.values.map((s) {
              final selected = _status == s;
              return AiraTapEffect(
                onTap: () => setState(() => _status = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected ? AiraColors.primaryGradient : null,
                    color: selected ? null : AiraColors.parchment,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? Colors.transparent : AiraColors.woodPale.withValues(alpha: 0.3)),
                    boxShadow: selected
                        ? [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    s.dbValue,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : AiraColors.muted),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _dropdownRow<T>(String label, T? value, List<T> items, ValueChanged<T> onChanged, String Function(T) display) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        value: value,
        style: airaFieldTextStyle,
        decoration: airaFieldDecoration(label: label),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(display(e), style: airaFieldTextStyle))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.charcoal))),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AiraColors.woodDk,
          ),
        ],
      ),
    );
  }
}
