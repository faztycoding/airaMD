import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../core/widgets/aira_tap_effect.dart';

/// Full-screen Before / After comparison with synchronized zoom/pan
/// across up to 4 panels, plus one-click composite export.
class PhotoComparisonScreen extends StatefulWidget {
  final String setLabel;
  final List<ComparisonSlot> slots;
  final String clinicName;

  const PhotoComparisonScreen({
    super.key,
    required this.setLabel,
    required this.slots,
    this.clinicName = 'airaMD Clinic',
  });

  @override
  State<PhotoComparisonScreen> createState() => _PhotoComparisonScreenState();
}

class ComparisonSlot {
  final String label;
  final String? imageUrl;
  final String? dateLabel;

  const ComparisonSlot({
    required this.label,
    this.imageUrl,
    this.dateLabel,
  });
}

class _PhotoComparisonScreenState extends State<PhotoComparisonScreen> {
  // A single controller drives all panels simultaneously
  final TransformationController _controller = TransformationController();
  final GlobalKey _repaintKey = GlobalKey();
  bool _exporting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _exportComposite() async {
    setState(() => _exporting = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/airamd_comparison_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '${widget.setLabel} — ${widget.clinicName}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งออกไม่สำเร็จ: $e'), backgroundColor: AiraColors.terra),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final filledSlots = widget.slots.where((s) => s.imageUrl != null).toList();
    // Show all slots (even empty) up to 4
    final displaySlots = widget.slots.take(4).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ─── Header ───
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
            ),
            child: Row(
              children: [
                AiraTapEffect(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.setLabel,
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'เปรียบเทียบ ${filledSlots.length} รูป — บีบเพื่อซูมพร้อมกัน',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                // Reset zoom
                AiraTapEffect(
                  onTap: _resetZoom,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.zoom_out_map_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                // Export
                AiraTapEffect(
                  onTap: _exporting ? null : _exportComposite,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_exporting)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        else
                          const Icon(Icons.share_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'ส่งออก',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Comparison Panels ───
          Expanded(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: Colors.black,
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: isLandscape
                      ? _buildHorizontalLayout(displaySlots)
                      : _buildGridLayout(displaySlots),
                ),
              ),
            ),
          ),

          // ─── Bottom labels ───
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            color: Colors.black.withValues(alpha: 0.9),
            child: Row(
              children: [
                Icon(Icons.verified_user_rounded, size: 14, color: AiraColors.sage.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  widget.clinicName,
                  style: GoogleFonts.playfairDisplay(fontSize: 13, color: Colors.white54),
                ),
                const Spacer(),
                Text(
                  'airaMD',
                  style: GoogleFonts.playfairDisplay(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.woodPale.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Landscape: 4 panels side by side
  Widget _buildHorizontalLayout(List<ComparisonSlot> slots) {
    return Row(
      children: slots.map((slot) => Expanded(child: _buildPanel(slot))).toList(),
    );
  }

  /// Portrait: 2x2 grid
  Widget _buildGridLayout(List<ComparisonSlot> slots) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              if (slots.isNotEmpty) Expanded(child: _buildPanel(slots[0])),
              if (slots.length > 1) Expanded(child: _buildPanel(slots[1])),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              if (slots.length > 2) Expanded(child: _buildPanel(slots[2])),
              if (slots.length > 3) Expanded(child: _buildPanel(slots[3])),
              // Fill remaining space
              if (slots.length <= 2)
                const Expanded(child: SizedBox())
              else if (slots.length == 3)
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(ComparisonSlot slot) {
    return Container(
      margin: const EdgeInsets.all(2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image or placeholder
          if (slot.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                slot.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _emptyPanel(),
              ),
            )
          else
            _emptyPanel(),

          // Label overlay at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    slot.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (slot.dateLabel != null)
                    Text(
                      slot.dateLabel!,
                      style: GoogleFonts.spaceGrotesk(fontSize: 10, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Icon(Icons.image_not_supported_rounded, size: 32, color: Colors.white.withValues(alpha: 0.2)),
      ),
    );
  }
}
