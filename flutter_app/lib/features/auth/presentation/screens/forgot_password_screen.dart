import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass/liquid_glass.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_background.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppToast.show(strings.authFieldRequired, tone: ToastTone.error);
      return;
    }

    setState(() => _loading = true);
    final result = await ref.read(sendPasswordResetUseCaseProvider).call(email);
    if (!mounted) return;
    setState(() => _loading = false);

    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        setState(() => _sent = true);
        AppToast.show(strings.authResetPasswordSent, tone: ToastTone.success);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: LiquidGlass(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          strings.authResetPasswordTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          strings.authCheckYourEmail,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        AppTextField(
                          label: strings.authEmail,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: LucideIcons.mail,
                          enabled: !_sent,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: strings.commonConfirm,
                          onPressed: _sent || _loading ? null : _submit,
                          loading: _loading,
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
}
