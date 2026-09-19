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
import '../../domain/auth_validation.dart' as validation;
import '../providers/auth_providers.dart';
import '../widgets/auth_background.dart';

/// Self-service registration — full name + email + phone + password.
/// Both contacts must then be verified (see RegistrationVerifyScreen)
/// before the router redirect guard lets the user reach
/// RegistrationChoiceScreen — see core/router/onboarding_redirect.dart
/// for that gate and supabase/README.md's "Company registration"
/// section for what happens once they're through it. This screen only
/// creates the Supabase Auth user; it never touches
/// `profiles.company_id`/`status` itself, same as before.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final fullNameError = validation.validateFullName(fullName);
    final emailError = validation.validateEmail(email);
    final phoneError = validation.validatePhone(phone);
    final passwordError = validation.validatePassword(password);
    final firstError =
        fullNameError ?? emailError ?? phoneError ?? passwordError;
    if (firstError != null) {
      AppToast.show(firstError, tone: ToastTone.error);
      return;
    }
    if (password != confirmPassword) {
      AppToast.show(strings.authPasswordsDoNotMatch, tone: ToastTone.error);
      return;
    }

    final failure = await ref
        .read(registrationControllerProvider.notifier)
        .register(
          fullName: fullName,
          email: validation.normalizeEmail(email),
          phone: validation.normalizeKzPhone(phone),
          password: password,
        );

    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
      return;
    }
    context.go(RoutePaths.registerVerify);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final signUpState = ref.watch(registrationControllerProvider);
    final isLoading = signUpState.isLoading;

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
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: LiquidGlass(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          strings.authSignUpTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          strings.authSignUpSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppTextField(
                          label: strings.authFullName,
                          controller: _fullNameController,
                          prefixIcon: LucideIcons.user,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: strings.authEmail,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: LucideIcons.mail,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: strings.authPhone,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: LucideIcons.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: strings.authPassword,
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          prefixIcon: LucideIcons.lock,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
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
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: strings.authConfirmPassword,
                          controller: _confirmPasswordController,
                          obscureText: _obscurePassword,
                          prefixIcon: LucideIcons.lock,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: strings.authSignUpButton,
                          onPressed: isLoading ? null : _submit,
                          loading: isLoading,
                          icon: LucideIcons.userPlus,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextButton(
                          onPressed: () => context.go(RoutePaths.login),
                          child: Text(strings.authHaveAccountLink),
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
