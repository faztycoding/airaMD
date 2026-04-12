part of 'patient_profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════
// Face Diagram + Digital Notepad combined tab
// ═══════════════════════════════════════════════════════════════════

class _FaceDiagramWithNotepad extends ConsumerWidget {
  final String patientId;
  const _FaceDiagramWithNotepad({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final diagramsAsync = ref.watch(diagramsByPatientProvider(patientId));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ─── New Diagram Button ───
        AiraTapEffect(
          onTap: () => context.push('/patients/$patientId/diagram'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  context.l10n.newDiagram,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ─── Saved Diagrams List (sorted by date, newest first) ───
        _SectionCard(
          title: context.l10n.savedDiagrams,
          icon: Icons.draw_rounded,
          iconColor: AiraColors.woodMid,
          children: [
            Text(
              isThai
                  ? 'แต่ละ Diagram บันทึกแยกครั้ง เซฟแล้วแก้ไขไม่ได้ (Immutable Lock)'
                  : 'Each diagram is saved separately and cannot be edited after saving.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
            ),
            const SizedBox(height: 12),
            diagramsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e',
                  style: GoogleFonts.plusJakartaSans(color: AiraColors.terra)),
              data: (diagrams) {
                if (diagrams.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AiraColors.parchment,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.draw_rounded, size: 36, color: AiraColors.muted.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.noDiagramsYet,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: AiraColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                const viewOrder = [DiagramView.front, DiagramView.leftSide, DiagramView.rightSide, DiagramView.side, DiagramView.lipZone];
                final Map<String, List<FaceDiagram>> sessions = {};
                for (final d in diagrams) {
                  final key = d.createdAt != null
                      ? '${d.createdAt!.year}-${d.createdAt!.month}-${d.createdAt!.day} ${d.createdAt!.hour}:${d.createdAt!.minute}'
                      : 'unknown';
                  sessions.putIfAbsent(key, () => []).add(d);
                }
                for (final g in sessions.values) {
                  g.sort((a, b) => viewOrder.indexOf(a.viewType).compareTo(viewOrder.indexOf(b.viewType)));
                }
                // Sort sessions by date (newest first)
                final sortedEntries = sessions.entries.toList()
                  ..sort((a, b) {
                    final aDate = a.value.first.createdAt ?? DateTime(2000);
                    final bDate = b.value.first.createdAt ?? DateTime(2000);
                    return bDate.compareTo(aDate);
                  });

                return Column(
                  children: sortedEntries.map((entry) {
                    final group = entry.value;
                    final first = group.first;
                    final dateStr = first.createdAt != null
                        ? '${first.createdAt!.day}/${first.createdAt!.month}/${first.createdAt!.year}  ${first.createdAt!.hour.toString().padLeft(2, '0')}:${first.createdAt!.minute.toString().padLeft(2, '0')}'
                        : '-';

                    String viewLabel(DiagramView v) => switch (v) {
                      DiagramView.front => context.l10n.front,
                      DiagramView.side => context.l10n.side,
                      DiagramView.leftSide => context.l10n.left,
                      DiagramView.rightSide => context.l10n.right,
                      DiagramView.lipZone => context.l10n.lipZone,
                    };

                    IconData viewIcon(DiagramView v) => switch (v) {
                      DiagramView.front => Icons.face_rounded,
                      DiagramView.side => Icons.face_3_rounded,
                      DiagramView.leftSide => Icons.face_3_rounded,
                      DiagramView.rightSide => Icons.face_3_rounded,
                      DiagramView.lipZone => Icons.mood_rounded,
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.18)),
                          boxShadow: [
                            BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AiraColors.woodPale.withValues(alpha: 0.25), AiraColors.gold.withValues(alpha: 0.15)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.draw_rounded, size: 18, color: AiraColors.woodMid),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.diagramSession,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                                      ),
                                      Text(dateStr, style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AiraColors.muted)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AiraColors.terra.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.lock_rounded, size: 12, color: AiraColors.terra),
                                      const SizedBox(width: 3),
                                      Text(
                                        context.l10n.locked,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AiraColors.terra),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: group.map((d) {
                                return AiraTapEffect(
                                  onTap: () => context.push('/patients/$patientId/diagram?diagramId=${d.id}'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AiraColors.parchment,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(viewIcon(d.viewType), size: 16, color: AiraColors.woodMid),
                                        const SizedBox(width: 6),
                                        Text(
                                          viewLabel(d.viewType),
                                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right_rounded, size: 14, color: AiraColors.muted),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.l10n.nViews(group.length),
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ─── Progress Note ───
        _ProgressNoteSection(isThai: isThai),
        const SizedBox(height: 16),

        // ─── Treatment Record / Laser Parameters ───
        _TreatmentRecordSection(isThai: isThai),
        const SizedBox(height: 16),

        // ─── Instructions & Follow-up ───
        _InstructionsFollowUpSection(isThai: isThai),
        const SizedBox(height: 24),

        // ─── Digital Notepad (embedded) ───
        _SectionCard(
          title: context.l10n.digitalNotepad,
          icon: Icons.edit_note_rounded,
          iconColor: AiraColors.sage,
          children: [
            Text(
              context.l10n.notepadForSession,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
            ),
            const SizedBox(height: 12),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 500,
          child: NotepadSection(patientId: patientId),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Progress Note — Response to Treatment + Adverse Events
// ═══════════════════════════════════════════════════════════════════

class _ProgressNoteSection extends StatefulWidget {
  final bool isThai;
  const _ProgressNoteSection({required this.isThai});

  @override
  State<_ProgressNoteSection> createState() => _ProgressNoteSectionState();
}

class _ProgressNoteSectionState extends State<_ProgressNoteSection> {
  String? _response; // improved, stable, worsened
  final Set<String> _adverseEvents = {};
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Progress Note',
      icon: Icons.assignment_rounded,
      iconColor: AiraColors.woodMid,
      children: [
        // ─── Response to Previous Treatment ───
        Text(
          context.l10n.responseToPrevious,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildResponseChip('improved', context.l10n.improved, AiraColors.sage),
            _buildResponseChip('stable', context.l10n.stable, AiraColors.gold),
            _buildResponseChip('worsened', context.l10n.worsened, AiraColors.terra),
          ],
        ),
        const SizedBox(height: 20),

        // ─── Adverse Events ───
        Text(
          context.l10n.adverseEvents,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildEventChip('none', context.l10n.none),
            _buildEventChip('erythema', 'Erythema'),
            _buildEventChip('burn', 'Burn'),
            _buildEventChip('pih', 'PIH'),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _otherCtrl,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
          decoration: InputDecoration(
            hintText: context.l10n.otherSpecify,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted.withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AiraColors.woodPale)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AiraColors.woodPale)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseChip(String value, String label, Color color) {
    final selected = _response == value;
    return AiraTapEffect(
      onTap: () => setState(() => _response = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AiraColors.parchment,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AiraColors.woodPale.withValues(alpha: 0.3), width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: selected ? color : AiraColors.muted),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? color : AiraColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventChip(String value, String label) {
    final selected = _adverseEvents.contains(value);
    final color = value == 'none' ? AiraColors.sage : AiraColors.terra;
    return AiraTapEffect(
      onTap: () {
        setState(() {
          if (value == 'none') {
            _adverseEvents.clear();
            _adverseEvents.add('none');
          } else {
            _adverseEvents.remove('none');
            if (selected) {
              _adverseEvents.remove(value);
            } else {
              _adverseEvents.add(value);
            }
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AiraColors.parchment,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AiraColors.woodPale.withValues(alpha: 0.3), width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 18, color: selected ? color : AiraColors.muted),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? color : AiraColors.muted)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Treatment Record / Laser Parameters
// ═══════════════════════════════════════════════════════════════════

class _TreatmentRecordSection extends StatelessWidget {
  final bool isThai;
  const _TreatmentRecordSection({required this.isThai});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.l10n.treatmentRecordLaser,
      icon: Icons.flash_on_rounded,
      iconColor: AiraColors.gold,
      children: [
        // ─── Assessment ───
        _buildField(context.l10n.assessmentDiagnosis, '', 2),
        const SizedBox(height: 12),

        // ─── Plan of Treatment ───
        _buildField(context.l10n.planOfTreatment, '', 2),
        const SizedBox(height: 16),

        // ─── Laser Parameters ───
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AiraColors.gold.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AiraColors.gold.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on_rounded, size: 16, color: AiraColors.gold),
                  const SizedBox(width: 6),
                  Text(
                    'Laser Parameters',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildCompactField('Device / Laser Type', 'เช่น Gentle YAG')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildCompactField('Energy / Fluence', 'เช่น 24')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildCompactField('Pulse Duration / Spot Size', 'เช่น 12')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildCompactField('Total Shots / Passes', 'เช่น 208')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, String hint, int maxLines) {
    return TextField(
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.muted),
        hintText: hint.isEmpty ? null : hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted.withValues(alpha: 0.4)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AiraColors.woodPale)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AiraColors.woodPale)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AiraColors.woodMid, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildCompactField(String label, String hint) {
    return TextField(
      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AiraColors.muted),
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted.withValues(alpha: 0.4)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AiraColors.woodPale)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AiraColors.woodPale)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AiraColors.gold, width: 2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Instructions & Follow-up + Next Appointment
// ═══════════════════════════════════════════════════════════════════

class _InstructionsFollowUpSection extends StatefulWidget {
  final bool isThai;
  const _InstructionsFollowUpSection({required this.isThai});

  @override
  State<_InstructionsFollowUpSection> createState() => _InstructionsFollowUpSectionState();
}

class _InstructionsFollowUpSectionState extends State<_InstructionsFollowUpSection> {
  final Set<String> _instructions = {};
  final _otherInstructionCtrl = TextEditingController();
  String _nextAppt = 'as_needed'; // 'date' or 'as_needed'
  DateTime? _nextApptDate;
  TimeOfDay? _nextApptTime;

  @override
  void dispose() {
    _otherInstructionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.l10n.instructionsFollowUp,
      icon: Icons.checklist_rounded,
      iconColor: AiraColors.sage,
      children: [
        // ─── Instruction checkboxes ───
        _buildInstruction('avoid_sun', context.l10n.avoidSun),
        _buildInstruction('sunscreen', context.l10n.applySunscreen),
        _buildInstruction('medication', context.l10n.applyMedication),
        const SizedBox(height: 8),
        TextField(
          controller: _otherInstructionCtrl,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
          decoration: InputDecoration(
            hintText: context.l10n.otherSpecify,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted.withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AiraColors.woodPale)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AiraColors.woodPale)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon: const Icon(Icons.edit_rounded, size: 18, color: AiraColors.muted),
          ),
        ),
        const SizedBox(height: 20),

        // ─── Next Appointment ───
        Text(
          context.l10n.nextAppointment,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildApptChip('date', context.l10n.setDateTime, Icons.calendar_today_rounded),
            _buildApptChip('as_needed', context.l10n.asNeeded, Icons.access_time_rounded),
          ],
        ),
        if (_nextAppt == 'date') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AiraTapEffect(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _nextApptDate ?? DateTime.now().add(const Duration(days: 14)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _nextApptDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AiraColors.woodPale),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: AiraColors.woodMid),
                        const SizedBox(width: 8),
                        Text(
                          _nextApptDate != null ? '${_nextApptDate!.day}/${_nextApptDate!.month}/${_nextApptDate!.year}' : context.l10n.selectDate,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _nextApptDate != null ? AiraColors.charcoal : AiraColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AiraTapEffect(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _nextApptTime ?? const TimeOfDay(hour: 10, minute: 0),
                    );
                    if (picked != null) setState(() => _nextApptTime = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AiraColors.woodPale),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: AiraColors.woodMid),
                        const SizedBox(width: 8),
                        Text(
                          _nextApptTime != null ? '${_nextApptTime!.hour.toString().padLeft(2, '0')}:${_nextApptTime!.minute.toString().padLeft(2, '0')}' : context.l10n.selectTime,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _nextApptTime != null ? AiraColors.charcoal : AiraColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInstruction(String value, String label) {
    final selected = _instructions.contains(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AiraTapEffect(
        onTap: () {
          setState(() {
            if (selected) {
              _instructions.remove(value);
            } else {
              _instructions.add(value);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AiraColors.sage.withValues(alpha: 0.08) : AiraColors.parchment,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AiraColors.sage.withValues(alpha: 0.3) : AiraColors.woodPale.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: selected ? AiraColors.sage : AiraColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AiraColors.charcoal : AiraColors.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApptChip(String value, String label, IconData icon) {
    final selected = _nextAppt == value;
    final color = AiraColors.woodMid;
    return AiraTapEffect(
      onTap: () => setState(() => _nextAppt = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AiraColors.parchment,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AiraColors.woodPale.withValues(alpha: 0.3), width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_circle_rounded : icon, size: 18, color: selected ? color : AiraColors.muted),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? color : AiraColors.muted)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Consent Form Tab — Separate tab with per-session saving
// ═══════════════════════════════════════════════════════════════════

class _ConsentFormTab extends ConsumerWidget {
  final String patientId;
  const _ConsentFormTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AiraTapEffect(
          onTap: () => context.push('/patients/$patientId/consent'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  context.l10n.newConsentForm,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: context.l10n.savedConsentForms,
          icon: Icons.description_rounded,
          iconColor: AiraColors.gold,
          children: [
            Text(
              isThai
                  ? 'Consent Form แต่ละครั้งจะบันทึกแยกเป็น session เพื่อเก็บเป็นหลักฐานทางการแพทย์'
                  : 'Each consent form is saved per session for medical compliance.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AiraColors.parchment,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.description_rounded, size: 36, color: AiraColors.muted.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.noConsentFormsHint,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Supplements Tab — อาหารเสริม
// ═══════════════════════════════════════════════════════════════════

class _SupplementsTab extends StatefulWidget {
  final String patientId;
  const _SupplementsTab({required this.patientId});

  @override
  State<_SupplementsTab> createState() => _SupplementsTabState();
}

class _SupplementsTabState extends State<_SupplementsTab> {
  final List<Map<String, String>> _supplements = [
    {'name': 'Vitamin C', 'dosage': '1,000 mg/วัน'},
    {'name': 'Collagen', 'dosage': '5,000 mg/วัน'},
    {'name': 'Glutathione', 'dosage': '500 mg/วัน'},
  ];

  static const _colors = [AiraColors.gold, AiraColors.woodMid, AiraColors.sage, AiraColors.terra, AiraColors.woodLt];
  static const _icons = [Icons.local_pharmacy_rounded, Icons.science_rounded, Icons.spa_rounded, Icons.medication_rounded, Icons.health_and_safety_rounded];

  void _addSupplement() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.addSupplement, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'ชื่ออาหารเสริม',
                hintText: 'เช่น Vitamin D, Omega-3...',
                hintStyle: GoogleFonts.plusJakartaSans(color: AiraColors.muted.withValues(alpha: 0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                prefixIcon: const Icon(Icons.medication_rounded, size: 20, color: AiraColors.woodMid),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: dosageCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'ปริมาณ / ขนาดรับประทาน',
                hintText: 'เช่น 1,000 mg/วัน',
                hintStyle: GoogleFonts.plusJakartaSans(color: AiraColors.muted.withValues(alpha: 0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                prefixIcon: const Icon(Icons.straighten_rounded, size: 20, color: AiraColors.woodMid),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel, style: GoogleFonts.plusJakartaSans(color: AiraColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AiraColors.sage,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final dosage = dosageCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() => _supplements.add({'name': name, 'dosage': dosage.isEmpty ? '-' : dosage}));
                Navigator.pop(ctx);
              }
            },
            child: Text(context.l10n.add, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AiraTapEffect(
          onTap: _addSupplement,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 6),
                Text('+ เพิ่มอาหารเสริม', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'อาหารเสริม / Supplements',
          icon: Icons.medication_rounded,
          iconColor: AiraColors.sage,
          children: [
            Text(
              'บันทึกอาหารเสริมที่ผู้รับบริการใช้อยู่',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted),
            ),
            const SizedBox(height: 16),
            if (_supplements.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AiraColors.parchment, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Icon(Icons.medication_rounded, size: 36, color: AiraColors.muted.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text(context.l10n.noSupplementData, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ...List.generate(_supplements.length, (i) {
              final s = _supplements[i];
              final color = _colors[i % _colors.length];
              final icon = _icons[i % _icons.length];
              return Column(
                children: [
                  if (i > 0) const Divider(height: 20),
                  _SupplementItemRow(
                    name: s['name']!,
                    dosage: s['dosage']!,
                    icon: icon,
                    color: color,
                    onDelete: () => setState(() => _supplements.removeAt(i)),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _SupplementItemRow extends StatelessWidget {
  final String name;
  final String dosage;
  final IconData icon;
  final Color color;
  final VoidCallback onDelete;
  const _SupplementItemRow({required this.name, required this.dosage, required this.icon, required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
              Text(dosage, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
            ],
          ),
        ),
        AiraTapEffect(
          onTap: onDelete,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AiraColors.terra.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close_rounded, size: 16, color: AiraColors.terra),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Patient Status Tab — Hidden from patients, behind Spending
// ═══════════════════════════════════════════════════════════════════

class _PatientStatusTab extends ConsumerWidget {
  final Patient patient;
  const _PatientStatusTab({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          title: context.l10n.patientStatusInternal,
          icon: Icons.star_rounded,
          iconColor: AiraColors.gold,
          children: [
            Text(
              isThai
                  ? 'ส่วนนี้ใช้ภายในคลินิกเท่านั้น คนไข้จะไม่เห็นข้อมูลนี้'
                  : 'This section is for internal use only. Patients cannot see this.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted),
            ),
            const SizedBox(height: 16),
            _StatusSelector(current: patient.status),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED COMPONENTS (continued)
// ═══════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
