import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/value_objects/company_role.dart';
import '../providers/company_providers.dart';
import '../widgets/company_role_picker_sheet.dart';
import '../widgets/company_role_x.dart';

/// `create_company_invitation()` — director/owner only, single-use by
/// default, expires after 7 days server-side (see
/// supabase/migrations/20260713000036_company_registration_module.sql).
/// No email delivery: no email provider is configured anywhere in this
/// project (see supabase/README.md's "Company registration" section,
/// an explicit scoping decision, not a silent gap) — the code is
/// shared manually, as text or the QR below (reusing `qr_flutter`,
/// already a dependency for the Production module's order QR).
class InviteEmployeeScreen extends ConsumerStatefulWidget {
  const InviteEmployeeScreen({super.key});

  @override
  ConsumerState<InviteEmployeeScreen> createState() =>
      _InviteEmployeeScreenState();
}

class _InviteEmployeeScreenState extends ConsumerState<InviteEmployeeScreen> {
  CompanyRole _role = CompanyRole.assistant;
  int _maxUses = 1;
  int _expiresInHours = 168;

  Future<void> _pickRole() async {
    final picked = await CompanyRolePickerSheet.open(context, current: _role);
    if (picked != null) setState(() => _role = picked);
  }

  Future<void> _generate() async {
    final failure = await ref
        .read(createInvitationControllerProvider.notifier)
        .create(
          role: _role,
          maxUses: _maxUses,
          expiresInHours: _expiresInHours,
        );
    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final state = ref.watch(createInvitationControllerProvider);
    final invitation = state.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.companyInviteTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MotionInkWell(
              onTap: _pickRole,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: strings.companyInviteRoleLabel,
                ),
                child: Text(_role.label(strings)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            MotionInkWell(
              onTap: () async {
                final value = await showDialog<int>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: Text(strings.companyInviteMaxUsesLabel),
                    children: [1, 5, 10, 50]
                        .map(
                          (n) => SimpleDialogOption(
                            onPressed: () => Navigator.of(context).pop(n),
                            child: Text('$n'),
                          ),
                        )
                        .toList(),
                  ),
                );
                if (value != null) setState(() => _maxUses = value);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: strings.companyInviteMaxUsesLabel,
                ),
                child: Text('$_maxUses'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            MotionInkWell(
              onTap: () async {
                final value = await showDialog<int>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: Text(strings.companyInviteExpiresLabel),
                    children: [24, 72, 168, 720]
                        .map(
                          (h) => SimpleDialogOption(
                            onPressed: () => Navigator.of(context).pop(h),
                            child: Text('${h ~/ 24} d'),
                          ),
                        )
                        .toList(),
                  ),
                );
                if (value != null) setState(() => _expiresInHours = value);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: strings.companyInviteExpiresLabel,
                ),
                child: Text('${_expiresInHours ~/ 24} d'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: strings.companyInviteGenerateAction,
              onPressed: state.isLoading ? null : _generate,
              loading: state.isLoading,
              icon: LucideIcons.ticket,
            ),
            if (invitation != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: invitation.code,
                    size: 180,
                    gapless: true,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    invitation.code,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.copy),
                    tooltip: strings.companyInviteCopyAction,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: invitation.code),
                      );
                      if (!context.mounted) return;
                      AppToast.show(
                        strings.companyInviteCopiedToast,
                        tone: ToastTone.success,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                strings.companyInviteEmailNote,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
