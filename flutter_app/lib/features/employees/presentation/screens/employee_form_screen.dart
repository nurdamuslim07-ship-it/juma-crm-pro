import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/theme/form_style.dart';
import '../../../../core/widgets/press_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/employee_validation.dart';
import '../../domain/entities/employee.dart';
import '../../domain/value_objects/employee_role.dart';
import '../../domain/value_objects/salary_type.dart';
import '../providers/employee_providers.dart';
import '../widgets/employee_role_picker_sheet.dart';
import '../widgets/employee_role_x.dart';
import '../widgets/salary_type_picker_sheet.dart';
import '../widgets/salary_type_x.dart';

/// Director-only (requirement: "Қызметкер қосу, өңдеу және өшіру тек
/// директорға рұқсат") — this screen is only ever pushed from
/// EmployeesListScreen's FAB or EmployeeDetailScreen's edit button,
/// both of which already gate on `currentUser.isDirector`; the real
/// enforcement is server-side (create-employee Edge Function checks
/// auth_is_director(), update_employee() RPC does too).
class EmployeeFormScreen extends ConsumerStatefulWidget {
  const EmployeeFormScreen({super.key, this.existing});

  final Employee? existing;

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  late final _fullName = TextEditingController(text: widget.existing?.fullName);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _email = TextEditingController(text: widget.existing?.email);
  final _password = TextEditingController();
  late final _baseSalary = TextEditingController(
    text: widget.existing?.baseSalaryTiyn != null
        ? (widget.existing!.baseSalaryTiyn! / 100).toStringAsFixed(0)
        : '0',
  );
  late final _bonusPercent = TextEditingController(
    text: widget.existing?.bonusPercent?.toStringAsFixed(0) ?? '0',
  );
  late final _notes = TextEditingController(text: widget.existing?.notes);

  EmployeeRole _role = EmployeeRole.master;
  SalaryType _salaryType = SalaryType.fixed;
  DateTime? _hireDate;
  bool _saving = false;

  String? _fullNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _bonusError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _role = existing.role ?? EmployeeRole.master;
      _salaryType = existing.salaryType ?? SalaryType.fixed;
      _hireDate = existing.hireDate;
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _baseSalary.dispose();
    _bonusPercent.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickRole() async {
    final picked = await EmployeeRolePickerSheet.open(context, current: _role);
    if (picked != null) setState(() => _role = picked);
  }

  Future<void> _pickSalaryType() async {
    final picked = await SalaryTypePickerSheet.open(
      context,
      current: _salaryType,
    );
    if (picked != null) setState(() => _salaryType = picked);
  }

  Future<void> _pickHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 20),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _hireDate = picked);
  }

  bool _validate() {
    final strings = ref.read(appStringsProvider);
    final isNew = widget.existing == null;

    setState(() {
      _fullNameError = validateFullName(_fullName.text);
      _emailError = isNew ? validateEmail(_email.text) : null;
      _phoneError = validatePhone(_phone.text);
      _passwordError = isNew ? validatePassword(_password.text) : null;
      final bonus = double.tryParse(_bonusPercent.text) ?? -1;
      _bonusError = validateBonusPercent(bonus);
    });

    if ([
      _fullNameError,
      _emailError,
      _phoneError,
      _passwordError,
      _bonusError,
    ].any((e) => e != null)) {
      AppToast.show(strings.authFieldRequired, tone: ToastTone.error);
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final strings = ref.read(appStringsProvider);
    final isNew = widget.existing == null;

    setState(() => _saving = true);

    final baseSalaryTiyn = ((num.tryParse(_baseSalary.text) ?? 0) * 100)
        .round();
    final bonusPercent = double.tryParse(_bonusPercent.text) ?? 0;

    if (isNew) {
      final result = await ref
          .read(createEmployeeUseCaseProvider)
          .call(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _fullName.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            role: _role,
            hireDate: _hireDate,
            salaryType: _salaryType,
            baseSalaryTiyn: baseSalaryTiyn,
            bonusPercent: bonusPercent,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );

      if (!mounted) return;
      setState(() => _saving = false);

      result.match(
        (failure) => AppToast.show(failure.message, tone: ToastTone.error),
        (_) {
          AppToast.show(strings.employeeCreatedToast, tone: ToastTone.success);
          context.pop(true);
        },
      );
    } else {
      final result = await ref
          .read(updateEmployeeUseCaseProvider)
          .call(
            userId: widget.existing!.userId,
            fullName: _fullName.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            role: _role,
            hireDate: _hireDate,
            salaryType: _salaryType,
            baseSalaryTiyn: baseSalaryTiyn,
            bonusPercent: bonusPercent,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );

      if (!mounted) return;
      setState(() => _saving = false);

      result.match(
        (failure) => AppToast.show(failure.message, tone: ToastTone.error),
        (_) {
          AppToast.show(strings.employeeUpdatedToast, tone: ToastTone.success);
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
        title: Text(
          isNew ? strings.employeeNewTitle : strings.employeeEditTitle,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppTextField(
                label: strings.employeeFormFullNameLabel,
                controller: _fullName,
                prefixIcon: LucideIcons.user,
                errorText: _fullNameError,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.employeeFormEmailLabel,
                controller: _email,
                prefixIcon: LucideIcons.mail,
                errorText: _emailError,
                enabled: isNew,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              if (isNew) ...[
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: strings.employeeFormPasswordLabel,
                  controller: _password,
                  prefixIcon: LucideIcons.lock,
                  errorText: _passwordError,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.employeeFormPhoneLabel,
                controller: _phone,
                prefixIcon: LucideIcons.phone,
                errorText: _phoneError,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.employeeFormRoleLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _PickerField(
                icon: _role.icon,
                label: _role.label(strings),
                onTap: _pickRole,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.employeeFormHireDateLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _PickerField(
                icon: LucideIcons.calendarDays,
                label: _hireDate != null
                    ? AppFormatters.date(_hireDate!)
                    : strings.employeeSelectDateTitle,
                onTap: _pickHireDate,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.employeeFormSalaryTypeLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _PickerField(
                icon: LucideIcons.wallet,
                label: _salaryType.label(strings),
                onTap: _pickSalaryType,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.employeeFormBaseSalaryLabel,
                controller: _baseSalary,
                prefixIcon: LucideIcons.banknote,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.employeeFormBonusPercentLabel,
                controller: _bonusPercent,
                prefixIcon: LucideIcons.percent,
                errorText: _bonusError,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.employeeFormNotesLabel,
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
