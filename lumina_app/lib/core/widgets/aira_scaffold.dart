import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../providers/providers.dart';
import 'aira_tap_effect.dart';
import '../localization/app_localizations.dart';


/// Main scaffold with luxury bottom navigation bar
class AiraScaffold extends ConsumerWidget {
  final Widget child;

  const AiraScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/patients')) return 1;
    if (location.startsWith('/calendar')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index, {required bool canAccessSettings, required bool isThai}) {
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/patients');
      case 2:
        context.go('/calendar');
      case 3:
        if (!canAccessSettings) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isThai
                    ? 'บัญชีนี้ไม่มีสิทธิ์เข้าถึงการตั้งค่า'
                    : 'This account cannot access settings.',
              ),
              backgroundColor: AiraColors.woodDk,
            ),
          );
          return;
        }
        context.go('/settings');
    }
  }

  List<_NavItem> _tabs(AppL10n l10n, bool canAccessSettings) => [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, l10n.dashboard),
    _NavItem(Icons.people_outline_rounded, Icons.people_rounded, l10n.patients),
    _NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded, l10n.calendar),
    _NavItem(
      canAccessSettings ? Icons.settings_outlined : Icons.lock_outline_rounded,
      canAccessSettings ? Icons.settings_rounded : Icons.lock_rounded,
      canAccessSettings
          ? l10n.settings
          : (l10n.isThai ? 'จำกัด' : 'Restricted'),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);
    final isThai = ref.watch(isThaiProvider);
    final canAccessSettings = ref.watch(canAccessSettingsProvider);
    final l10n = AppL10n.of(context);
    final tabs = _tabs(l10n, canAccessSettings);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: child,
      extendBody: false,
      bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AiraColors.white,
              border: Border(
                top: BorderSide(
                  color: AiraColors.woodPale.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;
                  return Center(
                    heightFactor: 1.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SyncStatusBar(),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(tabs.length, (i) {
                                final isActive = i == currentIndex;
                                final tab = tabs[i];
                                return Expanded(
                                  child: AiraTapEffect(
                                    onTap: () => _onTap(
                                      context,
                                      i,
                                      canAccessSettings: canAccessSettings,
                                      isThai: isThai,
                                    ),
                                    scaleDown: 0.92,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOutCubic,
                                      margin: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compact ? 8 : (isActive ? 16 : 12),
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AiraColors.woodDk.withValues(alpha: 0.10)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isActive ? tab.activeIcon : tab.icon,
                                            size: compact ? 22 : 24,
                                            color: isActive
                                                ? AiraColors.woodDk
                                                : AiraColors.muted,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            tab.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: compact ? 10 : 11,
                                              fontWeight: isActive
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isActive
                                                  ? AiraColors.woodDk
                                                  : AiraColors.muted,
                                            ),
                                          ),
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 250),
                                            margin: const EdgeInsets.only(top: 3),
                                            width: isActive ? 5 : 0,
                                            height: isActive ? 5 : 0,
                                            decoration: const BoxDecoration(
                                              color: AiraColors.woodDk,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

/// Subtle animated sync status indicator — lives above the nav row.
class _SyncStatusBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final isThai = ref.watch(isThaiProvider);

    final isOnline = connectivityAsync.when(
      data: (online) => online,
      loading: () => true,
      error: (_, _) => false,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      child: Container(
        key: ValueKey(isOnline),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: isOnline
              ? AiraColors.sage.withValues(alpha: 0.08)
              : AiraColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOnline
                ? AiraColors.sage.withValues(alpha: 0.18)
                : AiraColors.gold.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated pulse dot
            _PulseDot(color: isOnline ? AiraColors.sage : AiraColors.gold, pulse: !isOnline),
            const SizedBox(width: 6),
            Text(
              isOnline
                  ? (isThai ? 'ข้อมูลซิงค์แล้ว' : 'Synced')
                  : (isThai ? 'รอการเชื่อมต่อ' : 'Offline'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isOnline ? AiraColors.sage : AiraColors.gold,
              ),
            ),
            if (isOnline) ...[
              const SizedBox(width: 4),
              Icon(Icons.cloud_done_rounded, size: 13, color: AiraColors.sage.withValues(alpha: 0.7)),
            ] else ...[
              const SizedBox(width: 4),
              Icon(Icons.cloud_off_rounded, size: 13, color: AiraColors.gold.withValues(alpha: 0.8)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tiny animated dot that pulses when offline to draw subtle attention.
class _PulseDot extends StatefulWidget {
  final Color color;
  final bool pulse;
  const _PulseDot({required this.color, required this.pulse});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.pulse && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(
        opacity: widget.pulse ? _opacity.value : 1.0,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

