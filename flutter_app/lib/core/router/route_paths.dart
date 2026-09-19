/// Central route path constants — every `context.go(...)` call in the
/// app references these instead of a raw string literal, so a path
/// rename is a one-file change.
abstract class RoutePaths {
  // Auth (outside the shell) — accounts are either director-provisioned
  // (Supabase Auth admin API, see ROLES_AND_PERMISSIONS.md) or
  // self-registered via [register]/the onboarding screens below (see
  // supabase/README.md's "Company registration" section).
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const register = '/register';
  // Dual-contact registration's email/phone verification step — see
  // core/router/onboarding_redirect.dart's `contactsVerified` gate and
  // RegistrationVerifyScreen, which switches between its email-pending
  // and phone-OTP views based on live Supabase Auth state rather than
  // needing separate paths for each.
  static const registerVerify = '/register/verify';

  // Onboarding (outside the shell) — reached once signed in but not
  // yet an active member of a company; see
  // core/router/onboarding_redirect.dart for the state machine that
  // routes here.
  static const onboarding = '/onboarding';
  static const onboardingCreateCompany = '/onboarding/create-company';
  static const onboardingJoinCompany = '/onboarding/join-company';
  static const waitingApproval = '/onboarding/waiting-approval';
  static const accessBlocked = '/onboarding/access-blocked';

  // Shell tabs (bottom nav on mobile, sidebar on desktop/tablet — see
  // MOBILE_NAVIGATION.md / RESPONSIVE_LAYOUT.md)
  static const dashboard = '/dashboard';
  static const measurements = '/measurements';
  static const quickEstimate = '/quick-estimate';
  // Notifications (Stage 4 Part 2's UI) — nested in the `dashboard`
  // branch, opened via the bell icon on the dashboard header.
  static const notifications = '/notifications';
  static const orders = '/orders';
  static const orderNew = '/orders/new';
  static String orderDetail(String id) => '$orders/$id';
  static String orderEdit(String id) => '$orders/$id/edit';
  static const clients = '/clients';
  static String clientDetail(String id) => '$clients/$id';
  static const payments = '/payments';
  static const employees = '/employees';
  static const employeeNew = '/employees/new';
  static String employeeDetail(String userId) => '$employees/$userId';
  static String employeeEdit(String userId) => '$employees/$userId/edit';
  // Company management — director/owner only, see EmployeesListScreen's
  // app bar action.
  static const companyRequests = '$employees/requests';
  static const companyInvite = '$employees/invite';
  static const companyMembers = '$employees/members';
  static const partners = '/partners';
  static const partnerNew = '/partners/new';
  static String partnerDetail(String id) => '$partners/$id';
  static String partnerEdit(String id) => '$partners/$id/edit';
  static const analytics = '/analytics';
  static const production = '/production';
  static String productionOrderDetail(String orderId) => '$production/$orderId';
  static const warehouse = '/warehouse';
  static String warehouseMaterialDetail(String materialId) =>
      '$warehouse/$materialId';
  static const purchases = '/purchases';
  static const purchaseOrderNew = '/purchases/new';
  static const purchasesAnalytics = '/purchases/analytics';
  static String purchaseOrderDetail(String id) => '$purchases/$id';
  static String purchaseOrderEdit(String id) => '$purchases/$id/edit';
  static String purchaseOrderReceive(String id) => '$purchases/$id/receive';
  static String supplierPayments(String partnerId) =>
      '$purchases/suppliers/$partnerId/payments';
  static const settings = '/settings';

  // Company Settings & Subscription Management (Stage 3) — nested
  // inside the `settings` shell branch (so the tab stays highlighted
  // and the bottom nav/sidebar chrome persists) despite the different
  // `/company/...` path prefix; see app_router.dart's own comment on
  // this branch for why a StatefulShellBranch can hold more than one
  // root-level GoRoute.
  static const companySettings = '/company/settings';
  static const subscription = '/company/subscription';
  static const billing = '/company/billing';

  // Audit Log UI (Stage 4 Part 3) — director-only, nested in the same
  // `settings` branch as the Company Settings/Subscription/Billing
  // routes above.
  static const auditLog = '/company/audit-log';
  static String auditLogDetail(String id) => '$auditLog/$id';
}
