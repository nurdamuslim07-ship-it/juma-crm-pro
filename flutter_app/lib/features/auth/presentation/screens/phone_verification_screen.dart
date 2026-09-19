import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../domain/auth_validation.dart' as validation;
import '../providers/auth_providers.dart';
import '../widgets/auth_background.dart';

const _resendCooldownSeconds = 30;

/// Step 4 of the dual-contact registration flow — shown by
/// RegistrationVerifyScreen once email is confirmed but
/// `currentUserProvider`'s `isPhoneVerified` is still false. Sends the
/// first SMS OTP itself, exactly once per screen mount (see the class
/// doc on RegistrationController.register for why the controller
/// deliberately does NOT also send one — this is the single place that
/// does, whether arriving fresh from registration or resumed after an
/// app restart with a session that already exists).
class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _codeController = TextEditingController();
  late String _phone;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  bool _sentInitialOtp = false;

  @override
  void initState() {
    super.initState();
    _phone = widget.phone;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sentInitialOtp) {
      _sentInitialOtp = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
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

  Future<void> _sendOtp() async {
    final failure = await ref
        .read(registrationControllerProvider.notifier)
        .sendPhoneOtp(_phone);
    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
      return;
    }
    _startCooldown();
  }

  Future<void> _resend() async {
    final strings = ref.read(appStringsProvider);
    final failure = await ref
        .read(registrationControllerProvider.notifier)
        .sendPhoneOtp(_phone);
    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
      return;
    }
    AppToast.show(strings.authCodeResent, tone: ToastTone.success);
    _startCooldown();
  }

  Future<void> _verify() async {
    final strings = ref.read(appStringsProvider);
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      AppToast.show(strings.authFieldRequired, tone: ToastTone.error);
      return;
    }
    final failure = await ref
        .read(registrationControllerProvider.notifier)
        .verifyPhoneOtp(phone: _phone, token: code);
    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
    }
    // On success the router redirect guard carries the now fully
    // verified user straight to RegistrationChoiceScreen — same
    // pattern as every other onboarding transition in this app.
  }

  Future<void> _changePhone() async {
    final strings = ref.read(appStringsProvider);
    final controller = TextEditingController(text: _phone);
    final newPhone = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.authChangePhone),
        content: AppTextField(
          label: strings.authPhone,
          controller: controller,
          keyboardType: TextInputType.phone,
          prefixIcon: LucideIcons.phone,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(strings.commonConfirm),
          ),
        ],
      ),
    );
    if (newPhone == null || !mounted) return;

    final phoneError = validation.validatePhone(newPhone);
    if (phoneError != null) {
      AppToast.show(phoneError, tone: ToastTone.error);
      return;
    }
    final normalized = validation.normalizeKzPhone(newPhone);

    final pending = ref.read(pendingRegistrationProvider);
    if (pending != null) {
      await ref
          .read(pendingRegistrationProvider.notifier)
          .save(
            PendingRegistration(
              fullName: pending.fullName,
              email: pending.email,
              phone: normalized,
            ),
          );
    }

    setState(() {
      _phone = normalized;
      _codeController.clear();
    });
    await _sendOtp();
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
                        const Icon(LucideIcons.smartphone, size: 40),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          strings.authPhoneVerifyTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          strings.authPhoneVerifySubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          _phone,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppTextField(
                          label: strings.authOtpLabel,
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          prefixIcon: LucideIcons.messageSquare,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onSubmitted: (_) => _verify(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: strings.authOtpVerifyButton,
                          onPressed: isLoading ? null : _verify,
                          loading: isLoading,
                          icon: LucideIcons.checkCircle,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: canResend ? _resend : null,
                          child: Text(
                            canResend
                                ? strings.authResendCode
                                : '${strings.authResendCode} ($_resendCooldown)',
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading ? null : _changePhone,
                          child: Text(strings.authChangePhone),
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
