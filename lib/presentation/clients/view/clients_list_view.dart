import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/client_model.dart';
import '../../../data/repositories/client_repository.dart';
import '../../task/widgets/task_screen_header.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/skeletons/api_tab_skeletons.dart';
import '../widgets/client_list_widgets.dart';
import '../widgets/clients_search_bar.dart';
import 'client_profile_view.dart';

/// Figma node `1:2202` — assigned clients list.
class ClientsListView extends StatefulWidget {
  const ClientsListView({super.key});

  @override
  State<ClientsListView> createState() => _ClientsListViewState();
}

class _ClientsListViewState extends State<ClientsListView> {
  final _repository = sl<ClientRepository>();
  final _searchController = TextEditingController();
  List<ClientModel> _clients = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final items = await _repository.fetchClients();
      if (!mounted) return;
      setState(() {
        _clients = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  List<ClientModel> get _filteredClients {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _clients;
    return _clients
        .where(
          (client) =>
              client.name.toLowerCase().contains(query) ||
              client.listSubtitle.toLowerCase().contains(query) ||
              client.address.toLowerCase().contains(query),
        )
        .toList();
  }

  void _openProfile(ClientModel client) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClientProfileView(client: client),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              TaskScreenHeader(
                title: 'My Clients',
                subtitle: 'Assigned to you',
                height: 171,
                onBack: () => Navigator.of(context).pop(),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: -30,
                child: ClientsSearchBar(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 38),
          Expanded(
            child: GetRequestView(
              isLoading: _isLoading,
              hasError: _hasError,
              onRetry: _load,
              skeleton: const ClientsListSkeleton(),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final clients = _filteredClients;
    if (clients.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.homePrimary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No clients found')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.homePrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.homeCardShadow,
                  blurRadius: 26,
                  offset: Offset(0, 24),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < clients.length; i++)
                  ClientListSection(
                    client: clients[i],
                    onOpenProfile: () => _openProfile(clients[i]),
                    showDivider: i < clients.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
