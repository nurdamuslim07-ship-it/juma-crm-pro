import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/production_photo.dart';
import '../providers/production_providers.dart';

/// Requirement #2 "Фото тіркеу" — thumbnails from the `order_photos`
/// table (`kind = 'production'`), viewed via a signed URL from the
/// private `order-photos` Storage bucket.
class ProductionPhotoGallery extends ConsumerWidget {
  const ProductionPhotoGallery({
    super.key,
    required this.orderId,
    required this.photos,
    required this.canWrite,
  });

  final String orderId;
  final List<ProductionPhoto> photos;
  final bool canWrite;

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    final companyId = ref.read(currentUserProvider)?.companyId;
    if (companyId == null) {
      AppToast.show(strings.clientCompanyMissingError, tone: ToastTone.error);
      return;
    }

    final bytes = await file.readAsBytes();
    final result = await ref
        .read(addProductionPhotoUseCaseProvider)
        .call(
          orderId: orderId,
          bytes: bytes,
          fileName: file.name,
          companyId: companyId,
        );

    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.productionPhotoAddedToast,
          tone: ToastTone.success,
        );
        ref.invalidate(productionOrderDetailProvider(orderId));
      },
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    ProductionPhoto photo,
  ) async {
    final strings = ref.read(appStringsProvider);
    final result = await ref
        .read(productionRepositoryProvider)
        .getPhotoSignedUrl(photo.storagePath);
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
    ProductionPhoto photo,
  ) async {
    final strings = ref.read(appStringsProvider);
    final result = await ref
        .read(deleteProductionPhotoUseCaseProvider)
        .call(photo.id);
    if (!context.mounted) return;
    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.productionPhotoDeletedToast,
          tone: ToastTone.success,
        );
        ref.invalidate(productionOrderDetailProvider(orderId));
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.productionPhotosTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (canWrite)
                IconButton(
                  icon: const Icon(LucideIcons.camera, size: 20),
                  tooltip: strings.productionAddPhotoAction,
                  onPressed: () => _upload(context, ref),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (photos.isEmpty)
            Text(
              strings.productionNoPhotos,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return MotionInkWell(
                  onTap: () => _open(context, ref, photo),
                  onLongPress: canWrite
                      ? () => _delete(context, ref, photo)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black12,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.image, size: 28),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
