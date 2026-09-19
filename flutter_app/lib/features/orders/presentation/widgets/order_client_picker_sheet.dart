import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/debounced_search_controller.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../clients/presentation/providers/client_providers.dart';

/// Requirement #7 ("Клиентті Clients кестесінен таңдау"): reuses the
/// Clients feature's own repository/entities rather than duplicating a
/// client list inside the Orders module — this picker has its own
/// local search state instead of the global `clientSearchQueryProvider`
/// so opening it from an order form never clobbers whatever the user
/// had typed on the actual Clients screen.
class OrderClientPickerSheet extends ConsumerStatefulWidget {
  const OrderClientPickerSheet({super.key});

  static Future<Client?> open(BuildContext context) {
    return showAppBottomSheet<Client>(
      context: context,
      child: const OrderClientPickerSheet(),
    );
  }

  @override
  ConsumerState<OrderClientPickerSheet> createState() =>
      _OrderClientPickerSheetState();
}

class _OrderClientPickerSheetState
    extends ConsumerState<OrderClientPickerSheet> {
  late final _search = DebouncedSearchController(
    debounce: const Duration(milliseconds: 300),
    onSearch: (value) => setState(() => _future = _fetch(value)),
  );
  late Future<List<Client>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch('');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Client>> _fetch(String query) {
    return ref
        .read(clientRepositoryProvider)
        .getClients(searchQuery: query)
        .then(
          (either) => either.match((failure) => throw failure, (data) => data),
        );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            strings.orderSelectClientTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _search.textController,
            onChanged: _search.onChanged,
            decoration: InputDecoration(
              hintText: strings.clientsSearchHint,
              prefixIcon: const Icon(LucideIcons.search, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: FutureBuilder<List<Client>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                    child: LoadingView(),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxxl,
                    ),
                    child: ErrorView(message: strings.dashboardLoadError),
                  );
                }
                final clients = snapshot.data ?? [];
                if (clients.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxxl,
                    ),
                    child: EmptyView(
                      icon: LucideIcons.userX,
                      title: strings.clientsEmptyTitle,
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return ListTile(
                      onTap: () => Navigator.of(context).pop(client),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.skyDeep.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          client.name.isNotEmpty
                              ? client.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.skyDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(client.name),
                      subtitle: Text(client.phone),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
