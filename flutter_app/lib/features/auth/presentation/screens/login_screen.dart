import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/config/development_login.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass/liquid_glass.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_background.dart';

/// Login screen — email or phone + password, verified server-side by
/// Supabase Auth. Two ways into an account now exist side by side: a
/// director provisioning one via the Supabase Auth admin API (see
/// ROLES_AND_PERMISSIONS.md "Director capabilities"), or self-service
/// registration via [SignUpScreen] — company creation/join-approval
/// (see supabase/README.md's "Company registration" section) is what
/// keeps the latter from being the open `handleCustomRegister`-style
/// hole SECURITY_PLAN.md finding #4/#5 flagged in the legacy web app:
/// a fresh signup starts with no company and no permissions until a
/// director approves it or the signer-upper creates their own company.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _developmentLoading = false;

  Future<void> _developmentLogin() async {
    if (_developmentLoading) return;
    setState(() => _developmentLoading = true);
    try {
      await signInToDevelopmentAccount(ref.read(supabaseClientProvider));
    } catch (_) {
      if (mounted) {
        AppToast.show(
          ref.read(appStringsProvider).authDevelopmentLoginError,
          tone: ToastTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _developmentLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      AppToast.show(strings.authFieldRequired, tone: ToastTone.error);
      return;
    }

    final failure = await ref
        .read(loginControllerProvider.notifier)
        .submit(email: email, password: password);

    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading || _developmentLoading;

    return AuthBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: LiquidGlass(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandMark(size: 88)),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    strings.authWelcomeTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    strings.authWelcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  if (developmentLoginEnabled) ...[
                    AppButton(
                      label: strings.authDevelopmentLogin,
                      onPressed: isLoading ? null : _developmentLogin,
                      loading: _developmentLoading,
                      icon: LucideIcons.code,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  AppTextField(
                    label: strings.authEmail,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: LucideIcons.user,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: strings.authPassword,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: LucideIcons.lock,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(RoutePaths.forgotPassword),
                      child: Text(strings.authForgotPassword),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: strings.authLoginButton,
                    onPressed: isLoading ? null : _submit,
                    loading: isLoading,
                    icon: LucideIcons.logIn,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextButton(
                    onPressed: () => context.push(RoutePaths.register),
                    child: Text(strings.authNoAccountLink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
