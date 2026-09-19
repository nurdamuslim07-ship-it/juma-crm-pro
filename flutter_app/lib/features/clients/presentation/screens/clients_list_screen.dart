import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/debounced_search_controller.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/client_providers.dart';
import '../widgets/client_form_sheet.dart';
import '../widgets/client_list_tile.dart';

class ClientsListScreen extends ConsumerStatefulWidget {
  const ClientsListScreen({super.key});

  @override
  ConsumerState<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends ConsumerState<ClientsListScreen> {
  late final _search = DebouncedSearchController(
    onSearch: (value) =>
        ref.read(clientSearchQueryProvider.notifier).state = value,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final clientsAsync = ref.watch(clientsListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(strings.navClients),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await ClientFormSheet.open(context);
          if (created == true) ref.invalidate(clientsListProvider);
        },
        child: const Icon(LucideIcons.plus),
      ),
      body: Padding(
        padding: context.pageInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search.textController,
              onChanged: _search.onChanged,
              decoration: InputDecoration(
                hintText: strings.clientsSearchHint,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: clientsAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: strings.dashboardLoadError,
                  retryLabel: strings.commonRetry,
                  onRetry: () => ref.invalidate(clientsListProvider),
                ),
                data: (clients) {
                  if (clients.isEmpty) {
                    return EmptyView(
                      icon: LucideIcons.users,
                      title: strings.clientsEmptyTitle,
                      description: strings.clientsEmptyDescription,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(clientsListProvider),
                    child: ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return ClientListTile(
                          client: client,
                          onTap: () =>
                              context.push(RoutePaths.clientDetail(client.id)),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
