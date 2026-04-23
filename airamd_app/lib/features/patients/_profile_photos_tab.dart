part of 'patient_profile_screen.dart';


// ═══════════════════════════════════════════════════════════════════
// TAB 7: รูปภาพ (Photos) — Before / After panels
// ═══════════════════════════════════════════════════════════════════

// Provider for treatment records filtered by patient + category
final _treatmentsByPatientCategoryProvider = FutureProvider.family<List<TreatmentRecord>, ({String patientId, String category})>((ref, params) async {
  final repo = ref.watch(treatmentRepoProvider);
  final all = await repo.getByPatient(patientId: params.patientId);
  return all.where((t) => t.category.dbValue == params.category).toList();
});

final _beforeAfterPairsProvider = FutureProvider.family<Map<String, List<PatientPhoto>>, String>((ref, patientId) async {
  final repo = ref.watch(photoRepoProvider);
  return repo.getBeforeAfterPairs(patientId: patientId);
});

class _PhotosTab extends ConsumerStatefulWidget {
  final String patientId;
  const _PhotosTab({required this.patientId});
  @override
  ConsumerState<_PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends ConsumerState<_PhotosTab> {
  final _picker = ImagePicker();
  bool _uploading = false;

  // ─── Helpers ───
  static const _photoTypes = [
    (type: PhotoType.angleFront, label: 'Front', thLabel: 'หน้าตรง'),
    (type: PhotoType.angleLeft45, label: 'Left 45°', thLabel: '45° ซ้าย'),
    (type: PhotoType.angleLeft90, label: 'Left 90°', thLabel: '90° ซ้าย'),
    (type: PhotoType.angleRight45, label: 'Right 45°', thLabel: '45° ขวา'),
    (type: PhotoType.angleRight90, label: 'Right 90°', thLabel: '90° ขวา'),
  ];

  PatientPhoto? _findByType(List<PatientPhoto> photos, PhotoType type) {
    for (final p in photos) {
      if (p.imageType == type) return p;
    }
    return null;
  }

  String _photoUrl(PatientPhoto photo) {
    final path = (photo.thumbnailPath?.isNotEmpty ?? false) ? photo.thumbnailPath! : photo.storagePath;
    if (path.startsWith('http')) return path;
    return ref.read(supabaseClientProvider).storage.from(AppConstants.bucketPatientPhotos).getPublicUrl(path);
  }

  // ─── Create new comparison set ───
  Future<void> _createNewSet(bool isThai) async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.newComparisonSet,
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.nameComparisonHint,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: context.l10n.comparisonSetName,
                hintStyle: GoogleFonts.plusJakartaSans(color: AiraColors.muted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              backgroundColor: AiraColors.woodMid,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: Text(context.l10n.create, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (label == null || label.isEmpty) return;

    // Create an initial "before" placeholder record so the set appears
    final clinicId = ref.read(currentClinicIdProvider);
    if (clinicId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.clinicContextMissing),
            backgroundColor: AiraColors.terra,
          ),
        );
      }
      return;
    }
    try {
      final repo = ref.read(photoRepoProvider);
      await repo.create(PatientPhoto(
        id: '',
        clinicId: clinicId,
        patientId: widget.patientId,
        imageType: PhotoType.before,
        storagePath: '',
        description: label,
        treatmentDate: DateTime.now(),
      ));
      ref.invalidate(_beforeAfterPairsProvider(widget.patientId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AiraColors.terra),
        );
      }
    }
  }

  // ─── Pick & upload photo for a slot ───
  Future<void> _uploadPhoto(String setLabel, PhotoType type, bool isThai) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 2048, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final clinicId = ref.read(currentClinicIdProvider);
      if (clinicId == null) throw Exception('No clinic');
      final bytes = await picked.readAsBytes();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = picked.name.split('.').last;
      final storagePath = '$clinicId/${widget.patientId}/ba_${ts}_${type.dbValue}.$ext';

      await ref.read(supabaseClientProvider).storage
          .from(AppConstants.bucketPatientPhotos)
          .uploadBinary(storagePath, bytes, fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));

      final repo = ref.read(photoRepoProvider);
      await repo.create(PatientPhoto(
        id: '',
        clinicId: clinicId,
        patientId: widget.patientId,
        imageType: type,
        storagePath: storagePath,
        description: setLabel,
        treatmentDate: DateTime.now(),
      ));
      ref.invalidate(_beforeAfterPairsProvider(widget.patientId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.photoUploaded, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: AiraColors.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('Bucket not found')
            ? context.l10n.createBucketHint
            : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AiraColors.terra));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isThai = ref.watch(isThaiProvider);
    final pairsAsync = ref.watch(_beforeAfterPairsProvider(widget.patientId));

    return Stack(
      children: [
        pairsAsync.when(
          data: (pairs) {
            // Group by description instead of treatment_record_id
            final Map<String, List<PatientPhoto>> grouped = {};
            for (final entry in pairs.values) {
              for (final photo in entry) {
                final key = (photo.description?.isNotEmpty ?? false) ? photo.description! : 'ชุดเปรียบเทียบ';
                grouped.putIfAbsent(key, () => []).add(photo);
              }
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ─── New Set Button ───
                AiraTapEffect(
                  onTap: () => _createNewSet(isThai),
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
                        const Icon(Icons.add_a_photo_rounded, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.newComparisonSet,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Info Card ───
                _SectionCard(
                  title: 'Before & After',
                  icon: Icons.photo_library_rounded,
                  iconColor: AiraColors.woodMid,
                  children: [
                    Text(
                      isThai
                          ? 'เปรียบเทียบ Before / After แต่ละมุม: หน้าตรง, 45° ซ้าย, 90° ซ้าย, 45° ขวา, 90° ขวา'
                          : 'Compare Before / After for each angle: Front, Left 45°, Left 90°, Right 45°, Right 90°',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Empty State ───
                if (grouped.isEmpty)
                  _SectionCard(
                    title: context.l10n.noComparisonPhotos,
                    children: [
                      Text(
                        isThai
                            ? 'กดปุ่ม "สร้างชุดเปรียบเทียบใหม่" ด้านบน แล้วอัพโหลดรูป Before/After ได้เลย'
                            : 'Tap "New Comparison Set" above to start uploading Before/After photos.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                      ),
                    ],
                  ),

                // ─── Comparison Sets ───
                ...grouped.entries.map((entry) {
                  final setLabel = entry.key;
                  final photos = entry.value;
                  final firstDate = photos.firstWhere((p) => p.treatmentDate != null, orElse: () => photos.first).treatmentDate;
                  final dateStr = firstDate != null ? '${firstDate.day}/${firstDate.month}/${firstDate.year}' : '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.18)),
                        boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [AiraColors.gold.withValues(alpha: 0.3), AiraColors.woodPale.withValues(alpha: 0.2)]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.compare_rounded, size: 18, color: AiraColors.woodMid),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(setLabel, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                                    if (dateStr.isNotEmpty)
                                      Text(dateStr, style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AiraColors.muted)),
                                  ],
                                ),
                              ),
                              Text(
                                '${photos.where((p) => p.storagePath.isNotEmpty).length}/10',
                                style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AiraColors.woodMid),
                              ),
                              const SizedBox(width: 8),
                              AiraTapEffect(
                                onTap: () => _openComparison(setLabel, photos, isThai),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.compare_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(context.l10n.compare, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // ─── Before / After grid per angle ───
                          ...['angleFront', 'angleLeft45', 'angleLeft90', 'angleRight45', 'angleRight90'].map((angleKey) {
                            final slot = _photoTypes.firstWhere((s) => s.type.name == angleKey);
                            return _CollapsibleAngleCard(
                              slot: slot,
                              setLabel: setLabel,
                              photos: photos,
                              isThai: isThai,
                              onUpload: _uploadPhoto,
                              onView: _showFullPhoto,
                              photoUrl: _photoUrl,
                              findByType: _findByType,
                              slotPlaceholder: _buildSlotPlaceholder,
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        if (_uploading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildSlotPlaceholder(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AiraColors.woodPale.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.3), style: BorderStyle.solid),
      ),
      child: Center(
        child: Icon(icon, size: 24, color: AiraColors.muted.withValues(alpha: 0.4)),
      ),
    );
  }

  void _openComparison(String setLabel, List<PatientPhoto> photos, bool isThai) {
    // Build comparison slots: Before + After for the front angle,
    // then Before + After for other angles that have photos
    final slots = <ComparisonSlot>[];
    for (final pt in _photoTypes) {
      final before = _findByType(photos, pt.type);
      if (before != null && before.storagePath.isNotEmpty) {
        slots.add(ComparisonSlot(
          label: '${isThai ? pt.thLabel : pt.label} — BEFORE',
          imageUrl: _photoUrl(before),
          dateLabel: before.treatmentDate != null ? '${before.treatmentDate!.day}/${before.treatmentDate!.month}/${before.treatmentDate!.year}' : null,
        ));
      }
      // Check for after photo
      final afterDesc = '${setLabel}_after_${pt.type.name}';
      final afterPhoto = photos.where((p) => p.description == afterDesc && p.storagePath.isNotEmpty).isEmpty
          ? null
          : photos.firstWhere((p) => p.description == afterDesc && p.storagePath.isNotEmpty);
      if (afterPhoto != null) {
        slots.add(ComparisonSlot(
          label: '${isThai ? pt.thLabel : pt.label} — AFTER',
          imageUrl: _photoUrl(afterPhoto),
          dateLabel: afterPhoto.treatmentDate != null ? '${afterPhoto.treatmentDate!.day}/${afterPhoto.treatmentDate!.month}/${afterPhoto.treatmentDate!.year}' : null,
        ));
      }
    }
    // Take up to 4 slots for comparison
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.noPhotosToCompare),
          backgroundColor: AiraColors.terra,
        ),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PhotoComparisonScreen(
        setLabel: setLabel,
        slots: slots.take(4).toList(),
      ),
    ));
  }

  void _showFullPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 7: Anti-aging — Anti-aging treatments
// ═══════════════════════════════════════════════════════════════════

class _AntiAgingTab extends StatelessWidget {
  final String patientId;
  const _AntiAgingTab({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AiraTapEffect(
          onTap: () => context.push('/patients/$patientId/treatments/new?category=OTHER'),
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
                Text('+ บันทึก Anti-aging ใหม่', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Anti-aging Treatments',
          icon: Icons.spa_rounded,
          iconColor: AiraColors.gold,
          children: [
            Text(
              'บันทึกการรักษา Anti-aging เช่น HIFU, Thermage, Ultherapy, ร้อยไหม, และการรักษาฟื้นฟูผิวอื่นๆ',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
            ),
            const SizedBox(height: 16),
            _AntiAgingItem('HIFU / Ultherapy', 'ยกกระชับผิวหน้า', ['1 เดือน', '3 เดือน', '6 เดือน'], patientId: patientId),
            const Divider(height: 24),
            _AntiAgingItem('Thermage FLX', 'กระชับรูขุมขน', ['1 เดือน', '3 เดือน', '6 เดือน', '1 ปี'], patientId: patientId),
            const Divider(height: 24),
            _AntiAgingItem('ร้อยไหม', 'ยกกระชับใบหน้า', ['1 เดือน', '3 เดือน', '6 เดือน', '1 ปี'], patientId: patientId),
          ],
        ),
      ],
    );
  }
}

class _AntiAgingItem extends StatefulWidget {
  final String name;
  final String desc;
  final List<String> timeline;
  final String patientId;
  const _AntiAgingItem(this.name, this.desc, this.timeline, {required this.patientId});

  @override
  State<_AntiAgingItem> createState() => _AntiAgingItemState();
}

class _AntiAgingItemState extends State<_AntiAgingItem> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.spa_rounded, size: 14, color: AiraColors.gold),
            const SizedBox(width: 6),
            Expanded(child: Text(widget.name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal))),
            AiraTapEffect(
              onTap: () => context.push('/patients/${widget.patientId}/treatments/new?category=OTHER'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AiraColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('+ บันทึก', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AiraColors.gold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: widget.timeline.asMap().entries.map((e) {
            final selected = _selectedIndex == e.key;
            return AiraTapEffect(
              onTap: () => setState(() => _selectedIndex = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AiraColors.gold.withValues(alpha: 0.18) : AiraColors.parchment,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AiraColors.gold : AiraColors.woodPale.withValues(alpha: 0.3),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  e.value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AiraColors.gold : AiraColors.muted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text('✨ ${widget.desc}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.gold)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Before/After Collapsible Angle Card Widget
// ═══════════════════════════════════════════════════════════════════

class _CollapsibleAngleCard extends StatefulWidget {
  final ({PhotoType type, String label, String thLabel}) slot;
  final String setLabel;
  final List<PatientPhoto> photos;
  final bool isThai;
  final Function(String, PhotoType, bool) onUpload;
  final Function(BuildContext, String) onView;
  final String Function(PatientPhoto) photoUrl;
  final PatientPhoto? Function(List<PatientPhoto>, PhotoType) findByType;
  final Widget Function(IconData) slotPlaceholder;

  const _CollapsibleAngleCard({
    required this.slot,
    required this.setLabel,
    required this.photos,
    required this.isThai,
    required this.onUpload,
    required this.onView,
    required this.photoUrl,
    required this.findByType,
    required this.slotPlaceholder,
  });

  @override
  State<_CollapsibleAngleCard> createState() => _CollapsibleAngleCardState();
}

class _CollapsibleAngleCardState extends State<_CollapsibleAngleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final angleLabel = widget.isThai ? widget.slot.thLabel : widget.slot.label;
    final beforePhoto = widget.findByType(widget.photos, widget.slot.type);
    final hasBeforeImg = beforePhoto != null && beforePhoto.storagePath.isNotEmpty;
    final afterPhoto = widget.photos.where((p) => p.description == '${widget.setLabel}_after_${widget.slot.type.name}' && p.storagePath.isNotEmpty).isEmpty
        ? null
        : widget.photos.firstWhere((p) => p.description == '${widget.setLabel}_after_${widget.slot.type.name}' && p.storagePath.isNotEmpty);
    final hasAfterImg = afterPhoto != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AiraColors.parchment,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            // ─── Collapsible Header ───
            AiraTapEffect(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AiraColors.woodDk.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(16),
                    bottom: Radius.circular(_isExpanded ? 0 : 16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: AiraColors.woodMid),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        angleLabel,
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                      ),
                    ),
                    // Photo count indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (hasBeforeImg || hasAfterImg) ? AiraColors.sage.withValues(alpha: 0.15) : AiraColors.woodPale.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${hasBeforeImg ? 1 : 0}/${hasAfterImg ? 1 : 0}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: (hasBeforeImg || hasAfterImg) ? AiraColors.sage : AiraColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: AiraColors.woodMid),
                    ),
                  ],
                ),
              ),
            ),
            // ─── Expandable Content ───
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Before ──
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: AiraColors.woodMid.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('BEFORE', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AiraColors.woodMid, letterSpacing: 0.5)),
                          ),
                          const SizedBox(height: 8),
                          AiraTapEffect(
                            onTap: hasBeforeImg
                                ? () => widget.onView(context, widget.photoUrl(beforePhoto))
                                : () => widget.onUpload(widget.setLabel, widget.slot.type, widget.isThai),
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: hasBeforeImg
                                    ? Image.network(widget.photoUrl(beforePhoto), fit: BoxFit.cover,
                                        errorBuilder: (_, e, s) => widget.slotPlaceholder(Icons.broken_image_rounded))
                                    : widget.slotPlaceholder(Icons.add_a_photo_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Divider ──
                    Container(
                      width: 1,
                      height: 160,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: AiraColors.woodPale.withValues(alpha: 0.3),
                    ),
                    // ── After ──
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: AiraColors.sage.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('AFTER', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AiraColors.sage, letterSpacing: 0.5)),
                          ),
                          const SizedBox(height: 8),
                          AiraTapEffect(
                            onTap: hasAfterImg
                                ? () => widget.onView(context, widget.photoUrl(afterPhoto))
                                : () => widget.onUpload('${widget.setLabel}_after_${widget.slot.type.name}', widget.slot.type, widget.isThai),
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: hasAfterImg
                                    ? Image.network(widget.photoUrl(afterPhoto), fit: BoxFit.cover,
                                        errorBuilder: (_, e, s) => widget.slotPlaceholder(Icons.broken_image_rounded))
                                    : widget.slotPlaceholder(Icons.add_a_photo_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

