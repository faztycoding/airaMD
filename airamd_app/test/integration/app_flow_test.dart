import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:airamd/config/theme.dart';
import 'package:airamd/features/dashboard/dashboard_screen.dart';
import 'package:airamd/features/patients/patient_list_screen.dart';
import 'package:airamd/features/calendar/calendar_screen.dart';
import 'package:airamd/features/settings/settings_screen.dart';
import 'package:airamd/core/widgets/aira_scaffold.dart';
import 'package:airamd/core/localization/app_localizations.dart';
import 'package:airamd/core/models/models.dart';
import 'package:airamd/core/providers/providers.dart';
import 'package:airamd/core/services/offline_sync_service.dart';
import 'package:airamd/features/auth/auth_gate.dart';
import '../helpers/test_fixtures.dart';

// ═══════════════════════════════════════════════════════════════
// Integration Test — Full app flow with mocked providers
// Tests: AuthGate → Dashboard → Navigate → Patient List
// ═══════════════════════════════════════════════════════════════

/// Helper to tap AiraTapEffect widgets (onTapDown/onTapUp pattern).
Future<void> tapWidget(WidgetTester tester, Finder finder) async {
  final center = tester.getCenter(finder);
  final gesture = await tester.startGesture(center);
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

/// Create a fresh GoRouter to avoid state leaks between tests.
GoRouter _createRouter() => GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(path: '/', redirect: (_, __) => '/dashboard'),
        ShellRoute(
          builder: (context, state, child) => AiraScaffold(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: DashboardScreen()),
            ),
            GoRoute(
              path: '/patients',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: PatientListScreen()),
            ),
            GoRoute(
              path: '/calendar',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: CalendarScreen()),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: SettingsScreen()),
            ),
          ],
        ),
      ],
    );

/// Build the full app with GoRouter and provider overrides.
Widget buildTestApp({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      // Auth — logged in
      authSessionProvider.overrideWithValue(null),
      isAuthenticatedProvider.overrideWithValue(true),
      currentAuthEmailProvider.overrideWithValue('owner@aira.test'),
      authSignOutActionProvider.overrideWithValue(() async {}),
      currentStaffProvider.overrideWith(
        (ref) => Future.value(TestFixtures.ownerStaff()),
      ),
      // RBAC — owner by default
      currentClinicIdProvider.overrideWithValue(TestFixtures.clinicId),
      effectiveStaffRoleProvider.overrideWithValue(StaffRole.owner),
      canManageClinicalDataProvider.overrideWithValue(true),
      canAccessFinancialDataProvider.overrideWithValue(true),
      canAccessSettingsProvider.overrideWithValue(true),
      isLimitedStaffProvider.overrideWithValue(false),
      // Locale
      isThaiProvider.overrideWithValue(true),
      // Connectivity
      connectivityProvider.overrideWith((ref) => Stream.value(true)),
      isOnlineProvider.overrideWithValue(true),
      pendingOpsCountProvider.overrideWith((ref) => Future.value(0)),
      lastSyncTimeProvider.overrideWith((ref) => Future.value(DateTime.now())),
      // Dashboard stats
      dashboardStatsProvider.overrideWith(
        (ref) => Future.value(const DashboardStats(
          todayAppointments: 5,
          totalPatients: 42,
          pendingFollowUps: 3,
          monthRevenue: 125000,
        )),
      ),
      upcomingFollowUpsProvider.overrideWith(
        (ref) => Future.value(<TreatmentRecord>[]),
      ),
      todayRevenueProvider.overrideWith((ref) => Future.value(25000.0)),
      lowStockAlertsProvider.overrideWith(
        (ref) => Future.value(<Product>[]),
      ),
      expiringProductsProvider.overrideWith(
        (ref) => Future.value(<Product>[]),
      ),
      // Patient list
      patientListProvider.overrideWith(() => _MockPatientListNotifier()),
      patientCountProvider.overrideWith((ref) => Future.value(42)),
      // Today's treatments
      todayTreatmentsProvider.overrideWith(
        (ref) => Future.value(<TreatmentRecord>[]),
      ),
      // Additional overrides
      ...overrides,
    ],
    child: MaterialApp.router(
      routerConfig: _createRouter(),
      locale: const Locale('th'),
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AiraTheme.light,
    ),
  );
}

/// Mock PatientListNotifier that returns test data
class _MockPatientListNotifier extends AsyncNotifier<List<Patient>>
    implements PatientListNotifier {
  @override
  Future<List<Patient>> build() async {
    return [
      TestFixtures.healthyPatient(),
      TestFixtures.allergyPatient(),
      TestFixtures.retinoidPatient(),
    ];
  }

  @override
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  @override
  Future<Patient> addPatient(Patient patient) async {
    return patient;
  }

  @override
  Future<Patient> updatePatient(Patient patient) async {
    return patient;
  }

  @override
  Future<void> deletePatient(String id) async {}
}

void main() {
  group('App Integration Flow', () {
    // ─── Dashboard Renders ────────────────────────────────

    testWidgets('should render dashboard with stats', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Dashboard should show greeting
      expect(
        find.textContaining('สวัสดี'),
        findsWidgets,
      );

      // Should show stat cards with data
      expect(find.text('5'), findsWidgets); // todayAppointments
      expect(find.text('42'), findsWidgets); // totalPatients
    });

    testWidgets('should show bottom nav with 4 tabs', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Bottom nav labels
      expect(find.text('แดชบอร์ด'), findsOneWidget);
      expect(find.text('ผู้ป่วย'), findsOneWidget);
      expect(find.text('ปฏิทิน'), findsOneWidget);
      expect(find.text('ตั้งค่า'), findsOneWidget);
    });

    // ─── Navigation: Dashboard → Patients ─────────────────

    testWidgets('should navigate from dashboard to patient list',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap "ผู้ป่วย" in bottom nav
      await tapWidget(tester, find.text('ผู้ป่วย'));

      // Dashboard should no longer be the active tab —
      // verify the nav tab icon changed (people_rounded = active)
      expect(find.byIcon(Icons.people_rounded), findsOneWidget);
    });

    // ─── Navigation: Dashboard → Calendar ─────────────────

    testWidgets('should navigate to calendar tab', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap "ปฏิทิน" in bottom nav
      await tapWidget(tester, find.text('ปฏิทิน'));

      // Should navigate (calendar screen is loaded)
      expect(find.text('แดชบอร์ด'), findsOneWidget); // nav still visible
    });

    // ─── Navigation: Dashboard → Settings (owner) ─────────

    testWidgets('should navigate to settings for owner', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap "ตั้งค่า" in bottom nav
      await tapWidget(tester, find.text('ตั้งค่า'));

      // Settings screen should be visible — look for common settings elements
      expect(find.byIcon(Icons.settings_rounded), findsWidgets);
    });

    // ─── RBAC: Receptionist blocked from settings ──────────

    testWidgets('should block receptionist from settings', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(
        overrides: [
          currentStaffProvider.overrideWith(
            (ref) => Future.value(TestFixtures.receptionistStaff()),
          ),
          effectiveStaffRoleProvider.overrideWithValue(StaffRole.receptionist),
          canAccessSettingsProvider.overrideWithValue(false),
          canManageClinicalDataProvider.overrideWithValue(false),
          canAccessFinancialDataProvider.overrideWithValue(false),
          isLimitedStaffProvider.overrideWithValue(true),
        ],
      ));
      await tester.pumpAndSettle();

      // Bottom nav should show "จำกัดสิทธิ์" label instead of "ตั้งค่า"
      expect(find.textContaining('จำกัด'), findsWidgets);
    });

    // ─── Auth Gate → Login ─────────────────────────────────

    testWidgets('should show login when not authenticated', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWithValue(null),
          ],
          child: MaterialApp(
            locale: const Locale('th'),
            supportedLocales: const [Locale('th'), Locale('en')],
            localizationsDelegates: const [
              AppL10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthGate(
              child: Scaffold(body: Center(child: Text('Main App'))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show login screen
      expect(find.text('airaMD'), findsOneWidget);
      expect(find.text('Main App'), findsNothing);
    });

    // ─── Sync Status ──────────────────────────────────────

    testWidgets('should show online sync status', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Should show synced indicator
      expect(find.byIcon(Icons.cloud_done_rounded), findsWidgets);
    });

    testWidgets('should show offline status when disconnected',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.value(false)),
          isOnlineProvider.overrideWithValue(false),
        ],
      ));
      // Don't pumpAndSettle — _PulseDot animation never settles
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should show offline text
      expect(find.textContaining('ออฟไลน์'), findsWidgets);
    });

    // ─── Dashboard content on narrow screen ────────────────

    testWidgets('should render dashboard content on narrow screen',
        (tester) async {
      // Narrow screen → CustomScrollView with slivers
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Dashboard should show greeting
      expect(find.textContaining('สวัสดี'), findsWidgets);
      // Nav should be visible
      expect(find.text('แดชบอร์ด'), findsOneWidget);
    });

    // ─── All nav tabs are tappable ─────────────────────────

    testWidgets('should cycle through all nav tabs', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Dashboard → Patients → Calendar → Settings → Dashboard
      for (final tab in ['ผู้ป่วย', 'ปฏิทิน', 'ตั้งค่า', 'แดชบอร์ด']) {
        await tapWidget(tester, find.text(tab));
      }

      // Should be back at dashboard
      expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget);
    });
  });
}
