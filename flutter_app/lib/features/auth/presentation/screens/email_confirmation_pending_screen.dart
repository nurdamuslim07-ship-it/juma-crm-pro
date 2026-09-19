import 'dart:async';

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
import '../providers/auth_providers.dart';
import '../widgets/auth_background.dart';

const _resendCooldownSeconds = 30;

/// Step 3 of the dual-contact registration flow — shown by
/// RegistrationVerifyScreen whenever `currentUserProvider`/
/// `pendingRegistrationProvider` say email confirmation isn't done
/// yet. Two different situations share this one screen:
///
/// - [needsPassword] true: no Supabase session exists on this device
///   (the app was killed/restarted before the confirmation link was
///   clicked) — the password never got persisted anywhere (binding
///   constraint: never store it), so it must be re-entered once to
///   sign in, which also happens to be exactly how Supabase itself
///   validates that the link was actually clicked (`email_not_confirmed`
///   otherwise).
/// - [needsPassword] false: a session already exists (fresh from
///   registration, or confirmation is already done and this is a
///   transient render before the router catches up) — only resend is
///   offered.
class EmailConfirmationPendingScreen extends ConsumerStatefulWidget {
  const EmailConfirmationPendingScreen({
    super.key,
    required this.email,
    required this.needsPassword,
  });

  final String email;
  final bool needsPassword;

  @override
  ConsumerState<EmailConfirmationPendingScreen> createState() =>
      _EmailConfirmationPendingScreenState();
}

class _EmailConfirmationPendingScreenState
    extends ConsumerState<EmailConfirmationPendingScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _passwordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendCooldown -= 1);
      if (_resendCooldown <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    final strings = ref.read(appStringsProvider);
    final failure = await ref
        .read(registrationControllerProvider.notifier)
        .resendEmailConfirmation();
    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
      return;
    }
    AppToast.show(strings.authEmailResent, tone: ToastTone.success);
    _startCooldown();
  }

  Future<void> _continue() async {
    final strings = ref.read(appStringsProvider);
    if (!widget.needsPassword) {
      // Session already exists — just re-check the latest confirmation
      // state from Supabase Auth (source of truth) and let the router
      // redirect guard react once it's caught up.
      await ref
          .read(registrationControllerProvider.notifier)
          .refreshVerificationState();
      return;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      AppToast.show(strings.authFieldRequired, tone: ToastTone.error);
      return;
    }
    final failure = await ref
        .read(registrationControllerProvider.notifier)
        .confirmEmailAndSignIn(password);
    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
    }
    // On success the router redirect guard carries the now-signed-in,
    // email-verified user straight to the phone step — no manual
    // navigation needed here (same pattern as CreateCompanyController).
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final controllerState = ref.watch(registrationControllerProvider);
    final isLoading = controllerState.isLoading;
    final canResend = _resendCooldown <= 0 && !isLoading;

    return AuthBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: () => context.go(RoutePaths.login),
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
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: LiquidGlass(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(LucideIcons.mailCheck, size: 40),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          strings.authEmailConfirmTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          strings.authEmailConfirmSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          widget.email,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          strings.authEmailConfirmInstructions,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (widget.needsPassword) ...[
                          const SizedBox(height: AppSpacing.xl),
                          AppTextField(
                            label: strings.authEnterPasswordToContinue,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: LucideIcons.lock,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _continue(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: strings.authContinueButton,
                          onPressed: isLoading ? null : _continue,
                          loading: isLoading,
                          icon: LucideIcons.arrowRight,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: canResend ? _resend : null,
                          child: Text(
                            canResend
                                ? strings.authResendEmail
                                : '${strings.authResendEmail} ($_resendCooldown)',
                          ),
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
