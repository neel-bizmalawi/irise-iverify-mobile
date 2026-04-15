import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:irise/route/app_routes.dart';
import 'package:irise/data/repositories/beneficiary_repository.dart';
import 'package:irise/data/repositories/training_site_repository.dart';
import 'package:irise/data/models/beneficiary.dart';
import 'package:irise/data/services/data_service.dart';
import 'package:irise/core/services/connectivity_service.dart';
import 'dart:async';
import 'dart:developer' as developer;

class BeneficiaryListScreen extends StatefulWidget {
  const BeneficiaryListScreen({super.key});

  @override
  State<BeneficiaryListScreen> createState() => _BeneficiaryListScreenState();
}

class _BeneficiaryListScreenState extends State<BeneficiaryListScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _beneficiaryRepo = BeneficiaryRepository();
  final _dataService = DataService();
  static const int _pageSize = 30;

  String _searchQuery = '';
  List<Beneficiary> _beneficiaries = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasLoadedOnce = false;
  bool _hasInitialFetch = false;
  bool _allTrainingSitesSynced = true;
  int _unsyncedTrainingSitesCount = 0;
  int _offset = 0;
  int _totalCount = 0;
  int _syncedCount = 0;
  int _unsyncedCount = 0;
  int _matchingCount = 0;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _checkInitialFetch();
    _checkTrainingSitesStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload when app comes to foreground
    if (state == AppLifecycleState.resumed && _hasLoadedOnce) {
      developer.log('App resumed, reloading beneficiaries...',
          name: 'BeneficiaryList');
      _resetAndLoadBeneficiaries();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || _isLoadingMore) return;

    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold && _hasMore) {
      _loadMoreBeneficiaries();
    }
  }

  Future<void> _checkInitialFetch() async {
    setState(() => _isLoading = true);
    try {
      // Check if there are any beneficiaries in the database
      final count = await _beneficiaryRepo.getCount();
      setState(() {
        _hasInitialFetch = count > 0;
        _isLoading = false;
      });

      if (_hasInitialFetch) {
        _resetAndLoadBeneficiaries();
      }
    } catch (e) {
      developer.log('Error checking initial fetch: $e',
          name: 'BeneficiaryList');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkTrainingSitesStatus() async {
    try {
      final trainingSiteRepo = TrainingSiteRepository();
      final allSynced = await trainingSiteRepo.areAllTrainingSitesSynced();
      final unsyncedCount = await trainingSiteRepo.getUnsyncedCount();

      setState(() {
        _allTrainingSitesSynced = allSynced;
        _unsyncedTrainingSitesCount = unsyncedCount;
      });

      developer.log(
          'Training sites sync status: allSynced=$allSynced, unsyncedCount=$unsyncedCount',
          name: 'BeneficiaryList');
    } catch (e) {
      developer.log('Error checking training sites status: $e',
          name: 'BeneficiaryList');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always reload data when this screen becomes the current route
    // This ensures we pick up any changes made in other screens (like EditHouseholdScreen)
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && _hasLoadedOnce) {
      developer.log('Screen became active, reloading beneficiaries...',
          name: 'BeneficiaryList');
      // Use Future.microtask to avoid calling setState during build
      Future.microtask(() {
        _resetAndLoadBeneficiaries();
        _checkTrainingSitesStatus();
      });
    }
  }

  Future<void> _refreshCounts() async {
    try {
      final results = await Future.wait([
        _beneficiaryRepo.getCount(),
        _beneficiaryRepo.getSyncedCount(),
        _beneficiaryRepo.getUnsyncedCount(),
        _beneficiaryRepo.getFilteredCount(searchQuery: _searchQuery),
      ]);

      setState(() {
        _totalCount = results[0];
        _syncedCount = results[1];
        _unsyncedCount = results[2];
        _matchingCount = results[3];
      });
    } catch (e) {
      developer.log('Error refreshing counts: $e', name: 'BeneficiaryList');
    }
  }

  Future<void> _resetAndLoadBeneficiaries() async {
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _offset = 0;
      _beneficiaries = [];
    });

    await _refreshCounts();
    await _loadMoreBeneficiaries();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    }
  }

  Future<void> _loadMoreBeneficiaries() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final page = await _beneficiaryRepo.getPaged(
        limit: _pageSize,
        offset: _offset,
        searchQuery: _searchQuery,
      );

      setState(() {
        _beneficiaries.addAll(page);
        _offset += page.length;
        _hasMore = page.length == _pageSize;
      });
    } catch (e) {
      developer.log('Error loading more beneficiaries: $e',
          name: 'BeneficiaryList');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = value;
      });
      _resetAndLoadBeneficiaries();
    });
  }

  Future<void> _syncBeneficiary(Beneficiary beneficiary) async {
    // Check internet connectivity first
    final connectivityService = context.read<ConnectivityService>();
    if (!connectivityService.isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Internet is off. Please connect to the internet to sync.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // CRITICAL: Check if ALL training sites are synced before allowing beneficiary sync
    try {
      final trainingSiteRepo = TrainingSiteRepository();
      final allSynced = await trainingSiteRepo.areAllTrainingSitesSynced();

      if (!allSynced) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot sync beneficiaries. Please sync all training sites first from the Conduct Training screen.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
    } catch (e) {
      developer.log('Error checking training sites sync status: $e',
          name: 'BeneficiaryList');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking training sites: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Additional check: Verify the specific training site for this beneficiary is synced
    if (beneficiary.trainingSite != null) {
      try {
        final trainingSiteRepo = TrainingSiteRepository();
        final trainingSite =
            await trainingSiteRepo.getById(beneficiary.trainingSite!);
        if (trainingSite == null) {
          throw Exception('Training site not found');
        }
        final trainingSiteLabel =
            trainingSite.trainingSite ?? 'ID ${beneficiary.trainingSite}';

        // Double-check if this specific training site is synced
        if (trainingSite.sIsSync == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cannot sync beneficiary. The training site "$trainingSiteLabel" is not synced yet.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      } catch (e) {
        developer.log('Error checking specific training site sync status: $e',
            name: 'BeneficiaryList');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Error: Training site ID ${beneficiary.trainingSite} not found.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    }

    try {
      developer.log(
          'Syncing beneficiary: ${beneficiary.firstName} ${beneficiary.lastName}',
          name: 'BeneficiaryList');

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
        );
      }

      // Convert beneficiary to JSON for sync
      final beneficiaryJson = beneficiary.toJsonForSync();

      // Sync to server using beneficiaryBeneSync
      final response = await _dataService.beneficiaryBeneSync(
        beneficiaries: [beneficiaryJson],
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (response.success) {
        developer.log('========================================',
            name: 'BeneficiaryList');
        developer.log('Beneficiary synced successfully',
            name: 'BeneficiaryList');
        developer.log('Response data: ${response.data}',
            name: 'BeneficiaryList');
        developer.log(
            'Current beneficiary - beneficiary_id: ${beneficiary.beneficiaryId}, offline_id: ${beneficiary.offlineId}, s_is_sync: ${beneficiary.sIsSync}',
            name: 'BeneficiaryList');

        // Try to extract beneficiary_id from response
        int? beneficiaryId;

        if (response.data != null) {
          // Response format: {success: true, action: created/updated, beneficiary_id: 94, message: ...}
          if (response.data!['beneficiary_id'] != null) {
            beneficiaryId = response.data!['beneficiary_id'] as int?;
            developer.log('Found beneficiary_id in response: $beneficiaryId',
                name: 'BeneficiaryList');
          } else if (response.data!['data'] is Map) {
            // Alternative format: {success: true, data: {beneficiary_id: 94}}
            final dataMap = response.data!['data'] as Map;
            beneficiaryId = dataMap['beneficiary_id'] as int?;
            developer.log('Found beneficiary_id in data map: $beneficiaryId',
                name: 'BeneficiaryList');
          } else if (response.data!['data'] is List) {
            // Alternative format: {success: true, data: [{beneficiary_id: 94}]}
            final mappings = response.data!['data'] as List;
            if (mappings.isNotEmpty) {
              final mapping = mappings.first;
              beneficiaryId = mapping['beneficiary_id'] as int?;
              developer.log('Found beneficiary_id in data list: $beneficiaryId',
                  name: 'BeneficiaryList');
            }
          }
        }

        // Always mark as synced after successful sync
        developer.log('Marking beneficiary as synced...',
            name: 'BeneficiaryList');

        if (beneficiary.offlineId != null &&
            beneficiaryId != null &&
            beneficiary.beneficiaryId == null) {
          // Has offline_id, got beneficiary_id from server, and doesn't already have beneficiary_id - update with server ID
          developer.log(
              'Updating offline_id ${beneficiary.offlineId} with server beneficiary_id: $beneficiaryId',
              name: 'BeneficiaryList');
          await _beneficiaryRepo.updateWithServerId(
              beneficiary.offlineId!, beneficiaryId);
        } else {
          // Already has beneficiary_id or no beneficiary_id in response - just mark as synced
          developer.log(
              'Marking as synced (beneficiary_id: ${beneficiary.beneficiaryId ?? beneficiaryId})',
              name: 'BeneficiaryList');
          final updatedBeneficiary = beneficiary.copyWith(
            sIsSync: 1,
            beneficiaryId: beneficiaryId ?? beneficiary.beneficiaryId,
          );
          await _beneficiaryRepo.update(updatedBeneficiary);
        }

        developer.log('Update complete, reloading beneficiaries...',
            name: 'BeneficiaryList');
        developer.log('========================================',
            name: 'BeneficiaryList');

        // Force a complete state refresh
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        // Reload beneficiaries
        await _resetAndLoadBeneficiaries();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Beneficiary synced successfully!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync failed: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error syncing beneficiary: $e', name: 'BeneficiaryList');

      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4EA),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Scroll to top FAB ──
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: FloatingActionButton(
              heroTag: 'scroll_top',
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: Colors.white,
              elevation: 2,
              child: const Icon(Icons.vertical_align_top,
                  color: Colors.black54, size: 22),
            ),
          ),

          // ── Add User FAB ──
          FloatingActionButton.extended(
            heroTag: 'add_user',
            onPressed: _hasInitialFetch
                ? () async {
                    await context.push(AppRoutes.beneficiary_registration);
                    // Reload the list after returning from registration
                    _resetAndLoadBeneficiaries();
                  }
                : null,
            backgroundColor:
                _hasInitialFetch ? const Color(0xFF4CAF50) : Colors.grey,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Beneficiary',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Green quarter-circle top-right ──
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(90),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.black87, size: 20),
                      ),
                      const Expanded(
                        child: Text(
                          'Beneficiary List',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.question_mark,
                            color: Colors.white, size: 12),
                      ),
                    ],
                  ),
                ),

                // ── Search Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      cursorColor: Colors.green,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search by Name or National ID...',
                        hintStyle:
                            TextStyle(color: Colors.black38, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: Colors.black38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Stats Row ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatSummary(
                          value: _totalCount.toString(),
                          label: 'TOTAL',
                          color: const Color(0xFF4CAF50)),
                      _divider(),
                      _StatSummary(
                          value: _syncedCount.toString(),
                          label: 'SYNCED',
                          color: const Color(0xFF4CAF50)),
                      _divider(),
                      _StatSummary(
                          value: _unsyncedCount.toString(),
                          label: 'OFFLINE',
                          color: const Color(0xFF4CAF50)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Warning banner if training sites are not all synced ──
                if (!_allTrainingSitesSynced && _unsyncedTrainingSitesCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF9800),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFF9800),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Training Sites Not Synced',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_unsyncedTrainingSitesCount training site${_unsyncedTrainingSitesCount > 1 ? 's' : ''} must be synced before beneficiaries can be synced.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_allTrainingSitesSynced && _unsyncedTrainingSitesCount > 0)
                  const SizedBox(height: 12),

                // ── Records loaded indicator ──
                if (_beneficiaries.isNotEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '• ${_beneficiaries.length}/$_matchingCount Records Loaded',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // ── List ──
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4CAF50)),
                          ),
                        )
                      : !_hasInitialFetch
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_download,
                                      size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Please fetch data from server first',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Use the sync option to download beneficiaries',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _beneficiaries.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_off,
                                          size: 64,
                                          color: Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No beneficiaries found',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  controller: _scrollController,
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 100),
                                  itemCount: _beneficiaries.length +
                                      (_isLoadingMore ? 1 : 0),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    if (index >= _beneficiaries.length) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12.0),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF4CAF50)),
                                          ),
                                        ),
                                      );
                                    }

                                    final beneficiary = _beneficiaries[index];
                                    return _BeneficiaryCard(
                                      beneficiary: beneficiary,
                                      onSync: () =>
                                          _syncBeneficiary(beneficiary),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.black12,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatSummary extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatSummary({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BeneficiaryCard extends StatelessWidget {
  final Beneficiary beneficiary;
  final VoidCallback onSync;

  const _BeneficiaryCard({
    required this.beneficiary,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final synced = beneficiary.sIsSync == 1;
    final name =
        '${beneficiary.firstName ?? ''} ${beneficiary.lastName ?? ''}'.trim();
    final nationalId = beneficiary.nationalId ?? 'N/A';

    // Check for missing required fields from BeneficiaryRegistrationScreen
    final List<String> missing = [];
    if (beneficiary.trainingSite == null) missing.add('Training Site');
    if (beneficiary.firstName == null || beneficiary.firstName!.isEmpty)
      missing.add('First Name');
    if (beneficiary.lastName == null || beneficiary.lastName!.isEmpty)
      missing.add('Last Name');
    if (beneficiary.mobileNo == null || beneficiary.mobileNo!.isEmpty)
      missing.add('Mobile Number');
    if (beneficiary.nationalId == null || beneficiary.nationalId!.isEmpty)
      missing.add('National ID');
    if (beneficiary.femalesBelow18 == null) missing.add('Females -18');
    if (beneficiary.femalesAbove18 == null) missing.add('Females +18');
    if (beneficiary.malesBelow18 == null) missing.add('Males -18');
    if (beneficiary.malesAbove18 == null) missing.add('Males +18');
    if (beneficiary.cookingMethod == null || beneficiary.cookingMethod!.isEmpty)
      missing.add('Cooking Method');
    if (beneficiary.language == null || beneficiary.language!.isEmpty)
      missing.add('Preferred Language');
    if (beneficiary.nationalIdAttachment == null ||
        beneficiary.nationalIdAttachment!.isEmpty)
      missing.add('National ID Image');
    if (beneficiary.signature == null || beneficiary.signature!.isEmpty)
      missing.add('Signature');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: synced ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
            width: 5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar ──
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF4CAF50),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),

                // ── Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name.isNotEmpty ? name : 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _SyncBadge(
                            synced: synced,
                            onTap: synced ? null : onSync,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (beneficiary.beneficiaryId != null)
                        Text(
                          'USER ID: ${beneficiary.beneficiaryId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      if (beneficiary.offlineId != null &&
                          beneficiary.beneficiaryId == null)
                        Text(
                          'OFFLINE ID: ${beneficiary.offlineId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'NATIONAL ID: $nationalId',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          // Edit Icon - show if NOT synced OR if there are missing fields
                          if (beneficiary.sIsSync == 0 || missing.isNotEmpty)
                            GestureDetector(
                              onTap: () async {
                                // Navigate to edit screen
                                // CRITICAL: Use prefixed format to prevent ID collision
                                // b_ prefix = beneficiary_id (server), o_ prefix = offline_id (local)
                                final idParam =
                                    beneficiary.beneficiaryId != null
                                        ? 'b_${beneficiary.beneficiaryId}'
                                        : 'o_${beneficiary.offlineId}';
                                await context.push(
                                  '${AppRoutes.beneficiary_registration}?beneficiaryId=$idParam',
                                );
                              },
                              child: const Icon(
                                Icons.edit_note,
                                color: Colors.black54,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Missing tags ──
            if (missing.isNotEmpty) ...[
              Divider(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  const Text(
                    '• MISSING:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  ...missing.map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SyncBadge extends StatelessWidget {
  final bool synced;
  final VoidCallback? onTap;

  const _SyncBadge({
    required this.synced,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: synced ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: synced ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              synced ? Icons.check_circle : Icons.sync,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              synced ? 'SYNCED' : 'NOT SYNCED',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
