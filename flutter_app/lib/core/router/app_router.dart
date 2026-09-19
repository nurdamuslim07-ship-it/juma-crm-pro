import '../../features/quick_estimate/estimate_screen.dart';
import '../../features/measurements/measurements_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/development_access.dart';

import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/audit/domain/entities/audit_log_entry.dart';
import '../../features/audit/presentation/screens/audit_log_detail_screen.dart';
import '../../features/audit/presentation/screens/audit_log_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registration_verify_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/clients/presentation/screens/client_detail_screen.dart';
import '../../features/clients/presentation/screens/clients_list_screen.dart';
import '../../features/company/presentation/screens/access_blocked_screen.dart';
import '../../features/company/presentation/screens/billing_screen.dart';
import '../../features/company/presentation/screens/company_members_screen.dart';
import '../../features/company/presentation/screens/company_settings_screen.dart';
import '../../features/company/presentation/screens/create_company_screen.dart';
import '../../features/company/presentation/screens/director_pending_requests_screen.dart';
import '../../features/company/presentation/screens/invite_employee_screen.dart';
import '../../features/company/presentation/screens/join_company_screen.dart';
import '../../features/company/presentation/screens/registration_choice_screen.dart';
import '../../features/company/presentation/screens/settings_screen.dart';
import '../../features/company/presentation/screens/subscription_screen.dart';
import '../../features/company/presentation/screens/waiting_approval_screen.dart';
import '../../features/company/presentation/widgets/subscription_guard.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/employees/domain/entities/employee.dart';
import '../../features/employees/presentation/screens/employee_detail_screen.dart';
import '../../features/employees/presentation/screens/employee_form_screen.dart';
import '../../features/employees/presentation/screens/employees_list_screen.dart';
import '../../features/orders/domain/entities/customer_order.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/order_form_screen.dart';
import '../../features/orders/presentation/screens/orders_list_screen.dart';
import '../../features/partners/domain/entities/partner.dart';
import '../../features/partners/presentation/screens/partner_detail_screen.dart';
import '../../features/partners/presentation/screens/partner_form_screen.dart';
import '../../features/partners/presentation/screens/partners_list_screen.dart';
import '../../features/payments/presentation/screens/payments_list_screen.dart';
import '../../features/production/presentation/screens/production_order_detail_screen.dart';
import '../../features/production/presentation/screens/production_queue_screen.dart';
import '../../features/purchases/domain/entities/purchase_order_detail.dart';
import '../../features/purchases/presentation/screens/purchase_analytics_screen.dart';
import '../../features/purchases/presentation/screens/purchase_order_detail_screen.dart';
import '../../features/purchases/presentation/screens/purchase_order_form_screen.dart';
import '../../features/purchases/presentation/screens/purchase_orders_screen.dart';
import '../../features/purchases/presentation/screens/receive_materials_screen.dart';
import '../../features/purchases/presentation/screens/supplier_payments_screen.dart';
import '../../features/warehouse/presentation/screens/material_detail_screen.dart';
import '../../features/warehouse/presentation/screens/materials_screen.dart';
import '../providers/supabase_provider.dart';
import '../widgets/record_not_found_screen.dart';
import 'app_shell.dart';
import 'onboarding_redirect.dart';
import 'route_paths.dart';

/// GoRouter with a [StatefulShellRoute] for the 8 authenticated modules
/// (see UI_ARCHITECTURE.md's routing decision — no router existed in
/// the audited web app at all) and a redirect guard that sends signed-
/// out users to /login and signed-in users away from the auth screens.
///
/// Per SECURITY_PLAN.md / ROLES_AND_PERMISSIONS.md: this redirect is a
/// UX convenience only, exactly like the web app's hidden-button
/// pattern was flagged as insufficient — the real authorization
/// boundary is Supabase RLS, enforced server-side regardless of what
/// this router allows the UI to render.
final routerProvider = Provider<GoRouter>((ref) {
  final authStream = ref.watch(supabaseClientProvider).auth.onAuthStateChange;

  final refresh = GoRouterRefreshStream(authStream);
  ref.onDispose(refresh.dispose);
  final router = GoRouter(
    initialLocation: RoutePaths.dashboard,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentSession != null;
      final user = ref.read(currentUserProvider);
      // Auth emits the session before the asynchronous profile/roles query
      // completes. Do not mistake that loading window for a new signup.
      final pending = ref.read(pendingRegistrationProvider);
      return resolveOnboardingRedirect(
        loggedIn: loggedIn,
        profileLoaded: user != null,
        matchedLocation: state.matchedLocation,
        hasPendingRegistration: pending != null,
        contactsVerified:
            skipDevelopmentContactVerification(user?.id) ||
            ((user?.isEmailVerified ?? false) &&
                (user?.isPhoneVerified ?? false)),
        companyId: user?.companyId,
        status: user?.status,
        companyIsActive: user?.companyIsActive ?? true,
      );
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: RoutePaths.registerVerify,
        builder: (context, state) => const RegistrationVerifyScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const RegistrationChoiceScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingCreateCompany,
        builder: (context, state) => const CreateCompanyScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingJoinCompany,
        builder: (context, state) => const JoinCompanyScreen(),
      ),
      GoRoute(
        path: RoutePaths.waitingApproval,
        builder: (context, state) => const WaitingApprovalScreen(),
      ),
      GoRoute(
        path: RoutePaths.accessBlocked,
        builder: (context, state) => const AccessBlockedScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dashboard,
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: RoutePaths.quickEstimate,
                builder: (context, state) =>
                    const SubscriptionGuard(child: EstimateScreen()),
              ),
              GoRoute(
                path: RoutePaths.measurements,
                builder: (context, state) =>
                    const SubscriptionGuard(child: MeasurementsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.orders,
                builder: (context, state) =>
                    const SubscriptionGuard(child: OrdersListScreen()),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const OrderFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        OrderDetailScreen(orderId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        // Same fix as the audit log detail route: a
                        // direct/reloaded navigation (a web concern)
                        // carries no `extra`, and a bare
                        // `as CustomerOrder?` cast would silently
                        // open this as a blank create-mode form under
                        // an edit URL instead of the real order. This
                        // route is only ever reached from the detail
                        // screen's own edit button, which always
                        // passes a real order — null/wrong-type here
                        // only happens on that reload edge case.
                        builder: (context, state) {
                          if (state.extra is! CustomerOrder) {
                            return const RecordNotFoundScreen(
                              backTo: RoutePaths.orders,
                            );
                          }
                          return OrderFormScreen(
                            existing: state.extra as CustomerOrder,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.clients,
                builder: (context, state) => const ClientsListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ClientDetailScreen(
                      clientId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.payments,
                builder: (context, state) => const SubscriptionGuard(
                  allowDirectorBypass: true,
                  child: PaymentsListScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.employees,
                builder: (context, state) => const EmployeesListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const EmployeeFormScreen(),
                  ),
                  GoRoute(
                    path: 'requests',
                    builder: (context, state) =>
                        const DirectorPendingRequestsScreen(),
                  ),
                  GoRoute(
                    path: 'invite',
                    builder: (context, state) => const InviteEmployeeScreen(),
                  ),
                  GoRoute(
                    path: 'members',
                    builder: (context, state) => const CompanyMembersScreen(),
                  ),
                  GoRoute(
                    path: ':userId',
                    builder: (context, state) => EmployeeDetailScreen(
                      userId: state.pathParameters['userId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        // Same fix as the order edit route above (see
                        // its comment) — a direct/reloaded navigation
                        // carries no `extra`.
                        builder: (context, state) {
                          if (state.extra is! Employee) {
                            return const RecordNotFoundScreen(
                              backTo: RoutePaths.employees,
                            );
                          }
                          return EmployeeFormScreen(
                            existing: state.extra as Employee,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.partners,
                builder: (context, state) => const PartnersListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const PartnerFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => PartnerDetailScreen(
                      partnerId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        // Same fix as the order edit route above (see
                        // its comment) — a direct/reloaded navigation
                        // carries no `extra`.
                        builder: (context, state) {
                          if (state.extra is! Partner) {
                            return const RecordNotFoundScreen(
                              backTo: RoutePaths.partners,
                            );
                          }
                          return PartnerFormScreen(
                            existing: state.extra as Partner,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.analytics,
                builder: (context, state) =>
                    const SubscriptionGuard(child: AnalyticsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.production,
                builder: (context, state) =>
                    const SubscriptionGuard(child: ProductionQueueScreen()),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) => ProductionOrderDetailScreen(
                      orderId: state.pathParameters['orderId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.warehouse,
                builder: (context, state) =>
                    const SubscriptionGuard(child: MaterialsScreen()),
                routes: [
                  GoRoute(
                    path: ':materialId',
                    builder: (context, state) => MaterialDetailScreen(
                      materialId: state.pathParameters['materialId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.purchases,
                builder: (context, state) => const PurchaseOrdersScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) =>
                        const PurchaseOrderFormScreen(),
                  ),
                  GoRoute(
                    path: 'analytics',
                    builder: (context, state) =>
                        const PurchaseAnalyticsScreen(),
                  ),
                  GoRoute(
                    path: 'suppliers/:partnerId/payments',
                    builder: (context, state) => SupplierPaymentsScreen(
                      partnerId: state.pathParameters['partnerId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => PurchaseOrderDetailScreen(
                      orderId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        // Same fix as the order edit route above (see
                        // its comment) — a direct/reloaded navigation
                        // carries no `extra`.
                        builder: (context, state) {
                          if (state.extra is! PurchaseOrderDetail) {
                            return const RecordNotFoundScreen(
                              backTo: RoutePaths.purchases,
                            );
                          }
                          return PurchaseOrderFormScreen(
                            existing: state.extra as PurchaseOrderDetail,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'receive',
                        builder: (context, state) => ReceiveMaterialsScreen(
                          orderId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
              // Company Settings & Subscription Management (Stage 3) —
              // literal `/company/...` paths per spec, kept as sibling
              // root-level routes within the SAME branch as `/settings`
              // (a StatefulShellBranch's `routes` is just a
              // List<RouteBase>, not limited to one root path) so the
              // Settings tab stays highlighted and shell chrome
              // persists while navigating between them.
              GoRoute(
                path: RoutePaths.companySettings,
                builder: (context, state) => const CompanySettingsScreen(),
              ),
              GoRoute(
                path: RoutePaths.subscription,
                builder: (context, state) => const SubscriptionScreen(),
              ),
              GoRoute(
                path: RoutePaths.billing,
                builder: (context, state) => const BillingScreen(),
              ),
              GoRoute(
                path: RoutePaths.auditLog,
                builder: (context, state) => const AuditLogScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    // AuditLogDetailScreen has no fetch-by-id fallback
                    // by design (its own doc comment: the list row
                    // already has everything it shows) — it requires
                    // a real AuditLogEntry via `extra`. A direct/
                    // refreshed navigation with no `extra` (mainly a
                    // web concern) used to crash on a bare cast here.
                    // Never reaching that cast — showing a real
                    // "record not found" screen instead of a bare
                    // redirect — is the smallest fix that doesn't
                    // touch AuditLogDetailScreen itself.
                    builder: (context, state) {
                      final entry = state.extra;
                      if (entry is! AuditLogEntry) {
                        return const RecordNotFoundScreen(
                          backTo: RoutePaths.auditLog,
                        );
                      }
                      return AuditLogDetailScreen(entry: entry);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.listen(currentUserProvider, (_, next) => router.refresh());
  ref.listen(pendingRegistrationProvider, (_, next) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

/// Bridges a Supabase auth event [Stream] into a [Listenable] so
/// GoRouter re-evaluates its redirect on sign-in/sign-out — the
/// standard go_router pattern for stream-driven refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
