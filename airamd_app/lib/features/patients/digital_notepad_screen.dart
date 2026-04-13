import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/localization/app_localizations.dart';

// ═══════════════════════════════════════════════════════════════════
// Digital Notepad — Blank canvas for free-form clinical notes
// ═══════════════════════════════════════════════════════════════════

/// Provider to fetch all notepads for a patient.
final _notepadsByPatientProvider =
    FutureProvider.family<List<DigitalNotepad>, String>((ref, patientId) {
  final repo = ref.watch(notepadRepoProvider);
  return repo.getByPatient(patientId: patientId);
});

class DigitalNotepadScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String? notepadId; // null = new

  const DigitalNotepadScreen({
    super.key,
    required this.patientId,
    this.notepadId,
  });

  bool get isReadOnly => notepadId != null;

  @override
  ConsumerState<DigitalNotepadScreen> createState() =>
      _DigitalNotepadScreenState();
}

class _DigitalNotepadScreenState extends ConsumerState<DigitalNotepadScreen> {
  // ─── Drawing state ───
  final List<_Stroke> _strokes = [];
  final List<_Stroke> _redoStack = [];
  _Stroke? _currentStroke;

  Color _penColor = const Color(0xFF2D1F14); // charcoal default
  double _penSize = 2.5;
  bool _isEraser = false;
  bool _isSaving = false;
  bool _isLoading = false;
  DigitalNotepad? _loadedNotepad;

  // ─── Page style ───
  _PageStyle _pageStyle = _PageStyle.blank;

  // ─── Title ───
  final _titleCtrl = TextEditingController();

  static const _penColors = [
    Color(0xFF2D1F14), // Charcoal
    Color(0xFFD32F2F), // Red
    Color(0xFF1565C0), // Blue
    Color(0xFF2E7D32), // Green
    Color(0xFFFF6F00), // Orange
    Color(0xFF6A1B9A), // Purple
  ];

  @override
  void initState() {
    super.initState();
    if (widget.notepadId != null) {
      _loadSavedNotepad();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedNotepad() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(notepadRepoProvider);
      final data = await repo.client
          .from('digital_notepads')
          .select()
          .eq('id', widget.notepadId!)
          .maybeSingle();
      if (data != null && mounted) {
        final notepad = DigitalNotepad.fromJson(data);
        _loadedNotepad = notepad;
        _titleCtrl.text = notepad.title ?? '';
        // Restore strokes from canvasData
        final strokesList = notepad.canvasData['strokes'] as List<dynamic>? ?? [];
        for (final s in strokesList) {
          if (s is Map<String, dynamic>) {
            final points = (s['points'] as List<dynamic>?)
                    ?.map((p) => Offset(
                          (p as List<dynamic>)[0].toDouble(),
                          p[1].toDouble(),
                        ))
                    .toList() ??
                [];
            final colorStr = s['color'] as String? ?? '#FF2D1F14';
            final colorVal =
                int.tryParse(colorStr.replaceFirst('#', ''), radix: 16) ??
                    0xFF2D1F14;
            _strokes.add(_Stroke(
              points: points,
              color: Color(colorVal),
              size: (s['size'] as num?)?.toDouble() ?? 2.5,
            ));
          }
        }
        // Restore page style
        final styleStr = notepad.canvasData['pageStyle'] as String?;
        if (styleStr != null) {
          _pageStyle = _PageStyle.values.firstWhere(
            (s) => s.name == styleStr,
            orElse: () => _PageStyle.blank,
          );
        }
      }
    } catch (_) {
      // Silently fail
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _strokeToJson(_Stroke stroke) => {
        'points': stroke.points.map((p) => [p.dx, p.dy]).toList(),
        'color': '#${stroke.color.value.toRadixString(16).padLeft(8, '0')}',
        'size': stroke.size,
      };

  /// Render the notepad canvas to a PNG for optional storage upload.
  Future<Uint8List> _renderToPng({int width = 1200, int height = 1600}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw page lines if applicable
    _drawPageLines(canvas, size);

    // Draw user strokes
    _StrokesPainter(strokes: _strokes).paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to render notepad to PNG');
    return byteData.buffer.asUint8List();
  }

  void _drawPageLines(Canvas canvas, Size size) {
    if (_pageStyle == _PageStyle.blank) return;
    final linePaint = Paint()
      ..color = const Color(0xFFD0C8BC).withValues(alpha: 0.5)
      ..strokeWidth = 0.8;
    if (_pageStyle == _PageStyle.lined || _pageStyle == _PageStyle.grid) {
      for (double y = 40; y < size.height; y += 32) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
    }
    if (_pageStyle == _PageStyle.grid) {
      for (double x = 40; x < size.width; x += 32) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      }
    }
    if (_pageStyle == _PageStyle.dotGrid) {
      final dotPaint = Paint()
        ..color = const Color(0xFFD0C8BC).withValues(alpha: 0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (double y = 24; y < size.height; y += 24) {
        for (double x = 24; x < size.width; x += 24) {
          canvas.drawCircle(Offset(x, y), 1, dotPaint);
        }
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.nothingToSave,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          backgroundColor: AiraColors.terra,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final clinicId = ref.read(currentClinicIdProvider);
      if (clinicId == null) throw Exception('No clinic ID');

      final strokesJson = _strokes.map(_strokeToJson).toList();
      final canvasData = {
        'strokes': strokesJson,
        'pageStyle': _pageStyle.name,
      };

      // Try to upload PNG
      String? imageUrl;
      try {
        final pngBytes = await _renderToPng();
        final ts = DateTime.now().millisecondsSinceEpoch;
        final storagePath = '$clinicId/${widget.patientId}/notepad_$ts.png';
        await ref.read(supabaseClientProvider).storage
            .from(AppConstants.bucketNotepads)
            .uploadBinary(
              storagePath,
              pngBytes,
              fileOptions: const FileOptions(contentType: 'image/png', upsert: false),
            );
        imageUrl = storagePath;
      } catch (_) {
        // Storage upload failed — save canvas data only
      }

      final title = _titleCtrl.text.trim().isEmpty
          ? 'Note ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'
          : _titleCtrl.text.trim();

      final notepad = DigitalNotepad(
        id: '',
        clinicId: clinicId,
        patientId: widget.patientId,
        title: title,
        canvasData: canvasData,
        imageUrl: imageUrl,
      );

      await ref.read(notepadRepoProvider).create(notepad);
      ref.invalidate(_notepadsByPatientProvider(widget.patientId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.notepadSaved,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: AiraColors.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AiraColors.terra),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.cream,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AiraColors.woodMid))
          : Column(
              children: [
                // Title bar
                if (!widget.isReadOnly) _buildTitleBar(),
                // Canvas
                Expanded(child: _buildCanvasArea()),
                // Toolbar
                if (!widget.isReadOnly) _buildToolbar(),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
          const Icon(Icons.edit_note_rounded, size: 22, color: AiraColors.woodMid),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.isReadOnly
                  ? (_loadedNotepad?.title ?? context.l10n.viewNotepad)
                  : context.l10n.digitalNotepad,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AiraColors.charcoal,
              ),
            ),
          ),
          if (widget.isReadOnly) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AiraColors.woodMid.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                context.l10n.readOnly,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AiraColors.woodMid,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!widget.isReadOnly) ...[
          // Page style selector
          PopupMenuButton<_PageStyle>(
            icon: const Icon(Icons.grid_on_rounded, size: 20, color: AiraColors.muted),
            tooltip: 'Page Style',
            onSelected: (style) => setState(() => _pageStyle = style),
            itemBuilder: (context) => _PageStyle.values.map((style) {
              final selected = style == _pageStyle;
              return PopupMenuItem(
                value: style,
                child: Row(
                  children: [
                    Icon(style.icon, size: 18, color: selected ? AiraColors.woodMid : AiraColors.muted),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.isThai ? style.labelTh : style.labelEn,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AiraColors.woodMid : AiraColors.charcoal,
                      ),
                    ),
                    if (selected) ...[
                      const Spacer(),
                      const Icon(Icons.check_rounded, size: 16, color: AiraColors.woodMid),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          // Save button
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
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        context.l10n.save,
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

  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: TextField(
        controller: _titleCtrl,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AiraColors.charcoal,
        ),
        decoration: InputDecoration(
          hintText: context.l10n.noteTitleHint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w500, color: AiraColors.muted.withValues(alpha: 0.5),
          ),
          prefixIcon: const Icon(Icons.title_rounded, size: 20, color: AiraColors.woodLt),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AiraColors.creamDk),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AiraColors.creamDk),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AiraColors.woodMid, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Canvas — Blank page with optional grid/lines
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCanvasArea() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
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
            // Page background with optional lines/grid
            CustomPaint(painter: _PageLinePainter(_pageStyle)),
            // User strokes
            CustomPaint(
              painter: _StrokesPainter(
                strokes: _strokes,
                currentStroke: _currentStroke,
              ),
            ),
            // Touch handler
            if (!widget.isReadOnly)
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
                      _strokes.add(_currentStroke!);
                      _redoStack.clear();
                      _currentStroke = null;
                    });
                  }
                },
              ),
            // Watermark
            Positioned(
              bottom: 8,
              right: 12,
              child: Text(
                'airaMD Notepad',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 10,
                  color: AiraColors.muted.withValues(alpha: 0.2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Eraser
  // ═══════════════════════════════════════════════════════════════
  void _eraseStrokeAt(Offset pos) {
    const threshold = 20.0;
    for (int i = _strokes.length - 1; i >= 0; i--) {
      for (final p in _strokes[i].points) {
        if ((p - pos).distance < threshold + _strokes[i].size) {
          setState(() {
            final removed = _strokes.removeAt(i);
            _redoStack.add(removed);
          });
          return;
        }
      }
    }
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _redoStack.add(_strokes.removeLast()));
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() => _strokes.add(_redoStack.removeLast()));
  }

  void _clearAll() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.addAll(_strokes);
      _strokes.clear();
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Toolbar
  // ═══════════════════════════════════════════════════════════════
  Widget _buildToolbar() {
    final hasStrokes = _strokes.isNotEmpty;
    final hasRedo = _redoStack.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AiraColors.creamDk.withValues(alpha: 0.6))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Undo / Redo / Clear + Pen size
          Row(
            children: [
              _toolbarActionBtn(
                icon: Icons.undo_rounded,
                label: context.l10n.undo,
                enabled: hasStrokes,
                onTap: _undo,
              ),
              const SizedBox(width: 4),
              _toolbarActionBtn(
                icon: Icons.redo_rounded,
                label: 'Redo',
                enabled: hasRedo,
                onTap: _redo,
              ),
              const SizedBox(width: 4),
              _toolbarActionBtn(
                icon: Icons.delete_outline_rounded,
                label: context.l10n.clear,
                enabled: hasStrokes,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text(context.l10n.deleteAll,
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
                      content: Text(
                          context.l10n.clearAllStrokes,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(context.l10n.cancel)),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _clearAll();
                          },
                          child: Text(context.l10n.delete,
                              style: GoogleFonts.plusJakartaSans(
                                  color: AiraColors.terra, fontWeight: FontWeight.w700)),
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
                    max: 10,
                    divisions: 9,
                    onChanged: (v) => setState(() => _penSize = v),
                  ),
                ),
              ),
              Text(
                '${_penSize.toStringAsFixed(0)}px',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 11, color: AiraColors.muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: Color picker + Eraser
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
              ? (isDanger
                  ? AiraColors.terra.withValues(alpha: 0.08)
                  : AiraColors.charcoal.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Page Styles
// ═══════════════════════════════════════════════════════════════════
enum _PageStyle {
  blank(Icons.crop_square_rounded, 'เปล่า', 'Blank'),
  lined(Icons.format_line_spacing_rounded, 'เส้นบรรทัด', 'Lined'),
  grid(Icons.grid_on_rounded, 'ตาราง', 'Grid'),
  dotGrid(Icons.grain_rounded, 'จุด', 'Dot Grid');

  final IconData icon;
  final String labelTh;
  final String labelEn;
  const _PageStyle(this.icon, this.labelTh, this.labelEn);
}

// ═══════════════════════════════════════════════════════════════════
// Page Line Painter
// ═══════════════════════════════════════════════════════════════════
class _PageLinePainter extends CustomPainter {
  final _PageStyle style;
  const _PageLinePainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    if (style == _PageStyle.blank) return;

    final linePaint = Paint()
      ..color = const Color(0xFFD0C8BC).withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    if (style == _PageStyle.lined || style == _PageStyle.grid) {
      for (double y = 32; y < size.height; y += 28) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
    }
    if (style == _PageStyle.grid) {
      for (double x = 28; x < size.width; x += 28) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      }
    }
    if (style == _PageStyle.dotGrid) {
      final dotPaint = Paint()
        ..color = const Color(0xFFD0C8BC).withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (double y = 20; y < size.height; y += 20) {
        for (double x = 20; x < size.width; x += 20) {
          canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PageLinePainter old) => old.style != style;
}

// ═══════════════════════════════════════════════════════════════════
// Stroke & Painter — consistent with FaceDiagramScreen
// ═══════════════════════════════════════════════════════════════════
class _Stroke {
  final List<Offset> points;
  final Color color;
  final double size;
  const _Stroke({required this.points, required this.color, required this.size});
}

class _StrokesPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final _Stroke? currentStroke;
  const _StrokesPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, _Stroke stroke) {
    if (stroke.points.length < 2) {
      // Single dot
      if (stroke.points.isNotEmpty) {
        canvas.drawCircle(
          stroke.points.first,
          stroke.size / 2,
          Paint()
            ..color = stroke.color
            ..style = PaintingStyle.fill,
        );
      }
      return;
    }

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

    if (outlinePoints.isEmpty) return;

    final path = Path();
    path.moveTo(outlinePoints.first.dx, outlinePoints.first.dy);
    for (int i = 1; i < outlinePoints.length - 1; i++) {
      final mid = Offset(
        (outlinePoints[i].dx + outlinePoints[i + 1].dx) / 2,
        (outlinePoints[i].dy + outlinePoints[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(outlinePoints[i].dx, outlinePoints[i].dy, mid.dx, mid.dy);
    }
    if (outlinePoints.length > 1) {
      path.lineTo(outlinePoints.last.dx, outlinePoints.last.dy);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = stroke.color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════
// Notepad Section — embedded in Patient Profile
// ═══════════════════════════════════════════════════════════════════
class NotepadSection extends ConsumerWidget {
  final String patientId;
  const NotepadSection({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final notepadsAsync = ref.watch(_notepadsByPatientProvider(patientId));

    return notepadsAsync.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: AiraColors.woodMid),
      )),
      error: (e, s) => Center(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Error: $e', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.terra)),
      )),
      data: (notepads) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header + New button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AiraColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.edit_note_rounded, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digital Notepad',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20, fontWeight: FontWeight.w700, color: AiraColors.charcoal,
                        ),
                      ),
                      Text(
                        context.l10n.blankPagesDesc,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted),
                      ),
                    ],
                  ),
                ),
                AiraTapEffect(
                  onTap: () => context.push('/patients/$patientId/notepad'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AiraColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AiraColors.woodDk.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.newNote,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Empty state
            if (notepads.isEmpty)
              _EmptyNotepadState(isThai: isThai, patientId: patientId),

            // Notepad cards grid
            if (notepads.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  final crossAxisCount = isWide ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: notepads.length,
                    itemBuilder: (context, index) {
                      final notepad = notepads[index];
                      return _NotepadCard(
                        notepad: notepad,
                        isThai: isThai,
                        onTap: () => context.push('/patients/$patientId/notepad/${notepad.id}'),
                        onDelete: () => _confirmDelete(context, ref, notepad, isThai),
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DigitalNotepad notepad, bool isThai) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.l10n.deleteThisNote,
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
            '"${notepad.title ?? 'Untitled'}"',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(notepadRepoProvider).deleteNotepad(notepad.id);
              ref.invalidate(_notepadsByPatientProvider(patientId));
            },
            child: Text(context.l10n.delete,
                style: GoogleFonts.plusJakartaSans(
                    color: AiraColors.terra, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotepadState extends StatelessWidget {
  final bool isThai;
  final String patientId;
  const _EmptyNotepadState({required this.isThai, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AiraColors.woodWash.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.edit_note_rounded, size: 40, color: AiraColors.muted.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.noNotesYet,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w600, color: AiraColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.tapNewNoteHint,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AiraColors.muted.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          AiraTapEffect(
            onTap: () => context.push('/patients/$patientId/notepad'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AiraColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AiraColors.woodDk.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.startWriting,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotepadCard extends StatelessWidget {
  final DigitalNotepad notepad;
  final bool isThai;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _NotepadCard({
    required this.notepad,
    required this.isThai,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = notepad.createdAt != null
        ? DateFormat('dd MMM yyyy\nHH:mm').format(notepad.createdAt!)
        : '';
    final strokeCount =
        (notepad.canvasData['strokes'] as List<dynamic>?)?.length ?? 0;

    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AiraColors.woodDk.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview area (miniature of the page)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AiraColors.parchment,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Stack(
                  children: [
                    // Show stroke count as visual indicator
                    Center(
                      child: Icon(
                        Icons.edit_note_rounded,
                        size: 36,
                        color: AiraColors.woodWash.withValues(alpha: 0.5),
                      ),
                    ),
                    if (strokeCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AiraColors.woodMid.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$strokeCount strokes',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AiraColors.woodMid,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notepad.title ?? 'Untitled',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AiraColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            color: AiraColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  AiraTapEffect(
                    onTap: onDelete,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AiraColors.terra.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 15, color: AiraColors.terra),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
