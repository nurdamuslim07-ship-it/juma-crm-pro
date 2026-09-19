import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../providers/partner_providers.dart';

/// Requirement #13 "Прайс немесе құжат тіркеу" — only rendered by the
/// caller when [Partner.hasExtendedAccess] is true (see
/// partner_detail_screen.dart), matching `get_partner_documents()`'s
/// own `partners.read_extended`/`partners.read_financial` gate.
class PartnerDocumentList extends ConsumerWidget {
  const PartnerDocumentList({
    super.key,
    required this.partnerId,
    required this.canWrite,
  });

  final String partnerId;
  final bool canWrite;

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final picked = await FilePicker.platform.pickFiles(withData: true);
    final file = picked?.files.firstOrNull;
    if (file?.bytes == null) return;

    final result = await ref
        .read(addPartnerDocumentUseCaseProvider)
        .call(partnerId: partnerId, bytes: file!.bytes!, fileName: file.name);

    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.partnerDocumentAddedToast,
          tone: ToastTone.success,
        );
        ref.invalidate(partnerDocumentsProvider(partnerId));
      },
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, String path) async {
    final strings = ref.read(appStringsProvider);
    final result = await ref
        .read(partnerRepositoryProvider)
        .getDocumentSignedUrl(path);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (url) async {
        final uri = Uri.parse(url);
        final ok =
            await canLaunchUrl(uri) &&
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) {
          AppToast.show(strings.commonCannotOpenLink, tone: ToastTone.error);
        }
      },
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String documentId,
  ) async {
    final strings = ref.read(appStringsProvider);
    final result = await ref
        .read(deletePartnerDocumentUseCaseProvider)
        .call(documentId);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.partnerDocumentDeletedToast,
          tone: ToastTone.success,
        );
        ref.invalidate(partnerDocumentsProvider(partnerId));
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final documentsAsync = ref.watch(partnerDocumentsProvider(partnerId));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.partnerDocumentsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (canWrite)
                IconButton(
                  icon: const Icon(LucideIcons.paperclip, size: 20),
                  tooltip: strings.partnerAddDocumentAction,
                  onPressed: () => _upload(context, ref),
                ),
            ],
          ),
          documentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: LinearProgressIndicator(),
            ),
            error: (error, _) => Text(
              strings.partnerDocumentsLoadError,
              style: const TextStyle(color: AppColors.danger),
            ),
            data: (documents) {
              if (documents.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    strings.partnerDocumentsEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return Column(
                children: [
                  for (final document in documents)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(LucideIcons.fileText, size: 20),
                      title: Text(
                        document.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _open(context, ref, document.storagePath),
                      trailing: canWrite
                          ? IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 18),
                              onPressed: () =>
                                  _delete(context, ref, document.id),
                            )
                          : null,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
