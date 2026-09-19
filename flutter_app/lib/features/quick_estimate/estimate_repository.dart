import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';
import 'estimate_model.dart';

final estimateRepositoryProvider = Provider(
  (ref) => EstimateRepository(ref.watch(supabaseClientProvider)),
);
final estimateListProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(estimateRepositoryProvider).list(),
);

class EstimateRepository {
  EstimateRepository(this.client);
  final SupabaseClient client;
  Future<List<Map<String, dynamic>>> list() async => await client
      .from('quick_estimates')
      .select('id,name,snapshot,updated_at')
      .order('updated_at', ascending: false);
  Future<String> save(String? id, Estimate e) async {
    final data = {
      'name': e.name,
      'snapshot': e.toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final row = id == null
        ? await client
              .from('quick_estimates')
              .insert(data)
              .select('id')
              .single()
        : await client
              .from('quick_estimates')
              .update(data)
              .eq('id', id)
              .select('id')
              .single();
    return row['id'] as String;
  }

  Future<List<CostLine>> catalog() async {
    final rows = await client.from('estimate_price_catalog').select('snapshot');
    return rows
        .map((r) => CostLine.fromJson(Map<String, dynamic>.from(r['snapshot'])))
        .toList();
  }

  Future<void> savePrice(CostLine line) async {
    // Quantity overrides belong to a particular estimate, never to the catalog.
    final snapshot = line.toJson()..['quantity'] = null;
    await client.from('estimate_price_catalog').upsert({
      'item_key': line.id,
      'snapshot': snapshot,
    }, onConflict: 'company_id,item_key');
  }
}
