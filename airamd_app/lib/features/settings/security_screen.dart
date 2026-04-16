import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../app.dart';

const _pinStorageKey = 'airamd_pin_code';
final _secureStorage = FlutterSecureStorage();

/// Combined Security screen: Change Password + PIN Management + Auto-lock
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  // ─── Password change ───
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _pwObscureNew = true;
  bool _pwObscureConfirm = true;
  bool _pwSaving = false;

  // ─── PIN change ───
  _PinStep _pinStep = _PinStep.enterCurrent;
  String _enteredPin = '';
  String _newPin = '';
  bool _pinError = false;
  String? _pinErrorKey;
  bool _hasExistingPin = false;

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  Future<void> _checkExistingPin() async {
    try {
      final stored = await _secureStorage.read(key: _pinStorageKey);
      if (mounted) {
        setState(() {
          _hasExistingPin = stored != null && stored.isNotEmpty;
          if (!_hasExistingPin) _pinStep = _PinStep.enterNew;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Keychain read failed: $e');
      if (mounted) setState(() => _pinStep = _PinStep.enterNew);
    }
  }

  @override
  void dispose() {
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // Password change logic
  // ═══════════════════════════════════════════════════════════════
  Future<void> _changePassword() async {
    final l = context.l10n;
    final newPw = _newPwController.text.trim();
    final confirmPw = _confirmPwController.text.trim();

    if (newPw.length < 8) {
      _showSnack(l.passwordTooShort, isError: true);
      return;
    }
    if (newPw != confirmPw) {
      _showSnack(l.passwordMismatch, isError: true);
      return;
    }

    setState(() => _pwSaving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.updateUser(
        UserAttributes(password: newPw),
      );
      _newPwController.clear();
      _confirmPwController.clear();
      if (mounted) _showSnack(l.passwordChanged);
    } catch (e) {
      if (mounted) _showSnack('${l.passwordChangeFailed}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _pwSaving = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PIN change logic
  // ═══════════════════════════════════════════════════════════════
  void _onPinDigit(String digit) {
    if (_enteredPin.length >= 6) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pinError = false;
      _pinErrorKey = null;
      _enteredPin += digit;
    });
    if (_enteredPin.length == 6) {
      Future.delayed(const Duration(milliseconds: 150), _handlePinComplete);
    }
  }

  void _onPinBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
  }

  Future<void> _handlePinComplete() async {
    switch (_pinStep) {
      case _PinStep.enterCurrent:
        try {
          final stored = await _secureStorage.read(key: _pinStorageKey);
          if (_enteredPin == stored) {
            setState(() {
              _enteredPin = '';
              _pinStep = _PinStep.enterNew;
            });
          } else {
            setState(() {
              _pinError = true;
              _pinErrorKey = 'pinIncorrect';
              _enteredPin = '';
            });
            HapticFeedback.heavyImpact();
          }
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Keychain error: $e');
          setState(() {
            _enteredPin = '';
            _pinStep = _PinStep.enterNew;
          });
        }
        break;

      case _PinStep.enterNew:
        setState(() {
          _newPin = _enteredPin;
          _enteredPin = '';
          _pinStep = _PinStep.confirmNew;
        });
        break;

      case _PinStep.confirmNew:
        if (_enteredPin == _newPin) {
          try {
            await _secureStorage.write(key: _pinStorageKey, value: _newPin);
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ Keychain write failed: $e');
          }
          if (mounted) {
            _showSnack(context.l10n.pinChanged);
            setState(() {
              _enteredPin = '';
              _newPin = '';
              _hasExistingPin = true;
              _pinStep = _PinStep.enterCurrent;
            });
          }
        } else {
          setState(() {
            _pinError = true;
            _pinErrorKey = 'pinMismatch';
            _enteredPin = '';
            _pinStep = _PinStep.enterNew;
          });
          HapticFeedback.heavyImpact();
        }
        break;
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AiraColors.terra : AiraColors.sage,
    ));
  }

  // ═══════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════
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
              left: 20, right: 20, bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: AiraColors.heroGradient,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: AiraColors.woodDk.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                AiraTapEffect(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.security, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text(l.securitySubtitle, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ),
                Icon(Icons.shield_rounded, color: Colors.white.withValues(alpha: 0.3), size: 32),
              ],
            ),
          ),

          // ─── Body ───
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ════════════════════════════════
                  // Section 1: Change Password
                  // ════════════════════════════════
                  _sectionHeader(Icons.lock_rounded, l.accountSection, l.changePasswordSubtitle),
                  const SizedBox(height: 12),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _passwordField(
                          controller: _newPwController,
                          label: l.newPassword,
                          obscure: _pwObscureNew,
                          onToggle: () => setState(() => _pwObscureNew = !_pwObscureNew),
                        ),
                        const SizedBox(height: 12),
                        _passwordField(
                          controller: _confirmPwController,
                          label: l.confirmNewPassword,
                          obscure: _pwObscureConfirm,
                          onToggle: () => setState(() => _pwObscureConfirm = !_pwObscureConfirm),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: AiraSizes.buttonHeight,
                          child: ElevatedButton(
                            onPressed: _pwSaving ? null : _changePassword,
                            child: _pwSaving
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(l.changePassword),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ════════════════════════════════
                  // Section 2: PIN Lock
                  // ════════════════════════════════
                  _sectionHeader(Icons.dialpad_rounded, l.pinSection, l.changePinSubtitle),
                  const SizedBox(height: 12),
                  _card(
                    child: Column(
                      children: [
                        // Status text
                        Text(
                          _pinStepLabel(l),
                          style: AiraFonts.body(fontSize: 18, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // PIN dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (i) {
                            final filled = i < _enteredPin.length;
                            return Container(
                              width: 16, height: 16,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _pinError
                                    ? AiraColors.terra
                                    : filled
                                        ? AiraColors.woodDk
                                        : AiraColors.woodPale.withValues(alpha: 0.4),
                                border: Border.all(
                                  color: _pinError ? AiraColors.terra : AiraColors.woodPale,
                                  width: 1.5,
                                ),
                              ),
                            );
                          }),
                        ),
                        if (_pinError && _pinErrorKey != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _pinErrorKey == 'pinMismatch' ? l.pinMismatch : l.pinIncorrect,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.terra, fontWeight: FontWeight.w600),
                          ),
                        ],
                        const SizedBox(height: 20),
                        // Number pad
                        _buildPinPad(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ════════════════════════════════
                  // Section 3: Auto-lock toggle
                  // ════════════════════════════════
                  _card(
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: AiraColors.sage.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.lock_clock_rounded, color: AiraColors.sage, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.autoLock, style: AiraFonts.body(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text(l.autoLockSubtitle, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: autoLock,
                          activeColor: AiraColors.woodDk,
                          onChanged: (v) {
                            ref.read(autoLockEnabledProvider.notifier).state = v;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Helper widgets
  // ═══════════════════════════════════════════════════════════════
  String _pinStepLabel(AppL10n l) {
    return switch (_pinStep) {
      _PinStep.enterCurrent => l.enterCurrentPin,
      _PinStep.enterNew => l.enterNewPin,
      _PinStep.confirmNew => l.confirmNewPin,
    };
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AiraColors.woodMid),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AiraFonts.heading(fontSize: 20)),
            Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
          ],
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AiraColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AiraShadows.card,
      ),
      child: child,
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AiraFonts.body(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AiraColors.muted, size: 20),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    const digits = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: digits.map((d) {
        if (d.isEmpty) return const SizedBox(width: 64, height: 52);
        if (d == '⌫') {
          return SizedBox(
            width: 64, height: 52,
            child: AiraTapEffect(
              onTap: _onPinBackspace,
              child: Container(
                decoration: BoxDecoration(
                  color: AiraColors.parchment,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Icon(Icons.backspace_rounded, color: AiraColors.muted, size: 22)),
              ),
            ),
          );
        }
        return SizedBox(
          width: 64, height: 52,
          child: AiraTapEffect(
            onTap: () => _onPinDigit(d),
            child: Container(
              decoration: BoxDecoration(
                color: AiraColors.parchment,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  d,
                  style: AiraFonts.numeric(fontSize: 22),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

enum _PinStep { enterCurrent, enterNew, confirmNew }
