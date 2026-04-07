import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../app.dart';

const _pinStorageKey = 'airamd_pin_code';
final _secureStorage = FlutterSecureStorage();

/// Allows the user to change their PIN or toggle auto-lock.
class PinManagementScreen extends ConsumerStatefulWidget {
  const PinManagementScreen({super.key});

  @override
  ConsumerState<PinManagementScreen> createState() =>
      _PinManagementScreenState();
}

class _PinManagementScreenState extends ConsumerState<PinManagementScreen> {
  // Change-PIN flow
  _PinStep _step = _PinStep.enterCurrent;
  String _enteredPin = '';
  String _newPin = '';
  bool _isError = false;
  String? _errorKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final autoLock = ref.watch(autoLockEnabledProvider);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          // ─── Header ───
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B4F3A), Color(0xFF8B6650)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4F3A).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AiraTapEffect(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.security,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        l.securitySubtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Content ───
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
                  children: [
                    // Auto-lock toggle
                    _sectionCard(
                      child: SwitchListTile.adaptive(
                        title: Text(l.autoLock,
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: AiraColors.charcoal)),
                        subtitle: Text(l.autoLockSubtitle,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: AiraColors.muted)),
                        value: autoLock,
                        activeColor: AiraColors.woodMid,
                        onChanged: (v) =>
                            ref.read(autoLockEnabledProvider.notifier).state =
                                v,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Change PIN section
                    _sectionCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lock_rounded,
                                    size: 20, color: AiraColors.woodMid),
                                const SizedBox(width: 10),
                                Text(l.changePin,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AiraColors.charcoal)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(l.changePinSubtitle,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12, color: AiraColors.muted)),
                            const SizedBox(height: 20),
                            // Status label
                            Center(
                              child: Text(
                                _stepLabel(l),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isError
                                      ? AiraColors.terra
                                      : AiraColors.charcoal,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // PIN dots
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(6, (i) {
                                  final filled = i < _enteredPin.length;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isError
                                          ? AiraColors.terra
                                          : filled
                                              ? AiraColors.woodDk
                                              : Colors.transparent,
                                      border: Border.all(
                                        color: _isError
                                            ? AiraColors.terra
                                            : filled
                                                ? AiraColors.woodDk
                                                : AiraColors.woodPale,
                                        width: 2,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Compact numpad
                            _buildCompactNumPad(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  String _stepLabel(AppL10n l) {
    if (_errorKey == '_mismatch') return l.pinMismatch;
    if (_errorKey == '_incorrect') return l.pinIncorrect;
    switch (_step) {
      case _PinStep.enterCurrent:
        return l.enterCurrentPin;
      case _PinStep.enterNew:
        return l.enterNewPin;
      case _PinStep.confirmNew:
        return l.confirmNewPin;
    }
  }

  void _onDigit(String digit) {
    if (_enteredPin.length >= 6) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit;
      _isError = false;
      _errorKey = null;
    });
    if (_enteredPin.length == 6) {
      Future.delayed(const Duration(milliseconds: 150), _onComplete);
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _isError = false;
      _errorKey = null;
    });
  }

  Future<void> _onComplete() async {
    switch (_step) {
      case _PinStep.enterCurrent:
        final saved = await _secureStorage.read(key: _pinStorageKey);
        if (_enteredPin == saved) {
          setState(() {
            _step = _PinStep.enterNew;
            _enteredPin = '';
          });
        } else {
          setState(() {
            _isError = true;
            _errorKey = '_incorrect';
            _enteredPin = '';
          });
        }
        break;
      case _PinStep.enterNew:
        setState(() {
          _newPin = _enteredPin;
          _enteredPin = '';
          _step = _PinStep.confirmNew;
        });
        break;
      case _PinStep.confirmNew:
        if (_enteredPin == _newPin) {
          await _secureStorage.write(key: _pinStorageKey, value: _enteredPin);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.pinChanged)),
            );
            context.pop();
          }
        } else {
          setState(() {
            _isError = true;
            _errorKey = '_mismatch';
            _enteredPin = '';
            _newPin = '';
            _step = _PinStep.enterNew;
          });
        }
        break;
    }
  }

  Widget _buildCompactNumPad() {
    const btnSize = 52.0;

    Widget numBtn(String label) {
      return AiraTapEffect(
        onTap: () => _onDigit(label),
        child: Container(
          width: btnSize,
          height: btnSize,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AiraColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AiraColors.creamDk),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AiraColors.charcoal,
              ),
            ),
          ),
        ),
      );
    }

    Widget emptyBtn() => SizedBox(width: btnSize + 8, height: btnSize + 8);

    Widget backBtn() {
      return AiraTapEffect(
        onTap: _onBackspace,
        child: Container(
          width: btnSize,
          height: btnSize,
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Center(
            child: Icon(Icons.backspace_outlined,
                size: 22, color: AiraColors.muted),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          numBtn('1'),
          numBtn('2'),
          numBtn('3'),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          numBtn('4'),
          numBtn('5'),
          numBtn('6'),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          numBtn('7'),
          numBtn('8'),
          numBtn('9'),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          emptyBtn(),
          numBtn('0'),
          backBtn(),
        ]),
      ],
    );
  }
}

enum _PinStep { enterCurrent, enterNew, confirmNew }
