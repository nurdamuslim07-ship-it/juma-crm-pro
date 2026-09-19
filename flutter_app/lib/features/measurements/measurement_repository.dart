import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';
import '../auth/presentation/providers/auth_providers.dart';

final measurementRepositoryProvider = Provider(
  (ref) => MeasurementRepository(ref.watch(supabaseClientProvider)),
);
final measurementsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final company = ref.watch(currentUserProvider)?.companyId;
      if (company == null) return [];
      return ref.watch(measurementRepositoryProvider).list(company);
    });

// Parse money as integer tiyn, without a floating-point round trip.
int? measurementPriceTiyn(String input) {
  final value = input.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  return int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
}

class MeasurementRepository {
  MeasurementRepository(this.client);
  final SupabaseClient client;
  Future<List<Map<String, dynamic>>> list(String company) async => await client
      .from('measurements')
      .select('*, client:clients(name)')
      .eq('company_id', company)
      .order('created_at', ascending: false);
  Future<Map<String, dynamic>> save(
    String? id,
    Map<String, dynamic> data,
  ) async {
    if (id == null) {
      return await client.from('measurements').insert(data).select().single();
    }
    return await client
        .from('measurements')
        .update(data)
        .eq('id', id)
        .select()
        .single();
  }

  Future<String> convert(String id) async =>
      await client.rpc('measurement_to_order', params: {'p_measurement_id': id})
          as String;
  Future<String> photoUrl(String path) =>
      client.storage.from('measurement-photos').createSignedUrl(path, 3600);
}

final measurementPhotoUrlProvider = FutureProvider.autoDispose
    .family<String, String>(
      (ref, path) => ref.watch(measurementRepositoryProvider).photoUrl(path),
    );
