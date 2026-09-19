import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../data/datasources/partner_remote_datasource.dart';
import '../../data/repositories/partner_repository_impl.dart';
import '../../domain/entities/partner.dart';
import '../../domain/entities/partner_document.dart';
import '../../domain/repositories/partner_repository.dart';
import '../../domain/usecases/add_partner_document_usecase.dart';
import '../../domain/usecases/create_partner_usecase.dart';
import '../../domain/usecases/delete_partner_document_usecase.dart';
import '../../domain/usecases/delete_partner_usecase.dart';
import '../../domain/usecases/get_partner_documents_usecase.dart';
import '../../domain/usecases/get_partner_usecase.dart';
import '../../domain/usecases/get_partners_usecase.dart';
import '../../domain/usecases/restore_partner_usecase.dart';
import '../../domain/usecases/update_partner_financials_usecase.dart';
import '../../domain/usecases/update_partner_usecase.dart';
import '../../domain/value_objects/partner_category.dart';

final partnerRemoteDataSourceProvider = Provider<PartnerRemoteDataSource>((
  ref,
) {
  return PartnerRemoteDataSource(ref.watch(supabaseClientProvider));
});

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return PartnerRepositoryImpl(ref.watch(partnerRemoteDataSourceProvider));
});

final getPartnersUseCaseProvider = Provider<GetPartnersUseCase>((ref) {
  return GetPartnersUseCase(ref.watch(partnerRepositoryProvider));
});

final getPartnerUseCaseProvider = Provider<GetPartnerUseCase>((ref) {
  return GetPartnerUseCase(ref.watch(partnerRepositoryProvider));
});

final createPartnerUseCaseProvider = Provider<CreatePartnerUseCase>((ref) {
  return CreatePartnerUseCase(ref.watch(partnerRepositoryProvider));
});

final updatePartnerUseCaseProvider = Provider<UpdatePartnerUseCase>((ref) {
  return UpdatePartnerUseCase(ref.watch(partnerRepositoryProvider));
});

final updatePartnerFinancialsUseCaseProvider =
    Provider<UpdatePartnerFinancialsUseCase>((ref) {
      return UpdatePartnerFinancialsUseCase(
        ref.watch(partnerRepositoryProvider),
      );
    });

final deletePartnerUseCaseProvider = Provider<DeletePartnerUseCase>((ref) {
  return DeletePartnerUseCase(ref.watch(partnerRepositoryProvider));
});

final restorePartnerUseCaseProvider = Provider<RestorePartnerUseCase>((ref) {
  return RestorePartnerUseCase(ref.watch(partnerRepositoryProvider));
});

final getPartnerDocumentsUseCaseProvider = Provider<GetPartnerDocumentsUseCase>(
  (ref) {
    return GetPartnerDocumentsUseCase(ref.watch(partnerRepositoryProvider));
  },
);

final addPartnerDocumentUseCaseProvider = Provider<AddPartnerDocumentUseCase>((
  ref,
) {
  return AddPartnerDocumentUseCase(ref.watch(partnerRepositoryProvider));
});

final deletePartnerDocumentUseCaseProvider =
    Provider<DeletePartnerDocumentUseCase>((ref) {
      return DeletePartnerDocumentUseCase(ref.watch(partnerRepositoryProvider));
    });

final partnerSearchQueryProvider = StateProvider<String>((ref) => '');
final partnerCategoryFilterProvider = StateProvider<PartnerCategory?>(
  (ref) => null,
);

/// `null` = "барлық статустар" (both active and inactive).
final partnerActiveFilterProvider = StateProvider<bool?>((ref) => null);

/// Requirement #7 "Өшірілген серіктесті қалпына келтіру" — a
/// director-only "trash" toggle; the server ignores it for anyone else.
final partnerShowTrashProvider = StateProvider<bool>((ref) => false);

const _partnersPageSize = 30;

/// Bundles the current filter/search/trash state into one value so it
/// can key [partnersListProvider] — Dart records get structural
/// equality for free, so a filter change (new record) correctly
/// produces a fresh paginated list while an unrelated rebuild with the
/// same filter reuses the cached one.
typedef PartnersFilter = ({
  String search,
  PartnerCategory? category,
  bool? active,
  bool includeDeleted,
});

class PartnersPage {
  const PartnersPage({required this.items, required this.hasMore});
  final List<Partner> items;
  final bool hasMore;
}

class PartnersListNotifier extends StateNotifier<AsyncValue<PartnersPage>> {
  PartnersListNotifier(this._getPartners, this._filter)
    : super(const AsyncValue.loading()) {
    _loadFirstPage();
  }

  final GetPartnersUseCase _getPartners;
  final PartnersFilter _filter;
  bool _isLoadingMore = false;

  Future<void> _loadFirstPage() async {
    state = const AsyncValue.loading();
    final result = await _getPartners(
      searchQuery: _filter.search,
      categoryFilter: _filter.category,
      activeFilter: _filter.active,
      includeDeleted: _filter.includeDeleted,
      limit: _partnersPageSize,
      offset: 0,
    );
    state = result.match(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (items) => AsyncValue.data(
        PartnersPage(items: items, hasMore: items.length == _partnersPageSize),
      ),
    );
  }

  Future<void> refresh() => _loadFirstPage();

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    final result = await _getPartners(
      searchQuery: _filter.search,
      categoryFilter: _filter.category,
      activeFilter: _filter.active,
      includeDeleted: _filter.includeDeleted,
      limit: _partnersPageSize,
      offset: current.items.length,
    );
    _isLoadingMore = false;
    if (!mounted) return;
    result.match((failure) {}, (newItems) {
      state = AsyncValue.data(
        PartnersPage(
          items: [...current.items, ...newItems],
          hasMore: newItems.length == _partnersPageSize,
        ),
      );
    });
  }
}

final partnersListProvider = StateNotifierProvider.autoDispose
    .family<PartnersListNotifier, AsyncValue<PartnersPage>, PartnersFilter>((
      ref,
      filter,
    ) {
      return PartnersListNotifier(
        ref.watch(getPartnersUseCaseProvider),
        filter,
      );
    });

final partnerDetailProvider = FutureProvider.autoDispose
    .family<Partner, String>((ref, id) {
      return ref
          .watch(getPartnerUseCaseProvider)
          .call(id)
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

final partnerDocumentsProvider = FutureProvider.autoDispose
    .family<List<PartnerDocument>, String>((ref, partnerId) {
      return ref
          .watch(getPartnerDocumentsUseCaseProvider)
          .call(partnerId)
          .then(
            (either) =>
                either.match((failure) => throw failure, (data) => data),
          );
    });

/// UI-convenience only, per SECURITY_PLAN.md finding #6 — hiding a
/// button is not the authorization boundary, `partners.write`/
/// director-only checks in the RPCs (see
/// supabase/migrations/20260713000018_partners_module.sql) are. This
/// only decides which buttons this session's role set makes worth
/// showing.
extension PartnerAccess on AuthUser {
  bool get canWritePartners =>
      isDirector || hasRole('manager') || hasRole('purchaser');
  bool get canDeletePartners => isDirector;
}
