import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:juma_ui_crm/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:juma_ui_crm/features/payments/domain/value_objects/payment_method.dart';

void main() {
  test(
    'payment methods refresh after provisioning and session changes',
    () async {
      var count = 0;
      final client = SupabaseClient(
        'https://test.supabase.co',
        'test',
        httpClient: MockClient((request) async {
          count++;
          return http.Response(
            count == 1 ? '[]' : '[{"id":"company-$count-kaspi","key":"kaspi"}]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      final source = PaymentRemoteDataSource(client);
      expect(await source.getPaymentMethodIds(), isEmpty);
      expect(
        (await source.getPaymentMethodIds())[PaymentMethod.kaspi],
        'company-2-kaspi',
      );
      expect(
        (await source.getPaymentMethodIds())[PaymentMethod.kaspi],
        'company-3-kaspi',
      );
      await client.dispose();
    },
  );
}
