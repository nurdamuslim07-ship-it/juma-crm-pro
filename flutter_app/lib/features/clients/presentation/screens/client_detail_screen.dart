import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/launchers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/client.dart';
import '../providers/client_providers.dart';
import '../widgets/client_form_sheet.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final clientAsync = ref.watch(clientDetailProvider(clientId));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navClients),
      ),
      body: clientAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: strings.clientNotFound,
          retryLabel: strings.commonRetry,
          onRetry: () => ref.invalidate(clientDetailProvider(clientId)),
        ),
        data: (client) => _ClientDetailBody(client: client),
      ),
    );
  }
}

class _ClientDetailBody extends ConsumerWidget {
  const _ClientDetailBody({required this.client});
  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.skyDeep.withValues(alpha: 0.15),
                    child: Text(
                      client.name.isNotEmpty
                          ? client.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.skyDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(client.name, style: textTheme.titleLarge),
                        Text(client.phone, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth < 460
                      ? constraints.maxWidth
                      : (constraints.maxWidth - AppSpacing.md) / 2;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: width,
                        child: AppButton(
                          label: strings.clientCallAction,
                          icon: LucideIcons.phone,
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            final ok = await AppLaunchers.call(client.phone);
                            if (!ok && context.mounted) {
                              AppToast.show(
                                strings.commonCannotOpenLink,
                                tone: ToastTone.error,
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: AppButton(
                          label: strings.clientWhatsappAction,
                          icon: LucideIcons.messageCircle,
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            final ok = await AppLaunchers.whatsapp(
                              client.whatsappOrTelegram ?? client.phone,
                            );
                            if (!ok && context.mounted) {
                              AppToast.show(
                                strings.commonCannotOpenLink,
                                tone: ToastTone.error,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: LucideIcons.building2,
                label: strings.clientFormCityLabel,
                value: client.city,
              ),
              _InfoRow(
                icon: LucideIcons.mapPin,
                label: strings.clientFormAddressLabel,
                value: client.address,
              ),
              _InfoRow(
                icon: LucideIcons.tag,
                label: strings.clientFormSourceLabel,
                value: client.source,
              ),
              _InfoRow(
                icon: LucideIcons.userCog,
                label: strings.clientFormResponsibleManagerLabel,
                value:
                    client.responsibleManagerName ??
                    strings.clientResponsibleManagerNone,
              ),
              _InfoRow(
                icon: LucideIcons.stickyNote,
                label: strings.clientFormNotesLabel,
                value: client.notes ?? strings.clientNoNotes,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: strings.commonEdit,
          icon: LucideIcons.pencil,
          variant: AppButtonVariant.secondary,
          onPressed: () async {
            final updated = await ClientFormSheet.open(
              context,
              existing: client,
            );
            if (updated == true) {
              ref.invalidate(clientDetailProvider(client.id));
              ref.invalidate(clientsListProvider);
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: strings.commonDelete,
          icon: LucideIcons.trash2,
          variant: AppButtonVariant.destructive,
          onPressed: () => _confirmDelete(context, ref, client, strings),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Client client,
    dynamic strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.clientDeleteConfirmTitle),
        content: Text(strings.clientDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              strings.commonDelete,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(deleteClientUseCaseProvider).call(client.id);
    if (!context.mounted) return;

    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(strings.clientDeletedToast, tone: ToastTone.success);
        ref.invalidate(clientsListProvider);
        context.pop();
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondaryLight),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall),
                Text(
                  value?.isNotEmpty == true ? value! : '—',
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
