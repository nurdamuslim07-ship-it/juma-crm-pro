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
import '../providers/company_providers.dart';

/// `create_company_and_owner()` — the caller becomes `owner`, active
/// immediately, no approval step (see
/// supabase/migrations/20260713000036_company_registration_module.sql).
class CreateCompanyScreen extends ConsumerStatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  ConsumerState<CreateCompanyScreen> createState() =>
      _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends ConsumerState<CreateCompanyScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _iinBinController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _iinBinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.show(
        strings.createCompanyNameRequiredError,
        tone: ToastTone.error,
      );
      return;
    }

    final failure = await ref
        .read(createCompanyControllerProvider.notifier)
        .submit(
          name: name,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          iinBin: _iinBinController.text.trim().isEmpty
              ? null
              : _iinBinController.text.trim(),
        );

    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
      return;
    }
    AppToast.show(strings.createCompanySuccessToast, tone: ToastTone.success);
    context.go(RoutePaths.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final state = ref.watch(createCompanyControllerProvider);
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
                          strings.createCompanyTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppTextField(
                          label: strings.createCompanyNameLabel,
                          controller: _nameController,
                          prefixIcon: LucideIcons.building2,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: strings.createCompanyPhoneLabel,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: LucideIcons.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: strings.createCompanyEmailLabel,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: LucideIcons.mail,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: strings.createCompanyCityLabel,
                          controller: _cityController,
                          prefixIcon: LucideIcons.mapPin,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: strings.createCompanyAddressLabel,
                          controller: _addressController,
                          prefixIcon: LucideIcons.map,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: strings.createCompanyIinBinLabel,
                          controller: _iinBinController,
                          keyboardType: TextInputType.number,
                          prefixIcon: LucideIcons.hash,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: strings.createCompanySubmitButton,
                          onPressed: isLoading ? null : _submit,
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
}
