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
import '../../domain/entities/customer_order.dart';
import '../../domain/value_objects/order_status.dart';
import '../providers/order_providers.dart';
import '../widgets/order_client_picker_sheet.dart';
import '../widgets/order_employee_picker_sheet.dart';

/// Requirements #4/#5 ("Жаңа тапсырыс қосу" / "Тапсырысты өңдеу") — one
/// screen for both, matching [ClientFormSheet]'s create/edit-in-one
/// pattern. A full page rather than a bottom sheet (unlike
/// ClientFormSheet) because this form has meaningfully more fields —
/// consistent with RESPONSIVE_LAYOUT.md giving complex forms their own
/// route rather than cramming them into a sheet on every breakpoint.
class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key, this.existing});

  final CustomerOrder? existing;

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  late final _productType = TextEditingController(
    text: widget.existing?.productType,
  );
  late final _totalAmount = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.totalAmountTiyn / 100).toStringAsFixed(0),
  );
  late final _notes = TextEditingController(text: widget.existing?.description);

  String? _clientId;
  String? _clientName;
  String? _clientPhone;
  String? _employeeId;
  String? _employeeName;
  DateTime? _measurementDate;
  DateTime? _plannedCompletionDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _clientId = existing.clientId;
      _clientName = existing.clientName;
      _clientPhone = existing.clientPhone;
      _employeeId = existing.responsibleEmployeeId;
      _employeeName = existing.responsibleEmployeeName;
      _measurementDate = existing.measurementDate;
      _plannedCompletionDate = existing.plannedCompletionDate;
    }
  }

  @override
  void dispose() {
    _productType.dispose();
    _totalAmount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickClient() async {
    final client = await OrderClientPickerSheet.open(context);
    if (client == null) return;
    setState(() {
      _clientId = client.id;
      _clientName = client.name;
      _clientPhone = client.phone;
    });
  }

  Future<void> _pickEmployee() async {
    final employee = await OrderEmployeePickerSheet.open(context);
    if (employee == null) return;
    setState(() {
      _employeeId = employee.id;
      _employeeName = employee.fullName;
    });
  }

  Future<void> _pickDate({required bool isMeasurementDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (isMeasurementDate) {
        _measurementDate = picked;
      } else {
        _plannedCompletionDate = picked;
      }
    });
  }

  Future<void> _save() async {
    final strings = ref.read(appStringsProvider);

    if (_clientId == null ||
        _productType.text.trim().isEmpty ||
        _totalAmount.text.trim().isEmpty) {
      AppToast.show(strings.authFieldRequired, tone: ToastTone.error);
      return;
    }

    final totalMajorUnits = num.tryParse(_totalAmount.text.trim());
    if (totalMajorUnits == null || totalMajorUnits < 0) {
      AppToast.show(strings.authFieldRequired, tone: ToastTone.error);
      return;
    }

    setState(() => _saving = true);

    final isNew = widget.existing == null;
    final order = CustomerOrder(
      id: widget.existing?.id ?? '',
      orderNumber: widget.existing?.orderNumber ?? '',
      clientId: _clientId!,
      clientName: _clientName ?? '',
      clientPhone: _clientPhone ?? '',
      productType: _productType.text.trim(),
      description: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      status: widget.existing?.status ?? OrderStatus.measurement,
      responsibleEmployeeId: _employeeId,
      responsibleEmployeeName: _employeeName,
      measurementDate: _measurementDate,
      plannedCompletionDate: _plannedCompletionDate,
      totalAmountTiyn: (totalMajorUnits * 100).round(),
      paidTiyn: widget.existing?.paidTiyn ?? 0,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    final result = await ref
        .read(upsertOrderUseCaseProvider)
        .call(order, isNew: isNew);

    if (!mounted) return;
    setState(() => _saving = false);

    result.match(
      (failure) => AppToast.show(failure.message, tone: ToastTone.error),
      (_) {
        AppToast.show(
          isNew ? strings.orderCreatedToast : strings.orderUpdatedToast,
          tone: ToastTone.success,
        );
        context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final isNew = widget.existing == null;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(isNew ? strings.orderNewTitle : strings.orderEditTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                strings.orderFormClientLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _PickerField(
                icon: LucideIcons.user,
                label: _clientName ?? strings.orderFormSelectClient,
                filled: _clientName != null,
                onTap: _pickClient,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.orderFormProductTypeLabel,
                controller: _productType,
                prefixIcon: LucideIcons.armchair,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.orderFormTotalAmountLabel,
                controller: _totalAmount,
                prefixIcon: LucideIcons.banknote,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.orderFormMeasurementDateLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _PickerField(
                icon: LucideIcons.calendarDays,
                label: _measurementDate != null
                    ? AppFormatters.date(_measurementDate!)
                    : strings.orderFormSelectDate,
                filled: _measurementDate != null,
                onTap: () => _pickDate(isMeasurementDate: true),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.orderFormPlannedCompletionDateLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _PickerField(
                icon: LucideIcons.calendarCheck,
                label: _plannedCompletionDate != null
                    ? AppFormatters.date(_plannedCompletionDate!)
                    : strings.orderFormSelectDate,
                filled: _plannedCompletionDate != null,
                onTap: () => _pickDate(isMeasurementDate: false),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.orderFormResponsibleEmployeeLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              _PickerField(
                icon: LucideIcons.userCog,
                label: _employeeName ?? strings.orderResponsibleEmployeeNone,
                filled: _employeeName != null,
                onTap: _pickEmployee,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: strings.orderFormNotesLabel,
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
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
              child: Text(
                label,
                style: filled ? textTheme.bodyLarge : textTheme.bodyMedium,
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18),
          ],
        ),
      ),
    );
  }
}
