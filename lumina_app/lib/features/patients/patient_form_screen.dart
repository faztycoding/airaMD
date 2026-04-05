import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';

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
    // Require at least national ID or passport
    if (_nationalIdCtrl.text.trim().isEmpty && _passportCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอกเลขบัตรประชาชน หรือ หมายเลข Passport อย่างน้อย 1 อย่าง'),
          backgroundColor: AiraColors.terra,
        ),
      );
      return;
    }
    setState(() => _loading = true);

    final clinicId = ref.read(currentClinicIdProvider)!;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'แก้ไขข้อมูลสำเร็จ' : 'เพิ่มผู้รับบริการสำเร็จ'),
            backgroundColor: AiraColors.sage,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e'), backgroundColor: AiraColors.terra),
        );
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
              body: Center(child: Text('ไม่พบข้อมูลผู้รับบริการ', style: GoogleFonts.plusJakartaSans(fontSize: 16))),
            );
          }
          _populateFromPatient(patient);
          return _buildForm(topPad);
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AiraColors.woodMid))),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      );
    }

    return _buildForm(topPad);
  }

  Widget _buildForm(double topPad) {
    final isThai = ref.watch(isThaiProvider);
    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════
          // Premium Hero Header with airaClinic branding
          // ═══════════════════════════════════════════════════════
          AiraPremiumHeader(
            title: widget.isEdit
                ? (isThai ? 'แก้ไขข้อมูลผู้รับบริการ' : 'Edit Patient')
                : (isThai ? 'ลงทะเบียนผู้รับบริการใหม่' : 'New Patient Registration'),
            loading: _loading,
            onBack: () => context.pop(),
            onSave: _save,
            saveLabel: isThai ? 'บันทึก' : 'Save',
            steps: premiumSteps([
              (1, isThai ? 'ข้อมูลส่วนตัว' : 'Personal'),
              (2, isThai ? 'ติดต่อ' : 'Contact'),
              (3, isThai ? 'เอกสาร' : 'ID'),
              (4, isThai ? 'การแพทย์' : 'Medical'),
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    children: [
                      // ─── Section 1: Personal Info ───
                      AiraSectionHeader(
                        step: 1,
                        icon: Icons.person_rounded,
                        title: isThai ? 'ข้อมูลส่วนตัว' : 'Personal Information',
                        subtitle: isThai ? 'กรอกชื่อ-นามสกุลของผู้รับบริการ' : 'Patient name and basic details',
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
                        title: isThai ? 'ข้อมูลติดต่อ' : 'Contact Information',
                        subtitle: isThai ? 'เบอร์โทร, LINE, Facebook, IG, Email' : 'Phone, LINE, Facebook, IG, email',
                      ),
                      AiraPremiumCard(
                        accentColor: AiraColors.sage,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _field('เบอร์โทร *', _phoneCtrl, required: true, keyboard: TextInputType.phone, icon: Icons.phone_rounded)),
                              const SizedBox(width: 14),
                              Expanded(child: _field('Email', _emailCtrl, keyboard: TextInputType.emailAddress, icon: Icons.email_rounded)),
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
                        title: isThai ? 'สถานะ & เอกสาร' : 'Status & Identification',
                        subtitle: isThai ? 'สถานะผู้รับบริการ, เลขบัตร' : 'Patient status and ID documents',
                      ),
                      AiraPremiumCard(
                        accentColor: AiraColors.gold,
                        children: [
                          _statusPicker(),
                          Row(
                            children: [
                              Expanded(child: _field('เลขบัตรประชาชน', _nationalIdCtrl, icon: Icons.credit_card_rounded)),
                              const SizedBox(width: 14),
                              Expanded(child: _field('Passport', _passportCtrl, icon: Icons.flight_rounded)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ─── Section 4: Medical History ───
                      AiraSectionHeader(
                        step: 4,
                        icon: Icons.medical_information_rounded,
                        title: isThai ? 'ประวัติทางการแพทย์' : 'Medical History',
                        subtitle: isThai ? 'แพ้ยา, โรคประจำตัว, พฤติกรรม' : 'Allergies, conditions, habits',
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
                        title: isThai ? 'หมายเหตุเพิ่มเติม' : 'Additional Notes',
                        subtitle: isThai ? 'บันทึกสิ่งที่ต้องระวังเป็นพิเศษ' : 'Any special instructions or notes',
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
                            ? (isThai ? 'บันทึกการแก้ไข' : 'Save Changes')
                            : (isThai ? 'ลงทะเบียนผู้รับบริการ' : 'Register Patient'),
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

  Widget _field(String label, TextEditingController ctrl, {bool required = false, TextInputType? keyboard, int maxLines = 1, String? hint, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: airaFieldTextStyle,
        decoration: airaFieldDecoration(label: label, hint: hint, prefixIcon: icon),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอก$label' : null : null,
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
          Text('สถานะผู้รับบริการ', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.muted)),
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
