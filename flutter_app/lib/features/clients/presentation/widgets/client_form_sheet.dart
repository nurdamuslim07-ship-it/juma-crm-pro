import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/client.dart';
import '../providers/client_providers.dart';

/// Create/edit form — a bottom sheet on every breakpoint (per
/// COMPONENT_LIBRARY.md's `<BottomSheet>`, reused rather than a
/// separate full-screen route, matching the master spec's mobile-first
/// "Жаңа клиент" quick-add flow).
class ClientFormSheet extends ConsumerStatefulWidget {
  const ClientFormSheet({super.key, this.existing});

  final Client? existing;

  static Future<bool?> open(BuildContext context, {Client? existing}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClientFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends ConsumerState<ClientFormSheet> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _phoneSecondary = TextEditingController(
    text: widget.existing?.phoneSecondary,
  );
  late final _whatsapp = TextEditingController(
    text: widget.existing?.whatsappOrTelegram,
  );
  late final _address = TextEditingController(text: widget.existing?.address);
  late final _city = TextEditingController(text: widget.existing?.city);
  late final _source = TextEditingController(text: widget.existing?.source);
  late final _notes = TextEditingController(text: widget.existing?.notes);

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _phoneSecondary,
      _whatsapp,
      _address,
      _city,
      _source,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final strings = ref.read(appStringsProvider);
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      AppToast.show(strings.authFieldRequired, tone: ToastTone.error);
      return;
    }

    final isNew = widget.existing == null;

    // The authenticated user's own active company — never a literal,
    // never a value the caller can override. Required (not just
    // preferred) for a create: if it isn't loaded, refuse outright
    // rather than let the datasource send a null/omitted company_id.
    final companyId = ref.read(currentUserProvider)?.companyId;
    if (isNew && companyId == null) {
      AppToast.show(strings.clientCompanyMissingError, tone: ToastTone.error);
      return;
    }

    setState(() => _saving = true);

    final client = Client(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      phoneSecondary: _emptyToNull(_phoneSecondary.text),
      whatsappOrTelegram: _emptyToNull(_whatsapp.text),
      address: _emptyToNull(_address.text),
      city: _emptyToNull(_city.text),
      source: _emptyToNull(_source.text),
      notes: _emptyToNull(_notes.text),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    final result = await ref
        .read(upsertClientUseCaseProvider)
        .call(client, isNew: isNew, companyId: companyId);

    if (!mounted) return;
    setState(() => _saving = false);

    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          isNew ? strings.clientCreatedToast : strings.clientUpdatedToast,
          tone: ToastTone.success,
        );
        Navigator.of(context).pop(true);
      },
    );
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final isNew = widget.existing == null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  isNew ? strings.clientNewTitle : strings.clientEditTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: strings.clientFormNameLabel,
                  controller: _name,
                  prefixIcon: LucideIcons.user,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: strings.clientFormPhoneLabel,
                  controller: _phone,
                  prefixIcon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: strings.clientFormPhoneSecondaryLabel,
                  controller: _phoneSecondary,
                  prefixIcon: LucideIcons.phoneCall,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: strings.clientFormWhatsappLabel,
                  controller: _whatsapp,
                  prefixIcon: LucideIcons.messageCircle,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: strings.clientFormCityLabel,
                  controller: _city,
                  prefixIcon: LucideIcons.building2,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: strings.clientFormAddressLabel,
                  controller: _address,
                  prefixIcon: LucideIcons.mapPin,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: strings.clientFormSourceLabel,
                  controller: _source,
                  prefixIcon: LucideIcons.tag,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: strings.clientFormNotesLabel,
                  controller: _notes,
                  prefixIcon: LucideIcons.stickyNote,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: strings.commonSave,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
