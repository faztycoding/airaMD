import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/aira_tap_effect.dart';

// ═══════════════════════════════════════════════════════════════
// LOGIN SCREEN — World-class clinic auth experience
// Warm luxury aesthetic, smooth animations, Supabase Auth
// ═══════════════════════════════════════════════════════════════

enum _AuthMode { login, signup, forgotPassword, otpVerify }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeCtrl.forward();
      _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _logoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    _clinicCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode newMode) {
    _slideCtrl.reset();
    _fadeCtrl.reset();
    setState(() {
      _mode = newMode;
      _errorMessage = null;
    });
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  // ─── Auth Actions ────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMessage = null; });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      // Auth state change will be handled by auth_gate
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e.message));
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _errorMessage = context.l10n.passwordMismatch);
      return;
    }
    setState(() { _loading = true; _errorMessage = null; });

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        data: {
          'full_name': _nameCtrl.text.trim(),
          'clinic_name': _clinicCtrl.text.trim(),
        },
      );

      if (res.user != null && mounted) {
        // Create clinic + staff records
        await _createClinicAndStaff(res.user!);
        _switchMode(_AuthMode.login);
        setState(() => _errorMessage = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.signupSuccess),
              backgroundColor: AiraColors.sage,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e.message));
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createClinicAndStaff(User user) async {
    final client = Supabase.instance.client;
    // Create clinic
    final clinicData = await client.from('clinics').insert({
      'name': _clinicCtrl.text.trim().isEmpty
          ? '${_nameCtrl.text.trim()} Clinic'
          : _clinicCtrl.text.trim(),
    }).select().single();

    // Create owner staff record
    await client.from('staff').insert({
      'clinic_id': clinicData['id'],
      'user_id': user.id,
      'full_name': _nameCtrl.text.trim(),
      'role': 'OWNER',
      'is_active': true,
    });
  }

  Future<void> _handleForgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = context.l10n.enterEmailFirst);
      return;
    }
    setState(() { _loading = true; _errorMessage = null; });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.resetEmailSent),
            backgroundColor: AiraColors.sage,
          ),
        );
        _switchMode(_AuthMode.login);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e.message));
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login')) return context.l10n.invalidCredentials;
    if (lower.contains('email not confirmed')) return context.l10n.emailNotConfirmed;
    if (lower.contains('already registered')) return context.l10n.emailAlreadyUsed;
    if (lower.contains('weak password')) return context.l10n.weakPassword;
    if (lower.contains('rate limit')) return context.l10n.tooManyAttempts;
    return message;
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide > 600;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // ─── Background gradient circles ───
            Positioned(
              top: -size.width * 0.3,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AiraColors.woodWash.withValues(alpha: 0.3),
                      AiraColors.cream.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.4,
              left: -size.width * 0.3,
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AiraColors.woodPale.withValues(alpha: 0.15),
                      AiraColors.cream.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Main content ───
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 60 : 28,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 460 : 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: topPad > 40 ? 0 : 20),
                        // ─── Logo ───
                        ScaleTransition(
                          scale: _logoScale,
                          child: _buildLogo(),
                        ),
                        const SizedBox(height: 12),
                        // ─── Title ───
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Column(
                            children: [
                              Text(
                                'airaMD',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AiraColors.charcoal,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.l10n.loginSubtitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AiraColors.muted,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ─── Form Card ───
                        SlideTransition(
                          position: _slideAnim,
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: _buildFormCard(),
                          ),
                        ),

                        const SizedBox(height: 40),
                        // ─── Footer ───
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Text(
                            '${context.l10n.poweredBy} airaMD v1.0',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AiraColors.muted.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A3F2C), Color(0xFF7A5840), Color(0xFFA8806A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A3F2C).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'aira',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode title
            Text(
              _modeTitle,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AiraColors.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _modeSubtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AiraColors.muted,
              ),
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AiraColors.terra.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AiraColors.terra.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 18, color: AiraColors.terra),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.terra),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Mode-specific fields
            if (_mode == _AuthMode.signup) ...[
              _buildField(
                controller: _nameCtrl,
                label: context.l10n.fullName,
                icon: Icons.person_outline_rounded,
                validator: (v) => v == null || v.trim().isEmpty ? context.l10n.fieldRequired : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _clinicCtrl,
                label: context.l10n.clinicName,
                icon: Icons.local_hospital_rounded,
                hint: context.l10n.clinicNameHint,
              ),
              const SizedBox(height: 14),
            ],

            // Email
            _buildField(
              controller: _emailCtrl,
              label: context.l10n.email,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return context.l10n.fieldRequired;
                if (!v.contains('@') || !v.contains('.')) return context.l10n.invalidEmail;
                return null;
              },
            ),

            if (_mode != _AuthMode.forgotPassword) ...[
              const SizedBox(height: 14),
              // Password
              _buildField(
                controller: _passwordCtrl,
                label: context.l10n.password,
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 20,
                    color: AiraColors.muted,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return context.l10n.fieldRequired;
                  if (_mode == _AuthMode.signup && v.length < 8) return context.l10n.passwordTooShort;
                  return null;
                },
              ),
            ],

            if (_mode == _AuthMode.signup) ...[
              const SizedBox(height: 14),
              _buildField(
                controller: _confirmCtrl,
                label: context.l10n.confirmPassword,
                icon: Icons.lock_outline_rounded,
                obscure: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 20,
                    color: AiraColors.muted,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return context.l10n.fieldRequired;
                  if (v != _passwordCtrl.text) return context.l10n.passwordMismatch;
                  return null;
                },
              ),
            ],

            // Forgot password link
            if (_mode == _AuthMode.login) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: AiraTapEffect(
                  onTap: () => _switchMode(_AuthMode.forgotPassword),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      context.l10n.forgotPassword,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AiraColors.woodMid,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Primary action button
            _buildPrimaryButton(),

            const SizedBox(height: 20),

            // Mode switch
            _buildModeSwitch(),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, size: 20, color: AiraColors.woodMid),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AiraColors.cream.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AiraColors.terra),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AiraColors.terra, width: 1.5),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.terra),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return AiraTapEffect(
      onTap: _loading ? null : _onPrimaryAction,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: _loading ? null : AiraColors.heroGradient,
          color: _loading ? AiraColors.woodPale : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _loading
              ? []
              : [
                  BoxShadow(
                    color: AiraColors.woodDk.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  _primaryButtonLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            _modeSwitchLabel,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        AiraTapEffect(
          onTap: () => _switchMode(_modeSwitchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Text(
              _modeSwitchAction,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AiraColors.woodMid,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

  void _onPrimaryAction() {
    HapticFeedback.lightImpact();
    switch (_mode) {
      case _AuthMode.login:
        _handleLogin();
        break;
      case _AuthMode.signup:
        _handleSignup();
        break;
      case _AuthMode.forgotPassword:
        _handleForgotPassword();
        break;
      case _AuthMode.otpVerify:
        break;
    }
  }

  String get _modeTitle {
    final l = context.l10n;
    switch (_mode) {
      case _AuthMode.login: return l.loginTitle;
      case _AuthMode.signup: return l.signupTitle;
      case _AuthMode.forgotPassword: return l.forgotPasswordTitle;
      case _AuthMode.otpVerify: return l.verifyOtp;
    }
  }

  String get _modeSubtitle {
    final l = context.l10n;
    switch (_mode) {
      case _AuthMode.login: return l.loginDesc;
      case _AuthMode.signup: return l.signupDesc;
      case _AuthMode.forgotPassword: return l.forgotPasswordDesc;
      case _AuthMode.otpVerify: return l.otpDesc;
    }
  }

  String get _primaryButtonLabel {
    final l = context.l10n;
    switch (_mode) {
      case _AuthMode.login: return l.loginButton;
      case _AuthMode.signup: return l.signupButton;
      case _AuthMode.forgotPassword: return l.sendResetLink;
      case _AuthMode.otpVerify: return l.verifyButton;
    }
  }

  String get _modeSwitchLabel {
    final l = context.l10n;
    switch (_mode) {
      case _AuthMode.login: return l.noAccount;
      case _AuthMode.signup: return l.haveAccount;
      case _AuthMode.forgotPassword: return l.rememberedPassword;
      case _AuthMode.otpVerify: return '';
    }
  }

  String get _modeSwitchAction {
    final l = context.l10n;
    switch (_mode) {
      case _AuthMode.login: return l.signupButton;
      case _AuthMode.signup: return l.loginButton;
      case _AuthMode.forgotPassword: return l.loginButton;
      case _AuthMode.otpVerify: return l.resendOtp;
    }
  }

  _AuthMode get _modeSwitchTarget {
    switch (_mode) {
      case _AuthMode.login: return _AuthMode.signup;
      case _AuthMode.signup: return _AuthMode.login;
      case _AuthMode.forgotPassword: return _AuthMode.login;
      case _AuthMode.otpVerify: return _AuthMode.login;
    }
  }
}
