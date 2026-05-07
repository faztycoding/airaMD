part of 'patient_profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════
// TAB 1: ข้อมูล (Info) — Personal info, status, ID docs
// ═══════════════════════════════════════════════════════════════════

class _InfoTab extends ConsumerWidget {
  final Patient patient;
  const _InfoTab({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          title: context.l10n.personalInfo,
          children: [
            _InfoRow(context.l10n.nameNickname, '${patient.fullName}${patient.nickname != null ? "\n${patient.nickname}" : ""}'),
            if (patient.dateOfBirth != null)
              _InfoRow(context.l10n.dateOfBirth, '${patient.dateOfBirth!.day}/${patient.dateOfBirth!.month}/${patient.dateOfBirth!.year} (${patient.age} ${context.l10n.years})'),
            if (patient.gender != null) _InfoRow(context.l10n.gender, patient.gender!.label(isThai: isThai)),
            if (patient.phone != null) _InfoRow(context.l10n.phone, patient.phone!),
            if (patient.lineId != null) _InfoRow('Line ID', patient.lineId!),
            if (patient.email != null) _InfoRow('Email', patient.email!),
            if (patient.address != null) _InfoRow(context.l10n.address, patient.address!),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: context.l10n.identificationDocs,
          icon: Icons.badge_rounded,
          iconColor: AiraColors.woodMid,
          children: [
            if (patient.nationalId != null) _InfoRow(context.l10n.nationalId, patient.nationalId!),
            if (patient.passportNo != null) _InfoRow(context.l10n.passport, patient.passportNo!),
            if (patient.nationalId == null && patient.passportNo == null)
              Text(context.l10n.noDocuments, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted)),
          ],
        ),
        if (patient.notes != null && patient.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(title: context.l10n.notes, children: [
            Text(patient.notes!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.charcoal)),
          ]),
        ],
      ],
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final PatientStatus current;
  const _StatusSelector({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatusChipSelect('ปกติ', current == PatientStatus.normal, AiraColors.sage)),
        const SizedBox(width: 10),
        Expanded(child: _StatusChipSelect('VIP', current == PatientStatus.vip, AiraColors.gold)),
        const SizedBox(width: 10),
        Expanded(child: _StatusChipSelect('STAR', current == PatientStatus.star, AiraColors.terra)),
      ],
    );
  }
}

class _StatusChipSelect extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  const _StatusChipSelect(this.label, this.selected, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.12) : AiraColors.parchment,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.4) : AiraColors.woodPale.withValues(alpha: 0.2),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : AiraColors.muted,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 2: HA — Allergies, medical history, supplements, surgery
// (Per client brief: supplements + surgery history are folded into HA so
//  there is one source of truth for medical background.)
// ═══════════════════════════════════════════════════════════════════

class _HATab extends ConsumerWidget {
  final Patient patient;
  const _HATab({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final hasAllergies = patient.drugAllergies.isNotEmpty;
    final hasConditions = patient.medicalConditions.isNotEmpty;
    final hasMedications = patient.currentMedications.isNotEmpty;
    final yes = context.l10n.yes;
    final no = context.l10n.no;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          title: context.l10n.drugAllergies,
          icon: Icons.warning_amber_rounded,
          iconColor: AiraColors.danger,
          children: [
            if (hasAllergies) ...[
              Wrap(
                spacing: 8, runSpacing: 8,
                children: patient.drugAllergies.map((a) => _AllergyChip(a)).toList(),
              ),
              if (patient.allergySymptoms != null) ...[
                const SizedBox(height: 8),
                _InfoRow(context.l10n.symptoms, patient.allergySymptoms!),
              ],
            ] else
              Text(context.l10n.noDrugAllergies, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: context.l10n.medicalConditions,
          children: [
            if (hasConditions)
              Wrap(
                spacing: 8, runSpacing: 8,
                children: patient.medicalConditions.map((c) => _ConditionChip(c)).toList(),
              )
            else
              Text(context.l10n.noMedicalConditions, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: context.l10n.smokingAlcoholMeds,
          children: [
            _InfoRow(context.l10n.smoking, patient.smoking.label(isThai: isThai)),
            _InfoRow(context.l10n.alcohol, patient.alcohol.label(isThai: isThai)),
            _InfoRow(context.l10n.usingRetinoids, patient.isUsingRetinoids ? yes : no),
            _InfoRow(context.l10n.onAnticoagulant, patient.isOnAnticoagulant ? yes : no),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: context.l10n.supplementsAndMeds,
          icon: Icons.medication_rounded,
          iconColor: AiraColors.sage,
          children: [
            if (hasMedications)
              Wrap(
                spacing: 8, runSpacing: 8,
                children: patient.currentMedications
                    .map((m) => _ConditionChip(m))
                    .toList(),
              )
            else
              Text(
                isThai
                    ? 'ยังไม่มีอาหารเสริมหรือยาที่บันทึกไว้'
                    : 'No supplements or medications on file',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: context.l10n.surgeryHistory,
          icon: Icons.favorite_rounded,
          iconColor: AiraColors.terra,
          children: [
            // Clinic does not perform surgery — this section is informational
            // only and pulls from the patient's own narrative notes.
            Text(
              isThai
                  ? 'คลินิกไม่ได้ให้บริการศัลยกรรม ส่วนนี้บันทึกไว้เพื่อประเมินความเสี่ยงในการรักษา'
                  : 'This clinic does not perform surgery. This section is for risk assessment only.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted),
            ),
            const SizedBox(height: 8),
            if (patient.notes != null && patient.notes!.isNotEmpty)
              Text(
                patient.notes!,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.charcoal),
              )
            else
              Text(
                context.l10n.noSurgeryHistory,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
              ),
          ],
        ),
      ],
    );
  }
}

class _AllergyChip extends StatelessWidget {
  final String label;
  const _AllergyChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AiraColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AiraColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_rounded, size: 14, color: AiraColors.danger),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.danger)),
        ],
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final String label;
  const _ConditionChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AiraColors.sage.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AiraColors.sage.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.sage)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 3-5: Treatment List Tabs (Injectable / Laser / Treatment)
// ═══════════════════════════════════════════════════════════════════

final _staffByIdProvider = FutureProvider.family<Staff?, String>((ref, staffId) async {
  final repo = ref.watch(staffRepoProvider);
  return repo.get(staffId);
});

/// Provider that fetches ALL treatments for the patient regardless of category
/// — used by the unified Dermatology tab.
final _allTreatmentsByPatientProvider =
    FutureProvider.family<List<TreatmentRecord>, String>((ref, patientId) async {
  final repo = ref.watch(treatmentRepoProvider);
  return repo.getByPatient(patientId: patientId);
});

// ═══════════════════════════════════════════════════════════════════
// Dermatology Tab — unified Injectable + Laser + Treatment view with
// sub-category filter pills. Replaces the three separate top-level tabs
// per the client UX brief.
// ═══════════════════════════════════════════════════════════════════

class _DermatologyTab extends ConsumerWidget {
  final String patientId;
  final String subCategory; // ALL | INJECTABLE | LASER | TREATMENT
  final ValueChanged<String> onSubCategoryChanged;

  const _DermatologyTab({
    required this.patientId,
    required this.subCategory,
    required this.onSubCategoryChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final treatmentsAsync = ref.watch(_allTreatmentsByPatientProvider(patientId));

    final pills = <(String value, String label, IconData icon)>[
      ('ALL', l.allCategories, Icons.apps_rounded),
      ('INJECTABLE', l.injectable, Icons.colorize_rounded),
      ('LASER', l.laser, Icons.flash_on_rounded),
      ('TREATMENT', l.treatment, Icons.science_rounded),
    ];

    return treatmentsAsync.when(
      data: (allTreatments) {
        final filtered = subCategory == 'ALL'
            ? allTreatments
            : allTreatments
                .where((t) => t.category.dbValue == subCategory)
                .toList();
        // Sort newest first
        filtered.sort((a, b) =>
            (b.date).compareTo(a.date));

        // + New: if a specific sub-category is selected use it directly;
        // if ALL is selected, show a picker sheet so user consciously
        // chooses the category (prevents silent INJECTABLE default).
        final newCategory = subCategory == 'ALL' ? null : subCategory;

        void onNewTap() {
          if (newCategory != null) {
            context.push('/patients/$patientId/treatments/new?category=$newCategory');
            return;
          }
          // Show category picker bottom-sheet
          showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => _TreatmentCategoryPicker(
              onSelected: (cat) => context.push(
                '/patients/$patientId/treatments/new?category=$cat',
              ),
            ),
          );
        }

        final newLabel = newCategory == null
            ? (l.isThai ? 'บันทึกการรักษา' : 'New Treatment')
            : pills.firstWhere((p) => p.$1 == newCategory, orElse: () => pills.first).$2;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── Sub-category filter pills ───
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in pills) ...[
                    _DermSubPill(
                      label: p.$2,
                      icon: p.$3,
                      selected: subCategory == p.$1,
                      onTap: () => onSubCategoryChanged(p.$1),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ─── + New record button ───
            AiraTapEffect(
              onTap: onNewTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AiraColors.woodDk.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '+ ${l.isThai ? "บันทึก" : "Record"} $newLabel ${l.isThai ? "ใหม่" : "(new)"}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ─── Records (filtered) ───
            ...filtered.map((t) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TreatmentCard(
                  date: '${t.date.day}/${t.date.month}/${t.date.year}',
                  title:
                      '${_dermCategoryIcon(t.category.dbValue)} ${t.treatmentName}',
                  subtitle: t.chiefComplaint,
                  doctorId: t.doctorId,
                  followUpDate: t.followUpDate,
                  followUpAppointmentId: t.followUpAppointmentId,
                  products: t.productsUsed
                      .map((product) {
                        if (product is Map) {
                          final map =
                              Map<String, dynamic>.from(product);
                          final name =
                              map['name']?.toString().trim() ?? '';
                          if (name.isEmpty) return null;
                          final quantity = map['quantity'];
                          final unit =
                              map['unit']?.toString().trim() ?? '';
                          if (quantity == null) return name;
                          return '$name ${quantity.toString()} ${unit.isEmpty ? '' : unit}'
                              .trim();
                        }
                        final text = product.toString().trim();
                        return text.isEmpty ? null : text;
                      })
                      .whereType<String>()
                      .toList(),
                  category: t.category.dbValue,
                ),
              );
            }),
            if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 48,
                        color: AiraColors.muted.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l.noRecords(newLabel),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, color: AiraColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AiraColors.woodMid)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _dermCategoryIcon(String cat) {
    switch (cat) {
      case 'INJECTABLE':
        return '💉';
      case 'LASER':
        return '⚡';
      default:
        return '🧪';
    }
  }
}

class _DermSubPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _DermSubPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AiraColors.woodDk : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AiraColors.woodDk
                : AiraColors.woodPale.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? Colors.white : AiraColors.woodDk),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AiraColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// (`_TreatmentListTab` was previously used by the separate Injectable / Laser
//  / Treatment top-level tabs. Those have been consolidated into the unified
//  `_DermatologyTab` above so this list view is no longer needed.)

class _TreatmentCard extends ConsumerWidget {
  final String date;
  final String title;
  final String? subtitle;
  final String? doctorId;
  final DateTime? followUpDate;
  final String? followUpAppointmentId;
  final List<String> products;
  final String category;
  const _TreatmentCard({
    required this.date,
    required this.title,
    this.subtitle,
    this.doctorId,
    this.followUpDate,
    this.followUpAppointmentId,
    required this.products,
    required this.category,
  });

  Color get _accentColor {
    switch (category) {
      case 'INJECTABLE': return AiraColors.woodMid;
      case 'LASER': return AiraColors.gold;
      default: return AiraColors.sage;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorAsync = doctorId == null || doctorId!.isEmpty
        ? null
        : ref.watch(_staffByIdProvider(doctorId!));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: _accentColor, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                      ),
                    ),
                    Icon(Icons.expand_more_rounded, color: AiraColors.muted.withValues(alpha: 0.5), size: 22),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
                ],
                // ─── Follow-up appointment badge ───
                if (followUpDate != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: followUpAppointmentId != null
                          ? AiraColors.sage.withValues(alpha: 0.10)
                          : AiraColors.gold.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: followUpAppointmentId != null
                            ? AiraColors.sage.withValues(alpha: 0.25)
                            : AiraColors.gold.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          followUpAppointmentId != null
                              ? Icons.event_available_rounded
                              : Icons.event_rounded,
                          size: 13,
                          color: followUpAppointmentId != null
                              ? AiraColors.sage
                              : AiraColors.gold,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          context.l10n.isThai
                              ? 'นัดติดตามผล ${followUpDate!.day}/${followUpDate!.month}/${followUpDate!.year}${followUpAppointmentId != null ? " ✓" : ""}'
                              : 'Follow-up ${followUpDate!.day}/${followUpDate!.month}/${followUpDate!.year}${followUpAppointmentId != null ? " ✓" : ""}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: followUpAppointmentId != null
                                ? AiraColors.sage
                                : AiraColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (doctorAsync != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _accentColor.withValues(alpha: 0.16)),
                    ),
                    child: doctorAsync.when(
                      loading: () => Text(
                        context.l10n.isThai ? 'แพทย์ผู้รับผิดชอบ: ...' : 'Doctor: ...',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: _accentColor),
                      ),
                      error: (_, __) => Text(
                        context.l10n.isThai ? 'แพทย์ผู้รับผิดชอบ: ไม่พบข้อมูล' : 'Doctor: not found',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: _accentColor),
                      ),
                      data: (doctor) => Text(
                        context.l10n.isThai
                            ? 'แพทย์ผู้รับผิดชอบ: ${doctor?.fullName ?? context.l10n.notFoundShort}'
                            : 'Doctor: ${doctor?.fullName ?? context.l10n.notFoundShort}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: _accentColor),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ─── Product chips ───
          if (products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: products
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _accentColor.withValues(alpha: 0.15)),
                          ),
                          child: Text(p, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: _accentColor)),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// (_FaceDiagramSection removed — replaced by _FaceDiagramWithNotepad)

class _CourseOverviewSection extends ConsumerWidget {
  final String patientId;
  const _CourseOverviewSection({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesByPatientProvider(patientId));
    return coursesAsync.when(
      data: (courses) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AiraTapEffect(
            onTap: () => context.push('/courses?patientId=$patientId'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AiraColors.woodPale.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  'เปิดตารางคอร์สทั้งหมด',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.woodDk),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...courses.map((course) {
            final total = course.sessionsTotal ?? (course.sessionsBought + course.sessionsBonus);
            // Per-course total + per-session breakdown (per client brief).
            final perSession =
                (course.price != null && total > 0) ? course.price! / total : null;
            final priceLine = course.price != null
                ? ' • ฿${course.price!.toStringAsFixed(0)} '
                    '${perSession != null ? '(฿${perSession.toStringAsFixed(0)}/ครั้ง)' : ''}'
                : '';
            final detail = 'ซื้อ ${course.sessionsBought} แถม ${course.sessionsBonus}'
                '${course.expiryDate != null ? ' • ครบกำหนด ${course.expiryDate!.day}/${course.expiryDate!.month}/${course.expiryDate!.year}' : ' • ไม่กำหนดวันหมดอายุ'}'
                ' • $total ครั้ง$priceLine';
            final color = switch (course.status) {
              CourseStatus.completed => AiraColors.sage,
              CourseStatus.low => AiraColors.gold,
              CourseStatus.expired => AiraColors.terra,
              CourseStatus.active => AiraColors.woodMid,
            };
            final statusLabel = switch (course.status) {
              CourseStatus.completed => 'ครบแล้ว',
              CourseStatus.low => 'ใกล้หมด',
              CourseStatus.expired => 'หมดอายุ',
              CourseStatus.active => 'ใช้อยู่',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CourseCard(
                name: course.name,
                detail: detail,
                sessionsTotal: total,
                sessionsUsed: course.sessionsUsed,
                color: color,
                statusLabel: statusLabel,
              ),
            );
          }),
          if (courses.isEmpty)
            _SectionCard(
              title: 'ยังไม่มีคอร์ส',
              children: [
                Text(
                  'กดเปิดตารางคอร์สเพื่อสร้างคอร์สใหม่หรือดูรายการทั้งหมดของคนไข้รายนี้',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                ),
              ],
            ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Treatment Category Picker — shown when ALL filter is active
// Asks user to consciously choose Injectable / Laser / Treatment
// before navigating to the new-treatment form.
// ═══════════════════════════════════════════════════════════════════
class _TreatmentCategoryPicker extends StatelessWidget {
  final ValueChanged<String> onSelected;
  const _TreatmentCategoryPicker({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isThai = l.isThai;
    final options = [
      (
        cat: 'INJECTABLE',
        label: l.injectable,
        sublabel: isThai ? 'Botox, Filler, Mesotherapy' : 'Botox, Filler, Meso',
        icon: Icons.colorize_rounded,
        color: const Color(0xFF4A90D9),
      ),
      (
        cat: 'LASER',
        label: l.laser,
        sublabel: isThai ? 'Laser, IPL, RF, HIFU' : 'Laser, IPL, RF, HIFU',
        icon: Icons.flash_on_rounded,
        color: const Color(0xFFE06B8F),
      ),
      (
        cat: 'TREATMENT',
        label: l.treatment,
        sublabel: isThai ? 'Facial, Peel, Skincare' : 'Facial, Peel, Skincare',
        icon: Icons.science_rounded,
        color: const Color(0xFF7A9070),
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AiraColors.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isThai ? 'เลือกประเภทการรักษา' : 'Choose Treatment Category',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20, fontWeight: FontWeight.w700, color: AiraColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isThai ? 'บันทึกจะถูกจัดกลุ่มตามประเภทที่เลือก' : 'Records are grouped by the chosen category',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
          ),
          const SizedBox(height: 24),
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AiraTapEffect(
              onTap: () {
                Navigator.of(context).pop();
                onSelected(opt.cat);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: opt.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: opt.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: opt.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(opt.icon, size: 24, color: opt.color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16, fontWeight: FontWeight.w700, color: AiraColors.charcoal,
                            ),
                          ),
                          Text(
                            opt.sublabel,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 20, color: opt.color.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
