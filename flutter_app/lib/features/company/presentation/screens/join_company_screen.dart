import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass/liquid_glass.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/widgets/auth_background.dart';
import '../../domain/value_objects/company_role.dart';
import '../providers/company_providers.dart';
import '../widgets/company_role_picker_sheet.dart';
import '../widgets/company_role_x.dart';
import 'invite_code_scanner_screen.dart';

/// Two ways in, one screen: `request_to_join_company()` (files a
/// pending request, a director must approve) or
/// `accept_company_invitation()` (pre-authorized by a director already,
/// activates immediately) — see
/// supabase/migrations/20260713000036_company_registration_module.sql.
class JoinCompanyScreen extends ConsumerStatefulWidget {
  const JoinCompanyScreen({super.key});

  @override
  ConsumerState<JoinCompanyScreen> createState() => _JoinCompanyScreenState();
}

class _JoinCompanyScreenState extends ConsumerState<JoinCompanyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _codeController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _messageController = TextEditingController();
  CompanyRole? _requestedRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _inviteCodeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickRole() async {
    final picked = await CompanyRolePickerSheet.open(
      context,
      current: _requestedRole,
    );
    if (picked != null) setState(() => _requestedRole = picked);
  }

  Future<void> _scanInviteCode() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const InviteCodeScannerScreen()),
    );
    if (scanned != null) {
      _inviteCodeController.text = scanned;
    }
  }

  Future<void> _submitByCode() async {
    final strings = ref.read(appStringsProvider);
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      AppToast.show(
        strings.joinCompanyCodeRequiredError,
        tone: ToastTone.error,
      );
      return;
    }
    if (_requestedRole == null) {
      AppToast.show(
        strings.joinCompanyRoleRequiredError,
        tone: ToastTone.error,
      );
      return;
    }

    final failure = await ref
        .read(membershipControllerProvider.notifier)
        .requestToJoin(
          companyCode: code,
          requestedRole: _requestedRole!,
          message: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
        );

    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
      return;
    }
    AppToast.show(strings.joinCompanyRequestSentToast, tone: ToastTone.success);
    context.go(RoutePaths.waitingApproval);
  }

  Future<void> _submitByInvite() async {
    final strings = ref.read(appStringsProvider);
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) {
      AppToast.show(
        strings.joinCompanyInviteCodeRequiredError,
        tone: ToastTone.error,
      );
      return;
    }

    final failure = await ref
        .read(membershipControllerProvider.notifier)
        .acceptInvitation(
          code: code,
          message: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
        );

    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
      return;
    }
    AppToast.show(
      strings.joinCompanyInviteAcceptedToast,
      tone: ToastTone.success,
    );
    context.go(RoutePaths.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final state = ref.watch(membershipControllerProvider);
    final isLoading = state.isLoading;

    return AuthBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: LiquidGlass(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          strings.joinCompanyTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(text: strings.joinCompanyTabByCode),
                            Tab(text: strings.joinCompanyTabByInvite),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, _) => _tabController.index == 0
                              ? _byCodeForm(strings)
                              : _byInviteForm(strings),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: strings.joinCompanyMessageLabel,
                          controller: _messageController,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: _tabController.index == 0
                              ? strings.joinCompanySubmitButton
                              : strings.joinCompanyAcceptInviteButton,
                          onPressed: isLoading
                              ? null
                              : (_tabController.index == 0
                                    ? _submitByCode
                                    : _submitByInvite),
                          loading: isLoading,
                          icon: LucideIcons.check,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _byCodeForm(dynamic strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: strings.joinCompanyCodeLabel,
          controller: _codeController,
          prefixIcon: LucideIcons.building2,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),
        MotionInkWell(
          onTap: _pickRole,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: strings.joinCompanyRoleLabel,
            ),
            child: Text(_requestedRole?.label(strings) ?? ''),
          ),
        ),
      ],
    );
  }

  Widget _byInviteForm(dynamic strings) {
    return AppTextField(
      label: strings.joinCompanyInviteCodeLabel,
      controller: _inviteCodeController,
      prefixIcon: LucideIcons.ticket,
      textInputAction: TextInputAction.next,
      suffixIcon: IconButton(
        icon: const Icon(LucideIcons.qrCode, size: 20),
        onPressed: _scanInviteCode,
      ),
    );
  }
}
