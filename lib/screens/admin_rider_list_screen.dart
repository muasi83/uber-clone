import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/admin_riders_service.dart';
import 'admin_rider_details_screen.dart';
import '../theme/app_colors.dart';
import '../services/recorded_screen_mixin.dart';

class AdminRiderListScreen extends StatefulWidget {
  const AdminRiderListScreen({super.key});

  @override
  State<AdminRiderListScreen> createState() => _AdminRiderListScreenState();
}

class _AdminRiderListScreenState extends State<AdminRiderListScreen> with RecordedScreenMixin<AdminRiderListScreen> {
  List<Map<String, dynamic>>? _riders;
  bool _loading = true;
  String? _token;
  String _filterText = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    recordEvent(eventName: 'ADMIN_SCREEN_OPENED');
    _token = StorageService.getToken();
    _loadRiders();
  }

  Future<void> _loadRiders() async {
    if (_token == null) return;
    setState(() => _loading = true);
    final riders = await AdminRidersService.getRiders(_token!);
    if (!mounted) return;
    setState(() {
      _riders = riders;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredRiders {
    if (_riders == null) return [];
    return _riders!.where((r) {
      if (_statusFilter == 'online' && r['online'] != true) return false;
      if (_statusFilter == 'offline' && r['online'] == true) return false;
      if (_statusFilter == 'blocked' && r['blocked'] != true) return false;
      if (_statusFilter == 'unblocked' && r['blocked'] == true) return false;
      if (_filterText.isNotEmpty) {
        final name = (r['name'] as String? ?? '').toLowerCase();
        final email = (r['email'] as String? ?? '').toLowerCase();
        final phone = (r['phoneNumber'] as String? ?? '').toLowerCase();
        final q = _filterText.toLowerCase();
        if (!name.contains(q) && !email.contains(q) && !phone.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riders'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRiders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColors.surface,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, email, or phone',
              hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _filterText = v),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'all'),
                const SizedBox(width: 6),
                _filterChip('Online', 'online'),
                const SizedBox(width: 6),
                _filterChip('Offline', 'offline'),
                const SizedBox(width: 6),
                _filterChip('Blocked', 'blocked'),
                const SizedBox(width: 6),
                _filterChip('Active', 'unblocked'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary)),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = value),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      backgroundColor: AppColors.surfaceVariant,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_riders == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            const Text('Failed to load riders', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadRiders, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_filteredRiders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            const Text('No riders found', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRiders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredRiders.length,
        itemBuilder: (context, index) => _buildRiderCard(_filteredRiders[index]),
      ),
    );
  }

  Widget _buildRiderCard(Map<String, dynamic> rider) {
    final name = rider['name'] as String? ?? 'Unknown';
    final email = rider['email'] as String? ?? '';
    final phone = rider['phoneNumber'] as String?;
    final blocked = rider['blocked'] == true;
    final online = rider['online'] == true;
    final totalTrips = rider['totalTrips'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final riderId = rider['riderId'] as int?;
          if (riderId == null) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminRiderDetailsScreen(
                riderId: riderId,
                riderName: name,
              ),
            ),
          );
          _loadRiders();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: blocked
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person, color: blocked ? AppColors.error : AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                        if (blocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('BLOCKED', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
                          ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: online ? AppColors.success : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (phone != null) Text(phone, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text('$totalTrips trips', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
