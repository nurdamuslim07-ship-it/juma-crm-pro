import '../../core/widgets/app_back_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../core/providers/supabase_provider.dart';
import '../../core/theme/glass/liquid_glass.dart';
import 'workflow_strings.dart';
import 'workflow_repository.dart';
import 'contract_editor.dart';

class OrderWorkflowScreen extends ConsumerStatefulWidget {
  const OrderWorkflowScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<OrderWorkflowScreen> createState() =>
      _OrderWorkflowScreenState();
}

class _OrderWorkflowScreenState extends ConsumerState<OrderWorkflowScreen> {
  bool busy = false;
  Future<void> run(Future<void> Function() task) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await task();
      ref.invalidate(orderWorkflowProvider(widget.orderId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(workflowStringsProvider).error)),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> consent(String clientId, bool enabled) async {
    final s = ref.read(workflowStringsProvider),
        controller = TextEditingController();
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.source),
        content: TextField(controller: controller, maxLength: 200),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.trim().length >= 3) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (source == null || !mounted) return;
    await run(
      () => ref
          .read(supabaseClientProvider)
          .rpc(
            'set_client_whatsapp_consent',
            params: {
              'p_client_id': clientId,
              'p_enabled': enabled,
              'p_source': source,
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(workflowStringsProvider);
    final state = ref.watch(orderWorkflowProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: Text(s.title)),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () =>
                ref.invalidate(orderWorkflowProvider(widget.orderId)),
            child: Text(s.error),
          ),
        ),
        data: (data) {
          final order = data['order'] as Map<String, dynamic>;
          final consents = data['consent'] as List;
          final stages = data['history'] as List;
          final contracts = data['contracts'] as List;
          final messages = data['messages'] as List;
          final companies = data['company'] as List;
          Widget card(Widget child) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: LiquidGlass(padding: const EdgeInsets.all(18), child: child),
          );
          return AbsorbPointer(
            absorbing: busy,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(orderWorkflowProvider(widget.orderId));
                await ref.read(orderWorkflowProvider(widget.orderId).future);
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (busy) const LinearProgressIndicator(),
                  card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['order_number'] as String,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        DropdownButton<String>(
                          value: order['journey_stage'] as String,
                          isExpanded: true,
                          items: [
                            for (final key in WorkflowStrings.stages)
                              DropdownMenuItem(
                                value: key,
                                child: Text(s.stage(key)),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              run(
                                () => ref
                                    .read(supabaseClientProvider)
                                    .rpc(
                                      'set_order_journey',
                                      params: {
                                        'p_order_id': widget.orderId,
                                        'p_stage': value,
                                      },
                                    ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => run(() async {
                            final db = ref.read(supabaseClientProvider);
                            final token = await db.rpc(
                              'create_order_tracking_link',
                              params: {'p_order_id': widget.orderId},
                            );
                            final url =
                                '${db.rest.url.split('/rest/v1').first}/functions/v1/order-tracking?token=$token';
                            await Clipboard.setData(ClipboardData(text: url));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(s.trackingHint)),
                              );
                            }
                          }),
                          icon: const Icon(Icons.link),
                          label: Text(s.tracking),
                        ),
                        Text(s.history),
                        for (final h in stages.take(15))
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(s.stage(h['stage'] as String)),
                            subtitle: Text(
                              DateTime.parse(
                                h['created_at'] as String,
                              ).toLocal().toString().split('.').first,
                            ),
                          ),
                      ],
                    ),
                  ),
                  card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.messages,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(s.setup),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.consent),
                          value:
                              consents.isNotEmpty &&
                              consents.first['enabled'] == true,
                          onChanged: (value) =>
                              consent(order['client_id'] as String, value),
                        ),
                        if (messages.isEmpty) Text(s.empty),
                        for (final m in messages.take(20))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              m['kind'] == 'contract'
                                  ? Icons.description_outlined
                                  : Icons.chat_outlined,
                            ),
                            title: Text(
                              m['kind'] == 'contract'
                                  ? s.contracts
                                  : s.stage(m['payload']['stage'] as String),
                            ),
                            subtitle: Text(
                              '${s.status(m['status'] as String)}\n${DateTime.parse(m['created_at'] as String).toLocal().toString().split('.').first}',
                            ),
                          ),
                      ],
                    ),
                  ),
                  card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          s.contracts,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ContractEditor(
                                order: order,
                                company: companies.isEmpty
                                    ? {}
                                    : Map<String, dynamic>.from(
                                        companies.first as Map,
                                      ),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.description_outlined),
                          label: Text(s.create),
                        ),
                        for (final c in contracts) ...[
                          const Divider(),
                          Text(
                            '${s.draft} · ${DateTime.parse(c['created_at'] as String).toLocal().toString().split('.').first}',
                          ),
                          TextButton.icon(
                            onPressed: () => run(() async {
                              final bytes = await ref
                                  .read(supabaseClientProvider)
                                  .storage
                                  .from('order-contracts')
                                  .download(c['storage_path'] as String);
                              await Printing.layoutPdf(
                                name: 'JUMA-contract.pdf',
                                onLayout: (_) async => bytes,
                              );
                            }),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: Text(s.pdf),
                          ),
                          if (c['status'] == 'draft')
                            OutlinedButton(
                              onPressed: () => run(
                                () => ref
                                    .read(supabaseClientProvider)
                                    .rpc(
                                      'approve_order_contract',
                                      params: {'p_contract_id': c['id']},
                                    ),
                              ),
                              child: Text(s.approve),
                            )
                          else
                            Text(s.approved),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
