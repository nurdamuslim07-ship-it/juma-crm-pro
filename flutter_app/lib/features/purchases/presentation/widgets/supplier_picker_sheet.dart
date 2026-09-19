import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../partners/domain/entities/partner.dart';
import '../../../partners/presentation/providers/partner_providers.dart';

/// Requirement: "Supplier Picker" — a local, one-off fetch via
/// [getPartnersUseCaseProvider] rather than the shared
/// `partnersListProvider` state notifier, so opening this sheet from a
/// PO form never mutates the Partners screen's own filter/pagination
/// state.
class SupplierPickerSheet extends ConsumerStatefulWidget {
  const SupplierPickerSheet({super.key, this.currentPartnerId});

  final String? currentPartnerId;

  static Future<Partner?> open(
    BuildContext context, {
    String? currentPartnerId,
  }) {
    return showAppBottomSheet<Partner>(
      context: context,
      child: SupplierPickerSheet(currentPartnerId: currentPartnerId),
    );
  }

  @override
  ConsumerState<SupplierPickerSheet> createState() =>
      _SupplierPickerSheetState();
}

class _SupplierPickerSheetState extends ConsumerState<SupplierPickerSheet> {
  final _searchController = TextEditingController();
  late Future<List<Partner>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Partner>> _load() {
    return ref
        .read(getPartnersUseCaseProvider)
        .call(searchQuery: _searchController.text)
        .then((either) => either.match((failure) => throw failure, (d) => d));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.purchasesSelectSupplierTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: strings.commonSearch,
          controller: _searchController,
          prefixIcon: LucideIcons.search,
          onSubmitted: (_) => setState(() => _future = _load()),
        ),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<List<Partner>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: LoadingView(),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(strings.purchasesSuppliersLoadError),
              );
            }
            final partners = snapshot.data ?? const [];
            if (partners.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(strings.purchasesNoSuppliersAvailable),
              );
            }
            return Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final partner in partners)
                    ListTile(
                      onTap: () => Navigator.of(context).pop(partner),
                      leading: const Icon(LucideIcons.building2),
                      trailing: partner.id == widget.currentPartnerId
                          ? const Icon(LucideIcons.check, size: 18)
                          : null,
                      title: Text(
                        partner.displayName,
                        style: TextStyle(
                          fontWeight: partner.id == widget.currentPartnerId
                              ? FontWeight.w700
                              : null,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
