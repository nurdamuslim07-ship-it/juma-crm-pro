import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/employee_validation.dart';
import '../../domain/entities/employee.dart';
import '../providers/employee_providers.dart';
import 'employee_avatar.dart';

/// Requirement: "Қолданушы өз профилінің телефон нөмірі мен аватарын
/// ғана өзгерте алады" — the ONLY self-service edit surface in this
/// module. Deliberately has no full_name/role/salary fields: the
/// server-side `restrict_profile_self_update` trigger would reject
/// full_name/is_active changes anyway, but this form doesn't even
/// offer them, so there's nothing to fail silently.
class SelfProfileEditSheet extends ConsumerStatefulWidget {
  const SelfProfileEditSheet({super.key, required this.employee});

  final Employee employee;

  static Future<bool?> open(
    BuildContext context, {
    required Employee employee,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SelfProfileEditSheet(employee: employee),
        ),
      ),
    );
  }

  @override
  ConsumerState<SelfProfileEditSheet> createState() =>
      _SelfProfileEditSheetState();
}

class _SelfProfileEditSheetState extends ConsumerState<SelfProfileEditSheet> {
  late final _phone = TextEditingController(text: widget.employee.phone);
  String? _avatarUrl;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.employee.avatarUrl;
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    setState(() => _uploadingAvatar = true);
    final bytes = await file.readAsBytes();
    final result = await ref
        .read(uploadAvatarUseCaseProvider)
        .call(
          userId: widget.employee.userId,
          bytes: bytes,
          fileName: file.name,
        );

    if (!mounted) return;
    setState(() => _uploadingAvatar = false);

    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (url) {
        setState(() => _avatarUrl = url);
      },
    );
  }

  Future<void> _save() async {
    final strings = ref.read(appStringsProvider);
    final phoneError = validatePhone(_phone.text);
    setState(() => _phoneError = phoneError);
    if (phoneError != null) return;

    setState(() => _saving = true);
    final result = await ref
        .read(updateOwnContactInfoUseCaseProvider)
        .call(
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          avatarUrl: _avatarUrl,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          strings.employeeAvatarUpdatedToast,
          tone: ToastTone.success,
        );
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.employeeMyProfileTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Stack(
            children: [
              EmployeeAvatar(
                avatarUrl: _avatarUrl,
                fullName: widget.employee.fullName,
                radius: 40,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: MotionInkWell(
                  onTap: _uploadingAvatar ? null : _pickAvatar,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: _uploadingAvatar
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            LucideIcons.camera,
                            size: 14,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: strings.employeeFormPhoneLabel,
          controller: _phone,
          prefixIcon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
          errorText: _phoneError,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: strings.commonSave,
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
