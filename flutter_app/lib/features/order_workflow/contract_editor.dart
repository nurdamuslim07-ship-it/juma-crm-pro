import '../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';
import 'workflow_strings.dart';
import 'workflow_repository.dart';

Future<Uint8List> contractPdf(
  Map<String, String> fields,
  WorkflowStrings s,
  String number,
) async {
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
  );
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: font),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (c) => pw.Text(
        '${s.draft} · ${c.pageNumber}/${c.pagesCount}',
        style: const pw.TextStyle(fontSize: 9),
      ),
      build: (_) => [
        pw.Text('JUMA · ${s.draft}', style: const pw.TextStyle(fontSize: 22)),
        pw.SizedBox(height: 8),
        pw.Text('№ $number'),
        pw.SizedBox(height: 20),
        for (final field in fields.entries)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Text('${field.key}\n${field.value}'),
          ),
        pw.SizedBox(height: 20),
        pw.Text(s.hint, style: const pw.TextStyle(fontSize: 10)),
      ],
    ),
  );
  return doc.save();
}

class ContractEditor extends ConsumerStatefulWidget {
  const ContractEditor({super.key, required this.order, required this.company});
  final Map<String, dynamic> order, company;
  @override
  ConsumerState<ContractEditor> createState() => _ContractEditorState();
}

class _ContractEditorState extends ConsumerState<ContractEditor> {
  final form = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final o = widget.order,
        c = widget.company,
        client = o['client'] as Map? ?? {};
    final defaults = {
      'company': [
        c['name'],
        c['iin_bin'],
        c['address'],
        c['phone'],
      ].where((v) => v != null && v.toString().isNotEmpty).join('\n'),
      'client': [
        client['name'],
        client['phone'],
        client['address'],
      ].where((v) => v != null).join('\n'),
      'product': [
        o['product_type'],
        o['material'],
        o['dimensions'],
      ].where((v) => v != null).join('\n'),
      'amount': ((o['total_amount_tiyn'] as num) / 100).toStringAsFixed(2),
      'payment': '',
      'deadline': o['planned_completion_date']?.toString() ?? '',
      'warranty': '',
      'terms': '',
    };
    for (final e in defaults.entries) {
      controllers[e.key] = TextEditingController(text: e.value);
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> action(bool save) async {
    final s = ref.read(workflowStringsProvider);
    if (save && !(form.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    final labels = {
      'company': s.company,
      'client': s.client,
      'product': s.product,
      'amount': s.amount,
      'payment': s.payment,
      'deadline': s.deadline,
      'warranty': s.warranty,
      'terms': s.terms,
    };
    try {
      final snapshot = controllers.map(
        (k, v) => MapEntry(labels[k]!, v.text.trim()),
      );
      final bytes = await contractPdf(
        snapshot,
        s,
        widget.order['order_number'] as String,
      );
      if (save) {
        final db = ref.read(supabaseClientProvider);
        final path =
            '${widget.order['company_id']}/${widget.order['id']}/${DateTime.now().microsecondsSinceEpoch}.pdf';
        await db.storage
            .from('order-contracts')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(contentType: 'application/pdf'),
            );
        await db.rpc(
          'save_order_contract',
          params: {
            'p_order_id': widget.order['id'],
            'p_snapshot': snapshot,
            'p_storage_path': path,
          },
        );
        ref.invalidate(orderWorkflowProvider(widget.order['id'] as String));
        if (mounted) Navigator.pop(context);
      } else {
        await Printing.layoutPdf(
          name: 'JUMA-contract.pdf',
          onLayout: (_) async => bytes,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.error)));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(workflowStringsProvider);
    final labels = {
      'company': s.company,
      'client': s.client,
      'product': s.product,
      'amount': s.amount,
      'payment': s.payment,
      'deadline': s.deadline,
      'warranty': s.warranty,
      'terms': s.terms,
    };
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: Text(s.draft)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(s.hint),
                const SizedBox(height: 20),
                for (final e in labels.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: TextFormField(
                      controller: controllers[e.key],
                      enabled: !busy,
                      decoration: InputDecoration(labelText: e.value),
                      minLines: e.key == 'amount' ? 1 : 2,
                      maxLines: e.key == 'amount' ? 1 : 5,
                      validator: (v) {
                        if (e.key != 'terms' && (v ?? '').trim().isEmpty) {
                          return s.required;
                        }
                        if (e.key == 'amount' &&
                            !RegExp(
                              r'^\d{1,10}([.,]\d{1,2})?$',
                            ).hasMatch((v ?? '').trim())) {
                          return s.required;
                        }
                        return null;
                      },
                    ),
                  ),
                if (busy)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  OutlinedButton(
                    onPressed: () => action(false),
                    child: Text(s.preview),
                  ),
                  FilledButton(
                    onPressed: () => action(true),
                    child: Text(s.save),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
