import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/supabase_provider.dart';

final orderWorkflowProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
      final db = ref.watch(supabaseClientProvider);
      final order = await db
          .from('orders')
          .select('*,client:clients(name,phone,address)')
          .eq('id', id)
          .single();
      final values = await Future.wait([
        db
            .from('order_journey_history')
            .select()
            .eq('order_id', id)
            .order('created_at', ascending: false),
        db
            .from('whatsapp_outbox')
            .select('id,kind,payload,status,error_code,created_at')
            .eq('order_id', id)
            .order('created_at', ascending: false),
        db
            .from('order_contracts')
            .select()
            .eq('order_id', id)
            .order('created_at', ascending: false),
        db
            .from('client_whatsapp_consent')
            .select()
            .eq('client_id', order['client_id']),
        db
            .from('companies')
            .select('name,iin_bin,address,phone')
            .eq('id', order['company_id']),
      ]);
      return {
        'order': order,
        'history': values[0],
        'messages': values[1],
        'contracts': values[2],
        'consent': values[3],
        'company': values[4],
      };
    });
