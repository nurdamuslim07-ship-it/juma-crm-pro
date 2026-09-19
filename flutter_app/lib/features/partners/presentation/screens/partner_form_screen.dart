import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/theme/form_style.dart';
import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/partner.dart';
import '../../domain/partner_validation.dart';
import '../../domain/value_objects/partner_category.dart';
import '../providers/partner_providers.dart';
import '../widgets/partner_category_picker_sheet.dart';
import '../widgets/partner_category_x.dart';
import '../widgets/partner_trust_rating_picker_sheet.dart';

/// director/manager/purchaser only (`partners.write`) — this screen is
/// only ever pushed from PartnersListScreen's FAB or
/// PartnerDetailScreen's edit button, both of which already gate on
/// `currentUser.canWritePartners`; the real enforcement is server-side
/// (`create_partner()`/`update_partner()` RPCs check `partners.write`).
class PartnerFormScreen extends ConsumerStatefulWidget {
  const PartnerFormScreen({super.key, this.existing});

  final Partner? existing;

  @override
  ConsumerState<PartnerFormScreen> createState() => _PartnerFormScreenState();
}

class _PartnerFormScreenState extends ConsumerState<PartnerFormScreen> {
  late final _displayName = TextEditingController(
    text: widget.existing?.displayName,
  );
  late final _companyName = TextEditingController(
    text: widget.existing?.companyName,
  );
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _phoneSecondary = TextEditingController(
    text: widget.existing?.phoneSecondary,
  );
  late final _whatsapp = TextEditingController(
    text: widget.existing?.whatsappPhone,
  );
  late final _address = TextEditingController(text: widget.existing?.address);
  late final _city = TextEditingController(text: widget.existing?.city);
  late final _contactPerson = TextEditingController(
    text: widget.existing?.contactPerson,
  );
  late final _taxId = TextEditingController(text: widget.existing?.taxId);
  late final _serviceDescription = TextEditingController(
    text: widget.existing?.serviceDescription,
  );
  late final _priceNote = TextEditingController(
    text: widget.existing?.priceNote,
  );
  late final _notes = TextEditingController(text: widget.existing?.notes);

  PartnerCategory _category = PartnerCategory.other;
  int? _trustRating;
  bool _isActive = true;
  bool _saving = false;

  String? _displayNameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _category = existing.category;
      _trustRating = existing.trustRating;
      _isActive = existing.isActive;
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _companyName.dispose();
    _phone.dispose();
    _phoneSecondary.dispose();
    _whatsapp.dispose();
    _address.dispose();
    _city.dispose();
    _contactPerson.dispose();
    _taxId.dispose();
    _serviceDescription.dispose();
    _priceNote.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final result = await PartnerCategoryPickerSheet.open(
      context,
      current: _category,
      allowAll: false,
    );
    final unwrapped = unwrapPickedCategory(result);
    if (unwrapped.picked && unwrapped.value != null) {
      setState(() => _category = unwrapped.value!);
    }
  }

  Future<void> _pickTrustRating() async {
    final result = await PartnerTrustRatingPickerSheet.open(
      context,
      current: _trustRating,
    );
    final unwrapped = unwrapPickedRating(result);
    if (unwrapped.picked) setState(() => _trustRating = unwrapped.value);
  }

  bool _validate() {
    final strings = ref.read(appStringsProvider);
    setState(() {
      _displayNameError = validateDisplayName(_displayName.text);
      _phoneError = validatePartnerPhone(_phone.text);
    });
    if ([_displayNameError, _phoneError].any((e) => e != null)) {
      AppToast.show(strings.authFieldRequired, tone: ToastTone.error);
      return false;
    }
    return true;
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  Future<void> _save() async {
    if (!_validate()) return;
    final strings = ref.read(appStringsProvider);
    final isNew = widget.existing == null;

    setState(() => _saving = true);

    if (isNew) {
      final result = await ref
          .read(createPartnerUseCaseProvider)
          .call(
            displayName: _displayName.text.trim(),
            category: _category,
            companyName: _emptyToNull(_companyName.text),
            phone: _emptyToNull(_phone.text),
            phoneSecondary: _emptyToNull(_phoneSecondary.text),
            whatsappPhone: _emptyToNull(_whatsapp.text),
            address: _emptyToNull(_address.text),
            city: _emptyToNull(_city.text),
            contactPerson: _emptyToNull(_contactPerson.text),
            taxId: _emptyToNull(_taxId.text),
            serviceDescription: _emptyToNull(_serviceDescription.text),
            priceNote: _emptyToNull(_priceNote.text),
            trustRating: _trustRating,
            notes: _emptyToNull(_notes.text),
          );

      if (!mounted) return;
      setState(() => _saving = false);

      result.match(
        (failure) => AppToast.show(failure.message, tone: ToastTone.error),
        (_) {
          AppToast.show(strings.partnerCreatedToast, tone: ToastTone.success);
          context.pop(true);
        },
      );
    } else {
      final result = await ref
          .read(updatePartnerUseCaseProvider)
          .call(
            id: widget.existing!.id,
            displayName: _displayName.text.trim(),
            category: _category,
            companyName: _emptyToNull(_companyName.text),
            phone: _emptyToNull(_phone.text),
            phoneSecondary: _emptyToNull(_phoneSecondary.text),
            whatsappPhone: _emptyToNull(_whatsapp.text),
            address: _emptyToNull(_address.text),
            city: _emptyToNull(_city.text),
            contactPerson: _emptyToNull(_contactPerson.text),
            taxId: _emptyToNull(_taxId.text),
            serviceDescription: _emptyToNull(_serviceDescription.text),
            priceNote: _emptyToNull(_priceNote.text),
            trustRating: _trustRating,
            notes: _emptyToNull(_notes.text),
            isActive: _isActive,
          );

      if (!mounted) return;
      setState(() => _saving = false);

      result.match(
        (failure) => AppToast.show(failure.message, tone: ToastTone.error),
        (_) {
          AppToast.show(strings.partnerUpdatedToast, tone: ToastTone.success);
          context.pop(true);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final isNew = widget.existing == null;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(isNew ? strings.partnerNewTitle : strings.partnerEditTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppTextField(
                label: strings.partnerFormDisplayNameLabel,
                controller: _displayName,
                prefixIcon: LucideIcons.user,
                errorText: _displayNameError,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.partnerFormCompanyNameLabel,
                controller: _companyName,
                prefixIcon: LucideIcons.building2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.partnerFormCategoryLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _PickerField(
                icon: _category.icon,
                label: _category.label(strings),
                onTap: _pickCategory,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.partnerFormPhoneLabel,
                controller: _phone,
                prefixIcon: LucideIcons.phone,
                errorText: _phoneError,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.partnerFormPhoneSecondaryLabel,
                controller: _phoneSecondary,
                prefixIcon: LucideIcons.phoneForwarded,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.partnerFormWhatsappLabel,
                controller: _whatsapp,
                prefixIcon: LucideIcons.messageCircle,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.partnerFormCityLabel,
                controller: _city,
                prefixIcon: LucideIcons.building,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.partnerFormAddressLabel,
                controller: _address,
                prefixIcon: LucideIcons.mapPin,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.partnerFormContactPersonLabel,
                controller: _contactPerson,
                prefixIcon: LucideIcons.userCircle,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.partnerFormTaxIdLabel,
                controller: _taxId,
                prefixIcon: LucideIcons.badge,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.partnerFormServiceDescriptionLabel,
                controller: _serviceDescription,
                prefixIcon: LucideIcons.package,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.partnerFormPriceNoteLabel,
                controller: _priceNote,
                prefixIcon: LucideIcons.tag,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.partnerFormTrustRatingLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _PickerField(
                icon: LucideIcons.star,
                label: _trustRating != null
                    ? '$_trustRating/5'
                    : strings.partnerTrustRatingUnset,
                onTap: _pickTrustRating,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.partnerFormNotesLabel,
                controller: _notes,
                prefixIcon: LucideIcons.stickyNote,
                textInputAction: TextInputAction.done,
              ),
              if (!isNew) ...[
                const SizedBox(height: AppSpacing.lg),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  title: Text(strings.partnerFormStatusLabel),
                  subtitle: Text(
                    _isActive
                        ? strings.partnerFilterActive
                        : strings.partnerFilterInactive,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: strings.commonSave,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MotionInkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: FormStyle.picker(context),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            const Icon(LucideIcons.chevronRight, size: 18),
          ],
        ),
      ),
    );
  }
}
