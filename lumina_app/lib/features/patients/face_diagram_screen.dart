import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Face Diagram — Clinical Illustration / Skin Mapping screen
/// Modeled after MEKO Hospital "Dermatology Consultation and Progress Record"
/// Allows drawing on face (front + side views) with SOAP notes & laser params.
class FaceDiagramScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String? treatmentRecordId;
  final String? savedDiagramId;

  const FaceDiagramScreen({
    super.key,
    required this.patientId,
    this.treatmentRecordId,
    this.savedDiagramId,
  });

  bool get isReadOnly => savedDiagramId != null;

  @override
  ConsumerState<FaceDiagramScreen> createState() => _FaceDiagramScreenState();
}

class _FaceDiagramScreenState extends ConsumerState<FaceDiagramScreen> {
  // ─── Drawing state ───
  DiagramView _currentView = DiagramView.front;
  final Map<DiagramView, List<_Stroke>> _strokes = {
    DiagramView.front: [],
    DiagramView.side: [],
    DiagramView.leftSide: [],
    DiagramView.rightSide: [],
    DiagramView.lipZone: [],
  };
  _Stroke? _currentStroke;
  final Map<DiagramView, List<_Stroke>> _redoStack = {
    DiagramView.front: [],
    DiagramView.side: [],
    DiagramView.leftSide: [],
    DiagramView.rightSide: [],
    DiagramView.lipZone: [],
  };

  // ─── Patient gender for face diagram selection ───
  GenderType _patientGender = GenderType.female;
  Color _penColor = const Color(0xFFD32F2F);
  double _penSize = 3.0;
  bool _isEraser = false;

  // ─── SOAP Notes ───
  final _chiefComplaintCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _assessmentCtrl = TextEditingController();
  final _planCtrl = TextEditingController();

  // ─── Laser Parameters ───
  final _deviceCtrl = TextEditingController();
  final _energyCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _shotsCtrl = TextEditingController();

  // ─── Progress Notes ───
  TreatmentResponse _response = TreatmentResponse.notApplicable;
  final Set<String> _adverseEvents = {};
  final Set<String> _instructions = {};

  bool _isSaving = false;
  bool get _isReadOnly => widget.isReadOnly;
  FaceDiagram? _savedDiagram;
  bool _isLoadingSaved = false;

  static const _penColors = [
    Color(0xFFD32F2F), // Red
    Color(0xFF1565C0), // Blue
    Color(0xFF2E7D32), // Green
    Color(0xFFFF6F00), // Orange
    Color(0xFF6A1B9A), // Purple
    Color(0xFF212121), // Black
  ];

  static const _adverseEventOptions = [
    'None',
    'Erythema',
    'Burn',
    'PIH',
    'Swelling',
    'Bruising',
  ];

  static const _instructionOptions = [
    'Avoid sun exposure',
    'Apply sunscreen SPF 30+',
    'Apply prescribed medication / moisturizer',
    'Avoid exercise 24h',
    'Cold compress PRN',
    'No makeup 24h',
  ];

  /// Visible tabs (exclude legacy 'side' — replaced by leftSide/rightSide)
  static const _visibleViews = [
    DiagramView.front,
    DiagramView.leftSide,
    DiagramView.rightSide,
    DiagramView.lipZone,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedDiagramId != null) {
      _loadSavedDiagram();
    }
    _loadPatientGender();
  }

  Future<void> _loadPatientGender() async {
    final patientRepo = ref.read(patientRepoProvider);
    final patient = await patientRepo.get(widget.patientId);
    if (patient != null && patient.gender != null && mounted) {
      setState(() => _patientGender = patient.gender!);
    }
  }

  /// Returns the asset path for a face diagram image based on gender + view.
  String _diagramAssetPath(DiagramView view) {
    final gender = _patientGender == GenderType.male ? 'male' : 'female';
    final viewKey = switch (view) {
      DiagramView.front => 'front',
      DiagramView.side => 'left_side',
      DiagramView.leftSide => 'left_side',
      DiagramView.rightSide => 'right_side',
      DiagramView.lipZone => 'lip',
    };
    return 'assets/images/face_diagrams/${gender}_$viewKey.jpg';
  }

  /// Load a ui.Image from asset path (for offscreen rendering to PNG).
  Future<ui.Image> _loadAssetImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _loadSavedDiagram() async {
    setState(() => _isLoadingSaved = true);
    try {
      final diagramRepo = ref.read(diagramRepoProvider);
      final data = await diagramRepo.client
          .from('face_diagrams')
          .select()
          .eq('id', widget.savedDiagramId!)
          .maybeSingle();
      if (data != null && mounted) {
        final diagram = FaceDiagram.fromJson(data);
        _savedDiagram = diagram;
        _currentView = diagram.viewType;
        // Reconstruct strokes from JSON
        final restoredStrokes = <_Stroke>[];
        for (final s in diagram.strokesData) {
          if (s is Map<String, dynamic>) {
            final points = (s['points'] as List<dynamic>?)
                    ?.map((p) => Offset(
                          (p as List<dynamic>)[0].toDouble(),
                          p[1].toDouble(),
                        ))
                    .toList() ??
                [];
            final colorStr = s['color'] as String? ?? '#FFD32F2F';
            final colorVal =
                int.tryParse(colorStr.replaceFirst('#', ''), radix: 16) ??
                    0xFFD32F2F;
            restoredStrokes.add(_Stroke(
              points: points,
              color: Color(colorVal),
              size: (s['size'] as num?)?.toDouble() ?? 3.0,
            ));
          }
        }
        _strokes[diagram.viewType] = restoredStrokes;
      }
    } catch (_) {
      // Silently fail — read-only view will show empty
    } finally {
      if (mounted) setState(() => _isLoadingSaved = false);
    }
  }

  @override
  void dispose() {
    _chiefComplaintCtrl.dispose();
    _objectiveCtrl.dispose();
    _assessmentCtrl.dispose();
    _planCtrl.dispose();
    _deviceCtrl.dispose();
    _energyCtrl.dispose();
    _pulseCtrl.dispose();
    _shotsCtrl.dispose();
    super.dispose();
  }

  /// Convert a single stroke to a JSON-serializable map.
  Map<String, dynamic> _strokeToJson(_Stroke stroke) => {
        'points': stroke.points.map((p) => [p.dx, p.dy]).toList(),
        'color': '#${stroke.color.value.toRadixString(16).padLeft(8, '0')}',
        'size': stroke.size,
      };

  /// Render a specific view (face image + strokes) to a PNG [Uint8List].
  Future<Uint8List> _renderViewToPng(DiagramView view, {int width = 800, int height = 1000}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw face diagram image from assets
    try {
      final bgImage = await _loadAssetImage(_diagramAssetPath(view));
      final src = Rect.fromLTWH(0, 0, bgImage.width.toDouble(), bgImage.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(bgImage, src, dst, Paint()..filterQuality = FilterQuality.high);
    } catch (_) {
      // Fallback: just white background if image fails
    }

    // Draw user strokes
    _StrokesPainter(strokes: _strokes[view] ?? []).paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to render diagram to PNG');
    return byteData.buffer.asUint8List();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final clinicId = ref.read(currentClinicIdProvider);
      if (clinicId == null) throw Exception('No clinic ID');
      final now = DateTime.now();
      final ts = now.millisecondsSinceEpoch;
      final storage = Supabase.instance.client.storage;
      final diagramRepo = ref.read(diagramRepoProvider);

      // Collect views that have strokes
      final viewsWithStrokes = DiagramView.values
          .where((v) => (_strokes[v] ?? []).isNotEmpty)
          .toList();

      if (viewsWithStrokes.isEmpty) {
        throw Exception('ยังไม่ได้วาด Diagram — กรุณาวาดอย่างน้อย 1 view');
      }

      // Process each view: render → upload → save record
      for (final view in viewsWithStrokes) {
        // 1. Convert strokes to JSON
        final strokesJson = (_strokes[view] ?? [])
            .map(_strokeToJson)
            .toList();

        // 2. Try to render + upload PNG (optional — bucket may not exist)
        String imageUrl = '';
        try {
          final pngBytes = await _renderViewToPng(view);
          final storagePath =
              '$clinicId/${widget.patientId}/${ts}_${view.dbValue}.png';
          await storage
              .from(AppConstants.bucketFaceDiagrams)
              .uploadBinary(
                storagePath,
                pngBytes,
                fileOptions: const FileOptions(
                  contentType: 'image/png',
                  upsert: false,
                ),
              );
          imageUrl = storagePath;
        } catch (_) {
          // Storage upload failed (bucket may not exist) — save strokes only
        }

        // 3. Create FaceDiagram record (strokes always saved)
        final diagram = FaceDiagram(
          id: '',
          clinicId: clinicId,
          patientId: widget.patientId,
          treatmentRecordId: widget.treatmentRecordId,
          imageUrl: imageUrl,
          viewType: view,
          strokesData: strokesJson,
          markersData: const [],
        );
        await diagramRepo.create(diagram);
      }

      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'บันทึก Diagram เรียบร้อย (${viewsWithStrokes.length} views)',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AiraColors.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('Bucket not found')
            ? 'กรุณาสร้าง Storage Bucket "face-diagrams" ใน Supabase Dashboard ก่อน'
            : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AiraColors.terra),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isThai = ref.watch(isThaiProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: AiraColors.cream,
      appBar: _buildAppBar(isThai),
      body: _isLoadingSaved
          ? const Center(child: CircularProgressIndicator())
          : isWide
              ? _buildWideLayout(isThai)
              : _buildNarrowLayout(isThai),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isThai) {
    return AppBar(
      backgroundColor: AiraColors.cream,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => context.pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
            _isReadOnly
                ? (isThai
                    ? 'ดู Diagram${_savedDiagram?.createdAt != null ? ' — ${_savedDiagram!.createdAt!.day}/${_savedDiagram!.createdAt!.month}/${_savedDiagram!.createdAt!.year}' : ''}'
                    : 'View Diagram${_savedDiagram?.createdAt != null ? ' — ${_savedDiagram!.createdAt!.day}/${_savedDiagram!.createdAt!.month}/${_savedDiagram!.createdAt!.year}' : ''}')
                : (isThai ? 'Clinical Illustration / Skin Mapping' : 'Face Diagram'),
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AiraColors.charcoal,
            ),
          ),),
          if (_isReadOnly) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AiraColors.terra.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 13, color: AiraColors.terra),
                  const SizedBox(width: 3),
                  Text(
                    isThai ? 'แก้ไขไม่ได้' : 'Immutable',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AiraColors.terra,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isReadOnly) ...[
          // Save
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AiraTapEffect(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AiraColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isThai ? 'บันทึก' : 'Save',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Wide Layout (iPad Landscape) — Diagram left, SOAP right
  // ═══════════════════════════════════════════════════════════════
  Widget _buildWideLayout(bool isThai) {
    return Row(
      children: [
        // Left — Drawing canvas
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildViewTabs(isThai),
              Expanded(child: _buildCanvasArea()),
              if (!_isReadOnly) _buildToolbar(),
            ],
          ),
        ),
        // Divider
        Container(width: 1, color: AiraColors.creamDk),
        // Right — SOAP + Laser + Progress notes
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildFormFields(isThai),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Narrow Layout (Portrait/Phone) — Stacked
  // ═══════════════════════════════════════════════════════════════
  Widget _buildNarrowLayout(bool isThai) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildViewTabs(isThai),
          SizedBox(
            height: 420,
            child: _buildCanvasArea(),
          ),
          if (!_isReadOnly) _buildToolbar(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildFormFields(isThai),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // View Tabs: Front / Side / Lip Zone
  // ═══════════════════════════════════════════════════════════════
  Widget _buildViewTabs(bool isThai) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
        children: _visibleViews.map((view) {
          final selected = view == _currentView;
          final label = switch (view) {
            DiagramView.front => isThai ? 'ด้านหน้า' : 'Front',
            DiagramView.side => isThai ? 'ด้านข้าง' : 'Side',
            DiagramView.leftSide => isThai ? 'ด้านซ้าย' : 'Left',
            DiagramView.rightSide => isThai ? 'ด้านขวา' : 'Right',
            DiagramView.lipZone => isThai ? 'ปาก/ริมฝีปาก' : 'Lip Zone',
          };
          final icon = switch (view) {
            DiagramView.front => Icons.face_rounded,
            DiagramView.side => Icons.face_3_rounded,
            DiagramView.leftSide => Icons.face_3_rounded,
            DiagramView.rightSide => Icons.face_3_rounded,
            DiagramView.lipZone => Icons.mood_rounded,
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AiraTapEffect(
              onTap: () => setState(() => _currentView = view),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AiraColors.woodDk : AiraColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AiraColors.woodDk : AiraColors.creamDk,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: selected ? Colors.white : AiraColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AiraColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Canvas Area — Face outline + freehand drawing
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCanvasArea() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AiraColors.creamDk),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Face diagram image (gender-aware)
            Positioned.fill(
              child: Image.asset(
                _diagramAssetPath(_currentView),
                fit: BoxFit.cover,
              ),
            ),
            // User strokes
            CustomPaint(
              painter: _StrokesPainter(
                strokes: _strokes[_currentView] ?? [],
                currentStroke: _currentStroke,
              ),
            ),
            // Touch handler — blocked in read-only mode
            if (!_isReadOnly)
              GestureDetector(
                onPanStart: (details) {
                  if (_isEraser) {
                    _eraseStrokeAt(details.localPosition);
                  } else {
                    setState(() {
                      _currentStroke = _Stroke(
                        points: [details.localPosition],
                        color: _penColor,
                        size: _penSize,
                      );
                    });
                  }
                },
                onPanUpdate: (details) {
                  if (_isEraser) {
                    _eraseStrokeAt(details.localPosition);
                  } else {
                    if (_currentStroke == null) return;
                    setState(() {
                      _currentStroke = _Stroke(
                        points: [..._currentStroke!.points, details.localPosition],
                        color: _currentStroke!.color,
                        size: _currentStroke!.size,
                      );
                    });
                  }
                },
                onPanEnd: (_) {
                  if (!_isEraser && _currentStroke != null) {
                    setState(() {
                      _strokes[_currentView]!.add(_currentStroke!);
                      _redoStack[_currentView]!.clear();
                      _currentStroke = null;
                    });
                  }
                },
              ),
            // View label
            Positioned(
              top: 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AiraColors.charcoal.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentView.dbValue,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AiraColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Eraser — remove strokes near touch point
  // ═══════════════════════════════════════════════════════════════
  void _eraseStrokeAt(Offset pos) {
    final strokes = _strokes[_currentView]!;
    const threshold = 20.0;
    for (int i = strokes.length - 1; i >= 0; i--) {
      for (final p in strokes[i].points) {
        if ((p - pos).distance < threshold + strokes[i].size) {
          setState(() {
            final removed = strokes.removeAt(i);
            _redoStack[_currentView]!.add(removed);
          });
          return;
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Undo / Redo / Clear actions
  // ═══════════════════════════════════════════════════════════════
  void _undo() {
    final strokes = _strokes[_currentView]!;
    if (strokes.isEmpty) return;
    setState(() {
      _redoStack[_currentView]!.add(strokes.removeLast());
    });
  }

  void _redo() {
    final redo = _redoStack[_currentView]!;
    if (redo.isEmpty) return;
    setState(() {
      _strokes[_currentView]!.add(redo.removeLast());
    });
  }

  void _clearAll() {
    if (_strokes[_currentView]!.isEmpty) return;
    setState(() {
      _redoStack[_currentView]!.addAll(_strokes[_currentView]!);
      _strokes[_currentView]!.clear();
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Toolbar — pen colors, size, eraser, undo/redo/clear
  // ═══════════════════════════════════════════════════════════════
  Widget _buildToolbar() {
    final hasStrokes = _strokes[_currentView]!.isNotEmpty;
    final hasRedo = _redoStack[_currentView]!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AiraColors.creamDk.withValues(alpha: 0.6))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Row 1: Undo / Redo / Clear + Pen size ───
          Row(
            children: [
              _toolbarActionBtn(
                icon: Icons.undo_rounded,
                label: 'ย้อน',
                enabled: hasStrokes,
                onTap: _undo,
              ),
              const SizedBox(width: 4),
              _toolbarActionBtn(
                icon: Icons.redo_rounded,
                label: 'ถัดไป',
                enabled: hasRedo,
                onTap: _redo,
              ),
              const SizedBox(width: 4),
              _toolbarActionBtn(
                icon: Icons.delete_outline_rounded,
                label: 'ลบทั้งหมด',
                enabled: hasStrokes,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('ลบทั้งหมด?', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
                      content: Text('ลบเส้นทั้งหมดในมุมมองนี้', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
                        TextButton(
                          onPressed: () { Navigator.pop(ctx); _clearAll(); },
                          child: Text('ลบ', style: GoogleFonts.plusJakartaSans(color: AiraColors.terra, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
                isDanger: true,
              ),
              const Spacer(),
              // Pen size
              SizedBox(
                width: 100,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AiraColors.woodMid,
                    inactiveTrackColor: AiraColors.creamDk,
                    thumbColor: AiraColors.woodMid,
                  ),
                  child: Slider(
                    value: _penSize,
                    min: 1,
                    max: 8,
                    divisions: 7,
                    onChanged: (v) => setState(() => _penSize = v),
                  ),
                ),
              ),
              Text(
                '${_penSize.toStringAsFixed(0)}px',
                style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AiraColors.muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // ─── Row 2: Color picker + Eraser ───
          Row(
            children: [
              ..._penColors.map((c) {
                final selected = !_isEraser && c == _penColor;
                return AiraTapEffect(
                  onTap: () => setState(() {
                    _penColor = c;
                    _isEraser = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AiraColors.charcoal : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 6)]
                          : null,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              // Eraser
              AiraTapEffect(
                onTap: () => setState(() => _isEraser = !_isEraser),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _isEraser ? AiraColors.woodDk : AiraColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AiraColors.creamDk),
                  ),
                  child: Icon(
                    Icons.auto_fix_high_rounded,
                    size: 16,
                    color: _isEraser ? Colors.white : AiraColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolbarActionBtn({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final color = !enabled
        ? AiraColors.muted.withValues(alpha: 0.3)
        : isDanger
            ? AiraColors.terra
            : AiraColors.charcoal;
    return AiraTapEffect(
      onTap: enabled ? onTap : () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: enabled
              ? (isDanger ? AiraColors.terra.withValues(alpha: 0.08) : AiraColors.charcoal.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SOAP Notes + Laser Params + Progress Notes
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFormFields(bool isThai) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Subjective ───
        _formSection(
          icon: Icons.record_voice_over_rounded,
          title: isThai ? 'Subjective Symptoms (อาการ/ปัญหาหลัก)' : 'Subjective (Chief Complaint)',
          accentColor: AiraColors.woodDk,
          child: _textArea(_chiefComplaintCtrl, isThai ? 'ระบุอาการ / ปัญหาที่มา' : 'Chief complaint...'),
        ),
        const SizedBox(height: 16),

        // ─── Objective ───
        _formSection(
          icon: Icons.visibility_rounded,
          title: isThai ? 'Objective (ตรวจร่างกาย)' : 'Objective (Physical Exam)',
          accentColor: AiraColors.woodMid,
          child: _textArea(_objectiveCtrl, isThai ? 'ผลการตรวจ / สิ่งที่พบ' : 'Findings...'),
        ),
        const SizedBox(height: 16),

        // ─── Assessment ───
        _formSection(
          icon: Icons.analytics_rounded,
          title: isThai ? 'Assessment (วินิจฉัย)' : 'Assessment (Diagnosis)',
          accentColor: AiraColors.woodLt,
          child: _textArea(_assessmentCtrl, isThai ? 'การวินิจฉัย / Problem List' : 'Diagnosis / problem list...'),
        ),
        const SizedBox(height: 16),

        // ─── Plan ───
        _formSection(
          icon: Icons.assignment_rounded,
          title: isThai ? 'Plan of Treatment (แผนการรักษา)' : 'Plan of Treatment',
          accentColor: AiraColors.sage,
          child: _textArea(_planCtrl, isThai ? 'แผนการรักษา / สิ่งที่จะทำ' : 'Treatment plan...'),
        ),
        const SizedBox(height: 24),

        // ─── Laser Parameters ───
        _formSection(
          icon: Icons.flash_on_rounded,
          title: isThai ? 'Treatment Record / Laser Parameters' : 'Laser Parameters',
          accentColor: AiraColors.gold,
          child: Column(
            children: [
              _paramRow(
                Icons.devices_rounded,
                isThai ? 'Device / Laser Type' : 'Device / Laser Type',
                _deviceCtrl,
              ),
              _paramRow(
                Icons.bolt_rounded,
                isThai ? 'Energy / Fluence' : 'Energy / Fluence',
                _energyCtrl,
              ),
              _paramRow(
                Icons.timer_rounded,
                isThai ? 'Pulse Duration / Spot Size' : 'Pulse Duration / Spot Size',
                _pulseCtrl,
              ),
              _paramRow(
                Icons.tag_rounded,
                isThai ? 'Total Shots / Passes' : 'Total Shots / Passes',
                _shotsCtrl,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ─── Response to Previous Treatment ───
        _formSection(
          icon: Icons.trending_up_rounded,
          title: isThai ? 'Response to Previous Treatment' : 'Response to Previous',
          accentColor: AiraColors.woodLt,
          child: Row(
            children: [
              _responseChip(TreatmentResponse.improved, isThai ? 'ดีขึ้น' : 'Improved', AiraColors.sage),
              _responseChip(TreatmentResponse.stable, isThai ? 'คงที่' : 'Stable', AiraColors.gold),
              _responseChip(TreatmentResponse.worse, isThai ? 'แย่ลง' : 'Worsened', AiraColors.terra),
              _responseChip(TreatmentResponse.notApplicable, 'N/A', AiraColors.muted),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Adverse Events ───
        _formSection(
          icon: Icons.warning_amber_rounded,
          title: isThai ? 'Adverse Events' : 'Adverse Events',
          accentColor: AiraColors.terra,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _adverseEventOptions.map((event) {
              final selected = _adverseEvents.contains(event);
              return AiraTapEffect(
                onTap: _isReadOnly
                    ? null
                    : () {
                        setState(() {
                          if (selected) {
                            _adverseEvents.remove(event);
                          } else {
                            _adverseEvents.add(event);
                          }
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? (event == 'None' ? AiraColors.sage : AiraColors.terra).withValues(alpha: 0.12)
                        : AiraColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? (event == 'None' ? AiraColors.sage : AiraColors.terra)
                          : AiraColors.creamDk,
                    ),
                  ),
                  child: Text(
                    event,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? (event == 'None' ? AiraColors.sage : AiraColors.terra)
                          : AiraColors.charcoal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // ─── Instructions & Follow-up ───
        _formSection(
          icon: Icons.checklist_rounded,
          title: isThai ? 'Instructions & Follow-up' : 'Instructions & Follow-up',
          accentColor: AiraColors.sage,
          child: Column(
            children: _instructionOptions.map((instr) {
              final selected = _instructions.contains(instr);
              return AiraTapEffect(
                onTap: _isReadOnly
                    ? null
                    : () {
                        setState(() {
                          if (selected) {
                            _instructions.remove(instr);
                          } else {
                            _instructions.add(instr);
                          }
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: selected ? AiraColors.sage : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: selected ? AiraColors.sage : AiraColors.woodPale,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          instr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AiraColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _formSection({
    required IconData icon,
    required String title,
    required Widget child,
    Color accentColor = AiraColors.woodMid,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AiraColors.charcoal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AiraPremiumCard(
          accentColor: accentColor,
          children: [
            child,
            const SizedBox(height: 4),
          ],
        ),
      ],
    );
  }

  Widget _textArea(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      maxLines: 3,
      readOnly: _isReadOnly,
      style: airaFieldTextStyle,
      decoration: airaFieldDecoration(
        label: '',
        hint: hint,
        prefixIcon: null,
      ).copyWith(
        fillColor: _isReadOnly ? AiraColors.creamDk.withValues(alpha: 0.4) : AiraColors.parchment.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _paramRow(IconData icon, String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        readOnly: _isReadOnly,
        style: airaFieldTextStyle,
        decoration: airaFieldDecoration(
          label: label,
          prefixIcon: icon,
        ).copyWith(
          fillColor: _isReadOnly ? AiraColors.creamDk.withValues(alpha: 0.4) : AiraColors.parchment.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _responseChip(TreatmentResponse value, String label, Color color) {
    final selected = _response == value;
    return AiraTapEffect(
      onTap: _isReadOnly ? null : () => setState(() => _response = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AiraColors.parchment.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AiraColors.woodPale.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
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

// ═══════════════════════════════════════════════════════════════
// Stroke model
// ═══════════════════════════════════════════════════════════════
class _Stroke {
  final List<Offset> points;
  final Color color;
  final double size;

  _Stroke({required this.points, required this.color, required this.size});
}

// ═══════════════════════════════════════════════════════════════
// Strokes Painter — renders user drawings using perfect_freehand
// ═══════════════════════════════════════════════════════════════
class _StrokesPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final _Stroke? currentStroke;

  _StrokesPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final List<_Stroke> allStrokes = [
      ...strokes,
      ?currentStroke,
    ];

    for (final stroke in allStrokes) {
      if (stroke.points.length < 2) continue;

      final inputPoints = stroke.points
          .map((p) => PointVector(p.dx, p.dy))
          .toList();

      final outlinePoints = getStroke(
        inputPoints,
        options: StrokeOptions(
          size: stroke.size,
          thinning: 0.5,
          smoothing: 0.5,
          streamline: 0.5,
        ),
      );

      if (outlinePoints.isEmpty) continue;

      final path = Path();
      if (outlinePoints.length == 1) {
        path.addOval(Rect.fromCircle(
          center: outlinePoints[0],
          radius: stroke.size / 2,
        ));
      } else {
        path.moveTo(outlinePoints[0].dx, outlinePoints[0].dy);
        for (int i = 1; i < outlinePoints.length - 1; i++) {
          final p0 = outlinePoints[i];
          final p1 = outlinePoints[i + 1];
          path.quadraticBezierTo(
            p0.dx, p0.dy,
            (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2,
          );
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_StrokesPainter old) => true;
}

