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
// TAB 2: HA — Allergies, medical history
// ═══════════════════════════════════════════════════════════════════

class _HATab extends ConsumerWidget {
  final Patient patient;
  const _HATab({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final hasAllergies = patient.drugAllergies.isNotEmpty;
    final hasConditions = patient.medicalConditions.isNotEmpty;
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

class _TreatmentListTab extends ConsumerWidget {
  final String patientId;
  final String category;
  final String label;
  const _TreatmentListTab({required this.patientId, required this.category, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatmentsAsync = ref.watch(_treatmentsByPatientCategoryProvider((patientId: patientId, category: category)));

    return treatmentsAsync.when(
      data: (treatments) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AiraTapEffect(
            onTap: () => context.push('/patients/$patientId/treatments/new?category=$category'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: Text('+ บันทึก $label ใหม่', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...treatments.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TreatmentCard(
                  date: _formatDate(t.date),
                  title: '${_categoryIcon(category)} ${t.treatmentName}',
                  subtitle: t.chiefComplaint,
                  products: [],
                  category: category,
                ),
              )),
          if (treatments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 48, color: AiraColors.muted.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(context.l10n.noRecords(label), style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted)),
                  ],
                ),
              ),
            ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _categoryIcon(String cat) {
    switch (cat) {
      case 'INJECTABLE': return '💉';
      case 'LASER': return '⚡';
      default: return '🧪';
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _TreatmentCard extends StatelessWidget {
  final String date;
  final String title;
  final String? subtitle;
  final List<String> products;
  final String category;
  const _TreatmentCard({
    required this.date,
    required this.title,
    this.subtitle,
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
  Widget build(BuildContext context) {
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
            final detail = 'ซื้อ ${course.sessionsBought} แถม ${course.sessionsBonus}'
                '${course.expiryDate != null ? ' • ครบกำหนด ${course.expiryDate!.day}/${course.expiryDate!.month}/${course.expiryDate!.year}' : ' • ไม่กำหนดวันหมดอายุ'}'
                '${course.price != null ? ' • ฿${course.price!.toStringAsFixed(0)}' : ''}';
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
