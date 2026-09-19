import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../providers/issue_cart_provider.dart';
import '../providers/warehouse_providers.dart';

/// Requirement: "Себетке шығару" — reviews the pending cart and
/// submits it atomically via `issue_materials()`.
class IssueCartSheet extends ConsumerStatefulWidget {
  const IssueCartSheet({super.key});

  static Future<void> open(BuildContext context) {
    return showAppBottomSheet(context: context, child: const IssueCartSheet());
  }

  @override
  ConsumerState<IssueCartSheet> createState() => _IssueCartSheetState();
}

class _IssueCartSheetState extends ConsumerState<IssueCartSheet> {
  bool _saving = false;

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    final items = ref.read(issueCartProvider);
    if (items.isEmpty) return;

    setState(() => _saving = true);
    final result = await ref
        .read(issueMaterialsUseCaseProvider)
        .call(items: items);
    if (!mounted) return;
    setState(() => _saving = false);
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.warehouseIssuedToast, tone: ToastTone.success);
        ref.read(issueCartProvider.notifier).clear();
        ref.invalidate(materialsListProvider);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;
    final items = ref.watch(issueCartProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(strings.warehouseCartTitle, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              strings.warehouseCartEmpty,
              style: textTheme.bodyMedium,
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.materialName, style: textTheme.bodyLarge),
                          Text(
                            '${item.locationName} · ${item.quantity} ${item.unit}',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      color: AppColors.danger,
                      onPressed: () =>
                          ref.read(issueCartProvider.notifier).remove(item),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: strings.warehouseIssueConfirmAction,
          icon: LucideIcons.truck,
          loading: _saving,
          onPressed: items.isEmpty ? null : _submit,
        ),
      ],
    );
  }
}
