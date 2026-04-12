import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/patients/patient_list_screen.dart';
import '../features/patients/patient_profile_screen.dart';
import '../features/patients/patient_form_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/calendar/appointment_form_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/product_library_screen.dart';
import '../features/settings/service_library_screen.dart';
import '../features/settings/privacy_policy_screen.dart';
import '../features/settings/inventory_screen.dart';
import '../features/settings/audit_log_screen.dart';
import '../features/settings/pin_management_screen.dart';
import '../features/settings/consent_template_screen.dart';
import '../features/settings/notification_settings_screen.dart';
import '../features/settings/messaging_config_screen.dart';
import '../features/settings/clinic_info_screen.dart';
import '../features/settings/staff_management_screen.dart';
import '../features/settings/treatment_rule_screen.dart';
import '../features/treatments/treatment_form_screen.dart';
import '../core/models/models.dart';
import '../features/courses/course_list_screen.dart';
import '../features/courses/course_form_screen.dart';
import '../features/courses/course_overview_screen.dart';
import '../features/financial/financial_screen.dart';
import '../features/patients/consent_form_screen.dart';
import '../features/patients/face_diagram_screen.dart';
import '../features/patients/digital_notepad_screen.dart';
import '../core/widgets/aira_scaffold.dart';
import '../core/widgets/access_guard.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/dashboard',
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AiraScaffold(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/patients',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PatientListScreen(),
          ),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CalendarScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AccessGuard(
              permission: AiraPermission.settings,
              child: SettingsScreen(),
            ),
          ),
        ),
      ],
    ),

    // ─── Patient ──────────────────────────────────────────────
    GoRoute(
      path: '/patients/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PatientFormScreen(patientId: 'new'),
    ),
    GoRoute(
      path: '/patients/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => PatientProfileScreen(
        patientId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/patients/:id/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => PatientFormScreen(
        patientId: state.pathParameters['id']!,
      ),
    ),

    // ─── Treatment (SOAP) ────────────────────────────────────
    GoRoute(
      path: '/patients/:pid/treatments/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final catStr = state.uri.queryParameters['category'];
        final category = catStr != null ? TreatmentCategory.fromDb(catStr) : null;
        return AccessGuard(
          permission: AiraPermission.clinical,
          child: TreatmentFormScreen(
            patientId: state.pathParameters['pid']!,
            initialCategory: category,
          ),
        );
      },
    ),
    GoRoute(
      path: '/patients/:pid/treatments/:tid/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AccessGuard(
        permission: AiraPermission.clinical,
        child: TreatmentFormScreen(
          patientId: state.pathParameters['pid']!,
          treatmentId: state.pathParameters['tid']!,
        ),
      ),
    ),

    // ─── Appointments ────────────────────────────────────────
    GoRoute(
      path: '/appointments/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final dateStr = state.uri.queryParameters['date'];
        final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
        return AppointmentFormScreen(initialDate: date);
      },
    ),
    GoRoute(
      path: '/appointments/:id/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AppointmentFormScreen(
        appointmentId: state.pathParameters['id']!,
      ),
    ),

    // ─── Courses ─────────────────────────────────────────────
    GoRoute(
      path: '/courses',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final patientId = state.uri.queryParameters['patientId'];
        return AccessGuard(
          permission: AiraPermission.financial,
          child: CourseListScreen(patientId: patientId),
        );
      },
    ),
    GoRoute(
      path: '/courses/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final patientId = state.uri.queryParameters['patientId'];
        return AccessGuard(
          permission: AiraPermission.financial,
          child: CourseFormScreen(initialPatientId: patientId),
        );
      },
    ),
    GoRoute(
      path: '/courses/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AccessGuard(
        permission: AiraPermission.financial,
        child: CourseFormScreen(
          courseId: state.pathParameters['id']!,
        ),
      ),
    ),

    // ─── Consent Form ──────────────────────────────────────
    GoRoute(
      path: '/patients/:pid/consent',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AccessGuard(
        permission: AiraPermission.clinical,
        child: ConsentFormScreen(
          patientId: state.pathParameters['pid']!,
          treatmentRecordId: state.uri.queryParameters['tid'],
        ),
      ),
    ),

    // ─── Face Diagram (new) ────────────────────────────────
    GoRoute(
      path: '/patients/:pid/diagram',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AccessGuard(
        permission: AiraPermission.clinical,
        child: FaceDiagramScreen(
          patientId: state.pathParameters['pid']!,
          treatmentRecordId: state.uri.queryParameters['tid'],
          savedDiagramId: state.uri.queryParameters['diagramId'],
        ),
      ),
    ),

    // ─── Digital Notepad ─────────────────────────────────────
    GoRoute(
      path: '/patients/:pid/notepad',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AccessGuard(
        permission: AiraPermission.clinical,
        child: DigitalNotepadScreen(
          patientId: state.pathParameters['pid']!,
        ),
      ),
    ),
    GoRoute(
      path: '/patients/:pid/notepad/:nid',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AccessGuard(
        permission: AiraPermission.clinical,
        child: DigitalNotepadScreen(
          patientId: state.pathParameters['pid']!,
          notepadId: state.pathParameters['nid']!,
        ),
      ),
    ),

    // ─── Financial ───────────────────────────────────────────
    GoRoute(
      path: '/settings/financial',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.financial,
        child: FinancialScreen(),
      ),
    ),

    // ─── Product & Service Library ───────────────────────────
    GoRoute(
      path: '/settings/products',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.settings,
        child: ProductLibraryScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/services',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.settings,
        child: ServiceLibraryScreen(),
      ),
    ),

    // ─── Privacy Policy (PDPA) ─────────────────────────────────
    GoRoute(
      path: '/settings/privacy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),

    // ─── Inventory / Stock Management ───────────────────────
    GoRoute(
      path: '/settings/inventory',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.settings,
        child: InventoryScreen(),
      ),
    ),

    // ─── PIN Management ─────────────────────────────────
    GoRoute(
      path: '/settings/security',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.settings,
        child: PinManagementScreen(),
      ),
    ),

    // ─── Consent Templates ───────────────────────────────
    GoRoute(
      path: '/settings/consent-templates',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.settings,
        child: ConsentTemplateScreen(),
      ),
    ),

    // ─── Audit Logs ───────────────────────────────────
    GoRoute(
      path: '/settings/audit-logs',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.settings,
        child: AuditLogScreen(),
      ),
    ),

    // ─── Clinic Info ───────────────────────────────────
    GoRoute(
      path: '/settings/clinic-info',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.settings,
        child: ClinicInfoScreen(),
      ),
    ),

    // ─── Staff Management ──────────────────────────────
    GoRoute(
      path: '/settings/staff',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.settings,
        child: StaffManagementScreen(),
      ),
    ),

    // ─── Treatment Rules ───────────────────────────────
    GoRoute(
      path: '/settings/treatment-rules',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.settings,
        child: TreatmentRuleScreen(),
      ),
    ),

    // ─── Course Overview ───────────────────────────────
    GoRoute(
      path: '/settings/course-overview',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.financial,
        child: CourseOverviewScreen(),
      ),
    ),

    // ─── Notification Settings ─────────────────────────
    GoRoute(
      path: '/settings/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.settings,
        child: NotificationSettingsScreen(),
      ),
    ),

    // ─── Messaging Config ──────────────────────────────
    GoRoute(
      path: '/settings/messaging',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccessGuard(
        permission: AiraPermission.settings,
        child: MessagingConfigScreen(),
      ),
    ),
  ],
);
