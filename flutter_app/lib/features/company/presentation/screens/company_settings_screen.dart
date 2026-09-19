import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/company_settings.dart';
import '../providers/company_providers.dart';

/// Director/owner-only edit of the company's settings fields — see
/// `update_company_settings()` in
/// supabase/migrations/20260713000038_company_settings_subscription.sql.
/// Any active member can still VIEW this screen (read-only for
/// non-directors), matching how the rest of the app treats "hiding a
/// button is UX only" — the RPC itself is the real gate.
class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() =>
      _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final _nameController = TextEditingController();
  final _logoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _iinBinController = TextEditingController();
  final _websiteController = TextEditingController();
  final _timezoneController = TextEditingController();
  final _currencyController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _loadedOnce = false;

  @override
  void dispose() {
    _nameController.dispose();
    _logoController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _iinBinController.dispose();
    _websiteController.dispose();
    _timezoneController.dispose();
    _currencyController.dispose();
    _workingHoursController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _fillFrom(CompanySettings settings) {
    if (_loadedOnce) return;
    _loadedOnce = true;
    _nameController.text = settings.name;
    _logoController.text = settings.logo ?? '';
    _phoneController.text = settings.phone ?? '';
    _emailController.text = settings.email ?? '';
    _addressController.text = settings.address ?? '';
    _iinBinController.text = settings.iinBin ?? '';
    _websiteController.text = settings.website ?? '';
    _timezoneController.text = settings.timezone;
    _currencyController.text = settings.currency;
    _workingHoursController.text = settings.workingHours ?? '';
    _descriptionController.text = settings.description ?? '';
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

    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    final failure = await ref
        .read(updateCompanySettingsControllerProvider.notifier)
        .submit(
          name: name,
          logo: orNull(_logoController),
          phone: orNull(_phoneController),
          email: orNull(_emailController),
          address: orNull(_addressController),
          iinBin: orNull(_iinBinController),
          website: orNull(_websiteController),
          timezone: orNull(_timezoneController),
          currency: orNull(_currencyController),
          workingHours: orNull(_workingHoursController),
          description: orNull(_descriptionController),
        );

    if (!mounted) return;
    if (failure != null) {
      AppToast.show(failure.message, tone: ToastTone.error);
      return;
    }
    AppToast.show(strings.companySettingsSavedToast, tone: ToastTone.success);
    ref.invalidate(companySettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final settingsAsync = ref.watch(companySettingsProvider);
    final updateState = ref.watch(updateCompanySettingsControllerProvider);
    final isDirector = ref.watch(currentUserProvider)?.isDirector ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.companySettingsTitle),
      ),
      body: settingsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: strings.commonError,
          retryLabel: strings.commonRetry,
          onRetry: () => ref.invalidate(companySettingsProvider),
        ),
        data: (settings) {
          _fillFrom(settings);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: strings.createCompanyNameLabel,
                    controller: _nameController,
                    enabled: isDirector,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: strings.companySettingsLogoLabel,
                    controller: _logoController,
                    enabled: isDirector,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: strings.createCompanyIinBinLabel,
                    controller: _iinBinController,
                    enabled: isDirector,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: strings.createCompanyPhoneLabel,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: isDirector,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: strings.createCompanyEmailLabel,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: isDirector,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: strings.createCompanyAddressLabel,
                    controller: _addressController,
                    enabled: isDirector,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: strings.companySettingsWebsiteLabel,
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                    enabled: isDirector,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: strings.companySettingsTimezoneLabel,
                    controller: _timezoneController,
                    enabled: isDirector,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: strings.companySettingsCurrencyLabel,
                    controller: _currencyController,
                    enabled: isDirector,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: strings.companySettingsWorkingHoursLabel,
                    controller: _workingHoursController,
                    enabled: isDirector,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: strings.companySettingsDescriptionLabel,
                    controller: _descriptionController,
                    enabled: isDirector,
                  ),
                  if (isDirector) ...[
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: strings.commonSave,
                      loading: updateState.isLoading,
                      onPressed: updateState.isLoading ? null : _submit,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
