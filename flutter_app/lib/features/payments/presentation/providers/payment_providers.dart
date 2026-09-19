import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/realtime/table_realtime_provider.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/usecases/create_payment_usecase.dart';
import '../../domain/usecases/delete_payment_usecase.dart';
import '../../domain/usecases/get_payments_usecase.dart';
import '../../domain/usecases/update_payment_usecase.dart';
import '../../domain/usecases/upload_receipt_usecase.dart';
import '../../domain/value_objects/payment_method.dart';

final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>((
  ref,
) {
  return PaymentRemoteDataSource(ref.watch(supabaseClientProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.watch(paymentRemoteDataSourceProvider));
});

final getPaymentsUseCaseProvider = Provider<GetPaymentsUseCase>((ref) {
  return GetPaymentsUseCase(ref.watch(paymentRepositoryProvider));
});

final createPaymentUseCaseProvider = Provider<CreatePaymentUseCase>((ref) {
  return CreatePaymentUseCase(ref.watch(paymentRepositoryProvider));
});

final updatePaymentUseCaseProvider = Provider<UpdatePaymentUseCase>((ref) {
  return UpdatePaymentUseCase(ref.watch(paymentRepositoryProvider));
});

final deletePaymentUseCaseProvider = Provider<DeletePaymentUseCase>((ref) {
  return DeletePaymentUseCase(ref.watch(paymentRepositoryProvider));
});

final uploadReceiptUseCaseProvider = Provider<UploadReceiptUseCase>((ref) {
  return UploadReceiptUseCase(ref.watch(paymentRepositoryProvider));
});

/// Small, rarely-changing lookup — fetched once per app session.
final paymentMethodIdsProvider = FutureProvider<Map<PaymentMethod, String>>((
  ref,
) {
  return ref
      .watch(paymentRepositoryProvider)
      .getPaymentMethodIds()
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});

// ---- global "Төлемдер" tab state ----

final paymentSearchQueryProvider = StateProvider<String>((ref) => '');
final paymentMethodFilterProvider = StateProvider<PaymentMethod?>(
  (ref) => null,
);
final paymentDateFromProvider = StateProvider<DateTime?>((ref) => null);
final paymentDateToProvider = StateProvider<DateTime?>((ref) => null);

final paymentsListProvider = FutureProvider.autoDispose<List<Payment>>((ref) {
  final query = ref.watch(paymentSearchQueryProvider);
  final method = ref.watch(paymentMethodFilterProvider);
  final from = ref.watch(paymentDateFromProvider);
  final to = ref.watch(paymentDateToProvider);
  return ref
      .watch(getPaymentsUseCaseProvider)
      .call(
        searchQuery: query,
        methodFilter: method,
        dateFrom: from,
        dateTo: to,
      )
      .then(
        (either) => either.match((failure) => throw failure, (data) => data),
      );
});

/// Requirement #2 "Төлем тарихы" — one order's payment history, used
/// by OrderDetailScreen.
final orderPaymentsProvider = FutureProvider.autoDispose
    .family<List<Payment>, String>((ref, orderId) {
      return ref
          .watch(getPaymentsUseCaseProvider)
          .call(orderId: orderId)
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

/// Stage 4 Part 1 — see `ordersRealtimeProvider`'s own doc comment for
/// the general pattern.
final paymentsRealtimeProvider = tableRealtimeProvider('payments', (ref) {
  ref.invalidate(paymentsListProvider);
});
