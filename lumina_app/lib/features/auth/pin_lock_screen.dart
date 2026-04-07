import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../../config/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/localization/app_localizations.dart';

// ─── Providers ────────────────────────────────────────────────
const _pinStorageKey = 'airamd_pin_code';
const _pinEnabledKey = 'airamd_pin_enabled';

final _secureStorage = FlutterSecureStorage();

final pinEnabledProvider = FutureProvider<bool>((ref) async {
  final v = await _secureStorage.read(key: _pinEnabledKey);
  return v == 'true';
});

final savedPinProvider = FutureProvider<String?>((ref) async {
  return _secureStorage.read(key: _pinStorageKey);
});

// ─── Lock Screen ──────────────────────────────────────────────
class PinLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _isError = false;
  bool _isSettingUp = false;
  String _firstPin = '';
  String _statusMessage = '';
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _shakeCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _shakeCtrl.reset();
    });

    // Check if PIN is set; if not, go to setup mode
    Future.microtask(() async {
      try {
        final pin = await _secureStorage.read(key: _pinStorageKey);
        if (!mounted) return;
        if (pin == null || pin.isEmpty) {
          setState(() {
            _isSettingUp = true;
            _statusMessage = '';
          });
        } else {
          setState(() => _statusMessage = '');
          _tryBiometric();
        }
      } catch (_) {
        // Secure storage might fail on web — default to setup mode
        if (!mounted) return;
        setState(() {
          _isSettingUp = true;
          _statusMessage = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!canAuth || !isDeviceSupported) return;

      final didAuth = await _localAuth.authenticate(
        localizedReason: context.l10n.biometricReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (didAuth && mounted) {
        widget.onUnlocked();
      }
    } catch (_) {
      // Biometric not available — fall through to PIN
    }
  }

  void _onDigit(String digit) {
    if (_enteredPin.length >= 6) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit;
      _isError = false;
    });
    if (_enteredPin.length == 6) {
      Future.delayed(const Duration(milliseconds: 150), _onPinComplete);
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _isError = false;
    });
  }

  Future<void> _onPinComplete() async {
    if (_isSettingUp) {
      if (_firstPin.isEmpty) {
        // First entry — ask to confirm
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
          _statusMessage = '';
        });
      } else {
        // Confirm entry
        if (_enteredPin == _firstPin) {
          await _secureStorage.write(key: _pinStorageKey, value: _enteredPin);
          await _secureStorage.write(key: _pinEnabledKey, value: 'true');
          if (mounted) widget.onUnlocked();
        } else {
          _shakeCtrl.forward();
          setState(() {
            _isError = true;
            _enteredPin = '';
            _firstPin = '';
            _statusMessage = '_mismatch';
          });
        }
      }
    } else {
      // Verify existing PIN
      final saved = await _secureStorage.read(key: _pinStorageKey);
      if (_enteredPin == saved) {
        if (mounted) widget.onUnlocked();
      } else {
        _shakeCtrl.forward();
        setState(() {
          _isError = true;
          _enteredPin = '';
          _statusMessage = '_incorrect';
        });
      }
    }
  }

  String _resolveStatus(AppL10n l) {
    if (_statusMessage == '_mismatch') return l.pinMismatch;
    if (_statusMessage == '_incorrect') return l.pinIncorrect;
    if (_isSettingUp && _firstPin.isEmpty) return l.setupPin;
    if (_isSettingUp && _firstPin.isNotEmpty) return l.confirmPinAgain;
    return l.enterPinToUnlock;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide > 600;

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 420 : 360),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // ─── Logo / Brand ───
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AiraColors.heroGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AiraColors.woodDk.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'aira',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'airaMD',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AiraColors.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _resolveStatus(l),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: _isError ? AiraColors.terra : AiraColors.muted,
                    fontWeight: _isError ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 36),
                // ─── PIN Dots ───
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeAnim.value * (_shakeCtrl.status == AnimationStatus.forward ? 1 : 0) *
                            ((_shakeCtrl.value * 10).toInt().isEven ? 1 : -1),
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      final filled = i < _enteredPin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: filled ? 18 : 16,
                        height: filled ? 18 : 16,
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
                          boxShadow: filled
                              ? [
                                  BoxShadow(
                                    color: AiraColors.woodDk.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 48),
                // ─── Number Pad ───
                _buildNumPad(isTablet),
                const Spacer(flex: 1),
                // ─── Biometric button ───
                if (!_isSettingUp)
                  TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: Icon(Icons.fingerprint_rounded, color: AiraColors.woodMid, size: 28),
                    label: Text(
                      l.useBiometrics,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AiraColors.woodMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumPad(bool isTablet) {
    final btnSize = isTablet ? 76.0 : 68.0;
    final fontSize = isTablet ? 28.0 : 24.0;

    Widget numBtn(String label) {
      return AiraTapEffect(
        onTap: () => _onDigit(label),
        child: Container(
          width: btnSize,
          height: btnSize,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AiraColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AiraColors.creamDk),
            boxShadow: [
              BoxShadow(
                color: AiraColors.woodDk.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AiraColors.charcoal,
              ),
            ),
          ),
        ),
      );
    }

    Widget emptyBtn() => SizedBox(width: btnSize + 12, height: btnSize + 12);

    Widget backBtn() {
      return AiraTapEffect(
        onTap: _onBackspace,
        child: Container(
          width: btnSize,
          height: btnSize,
          margin: const EdgeInsets.all(6),
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 26,
              color: AiraColors.muted,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [numBtn('1'), numBtn('2'), numBtn('3')]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [numBtn('4'), numBtn('5'), numBtn('6')]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [numBtn('7'), numBtn('8'), numBtn('9')]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [emptyBtn(), numBtn('0'), backBtn()]),
      ],
    );
  }
}
