import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/client_model.dart';
import '../../../data/repositories/client_repository.dart';
import '../../task/widgets/task_screen_header.dart';
import '../../widgets/error_widget.dart';
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
  String? _error;

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
      _error = null;
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
        _error = 'Unable to load clients.';
        _isLoading = false;
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
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ErrorDisplayWidget(onRetry: _load);
    }

    if (_isLoading) {
      return Skeletonizer(
        enabled: true,
        effect: ShimmerEffect(
          baseColor: AppColors.homeSheetDetailsBg,
          highlightColor: AppColors.surface,
        ),
        child: const ClientsListSkeleton(),
      );
    }

    final clients = _filteredClients;
    if (clients.isEmpty) {
      return const Center(child: Text('No clients found'));
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
