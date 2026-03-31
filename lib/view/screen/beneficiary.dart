import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:irise/route/app_routes.dart';
import 'package:irise/data/repositories/beneficiary_repository.dart';
import 'package:irise/data/models/beneficiary.dart';
import 'package:irise/data/services/data_service.dart';
import 'package:irise/core/services/connectivity_service.dart';
import 'dart:developer' as developer;

class BeneficiaryListScreen extends StatefulWidget {
  const BeneficiaryListScreen({super.key});

  @override
  State<BeneficiaryListScreen> createState() => _BeneficiaryListScreenState();
}

class _BeneficiaryListScreenState extends State<BeneficiaryListScreen> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _beneficiaryRepo = BeneficiaryRepository();
  final _dataService = DataService();
  
  String _searchQuery = '';
  List<Beneficiary> _beneficiaries = [];
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  bool _hasInitialFetch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialFetch();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload when app comes to foreground
    if (state == AppLifecycleState.resumed && _hasLoadedOnce) {
      developer.log('App resumed, reloading beneficiaries...', name: 'BeneficiaryList');
      _loadBeneficiaries();
    }
  }
  
  Future<void> _checkInitialFetch() async {
    setState(() => _isLoading = true);
    try {
      // Check if there are any beneficiaries in the database
      final beneficiaries = await _beneficiaryRepo.getAll();
      setState(() {
        _hasInitialFetch = beneficiaries.isNotEmpty;
        _isLoading = false;
      });
      
      if (_hasInitialFetch) {
        _loadBeneficiaries();
      }
    } catch (e) {
      developer.log('Error checking initial fetch: $e', name: 'BeneficiaryList');
      setState(() => _isLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always reload data when this screen becomes the current route
    // This ensures we pick up any changes made in other screens (like EditHouseholdScreen)
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && _hasLoadedOnce) {
      developer.log('Screen became active, reloading beneficiaries...', name: 'BeneficiaryList');
      // Use Future.microtask to avoid calling setState during build
      Future.microtask(() => _loadBeneficiaries());
    }
  }

  Future<void> _loadBeneficiaries() async {
    setState(() => _isLoading = true);
    try {
      developer.log('Loading beneficiaries from database...', name: 'BeneficiaryList');
      final beneficiaries = await _beneficiaryRepo.getAll();
      developer.log('Loaded ${beneficiaries.length} beneficiaries', name: 'BeneficiaryList');
      
      // Sort: Not Synced (s_is_sync = 0) first, then Synced (s_is_sync = 1)
      // Within NOT SYNCED group: sort by offline_id descending (newest first)
      // Within SYNCED group: sort by beneficiary_id descending (newest first)
      beneficiaries.sort((a, b) {
        final aSync = a.sIsSync ?? 0;
        final bSync = b.sIsSync ?? 0;
        
        // If sync status is different, unsynced (0) comes first
        if (aSync != bSync) {
          return aSync.compareTo(bSync);
        }
        
        // If both are NOT SYNCED (s_is_sync = 0), sort by offline_id descending
        if (aSync == 0 && bSync == 0) {
          final aOfflineId = a.offlineId ?? 0;
          final bOfflineId = b.offlineId ?? 0;
          return bOfflineId.compareTo(aOfflineId); // Higher offline_id first (newest)
        }
        
        // If both are SYNCED (s_is_sync = 1), sort by beneficiary_id descending
        final aBeneficiaryId = a.beneficiaryId ?? 0;
        final bBeneficiaryId = b.beneficiaryId ?? 0;
        return bBeneficiaryId.compareTo(aBeneficiaryId); // Higher beneficiary_id first (newest)
      });
      
      // Log first few beneficiaries for debugging
      if (beneficiaries.isNotEmpty) {
        developer.log('========================================', name: 'BeneficiaryList');
        developer.log('Top beneficiaries after sorting (NOT SYNCED by offline_id DESC, then SYNCED by beneficiary_id DESC):', name: 'BeneficiaryList');
        for (var i = 0; i < (beneficiaries.length > 5 ? 5 : beneficiaries.length); i++) {
          final b = beneficiaries[i];
          developer.log(
            '[$i] ${b.firstName} ${b.lastName} | offline_id: ${b.offlineId} | beneficiary_id: ${b.beneficiaryId} | Synced: ${b.sIsSync == 1 ? 'YES' : 'NO'}',
            name: 'BeneficiaryList',
          );
        }
        developer.log('========================================', name: 'BeneficiaryList');
      }
      
      setState(() {
        _beneficiaries = beneficiaries;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      developer.log('Error loading beneficiaries: $e', name: 'BeneficiaryList');
      setState(() {
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    }
  }

  List<Beneficiary> get _filtered => _beneficiaries
      .where((e) =>
          (e.firstName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (e.lastName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (e.nationalId ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  int get _totalCount => _beneficiaries.length;
  int get _syncedCount => _beneficiaries.where((b) => b.sIsSync == 1).length;
  int get _unsyncedCount => _beneficiaries.where((b) => b.sIsSync == 0).length;

  Future<void> _syncBeneficiary(Beneficiary beneficiary) async {
    // Check internet connectivity first
    final connectivityService = context.read<ConnectivityService>();
    if (!connectivityService.isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internet is off. Please connect to the internet to sync.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    try {
      developer.log('Syncing beneficiary: ${beneficiary.firstName} ${beneficiary.lastName}', name: 'BeneficiaryList');
      
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
        developer.log('========================================', name: 'BeneficiaryList');
        developer.log('Beneficiary synced successfully', name: 'BeneficiaryList');
        developer.log('Response data: ${response.data}', name: 'BeneficiaryList');
        developer.log('Current beneficiary - beneficiary_id: ${beneficiary.beneficiaryId}, offline_id: ${beneficiary.offlineId}, s_is_sync: ${beneficiary.sIsSync}', name: 'BeneficiaryList');
        
        // Try to extract beneficiary_id from response
        int? beneficiaryId;
        
        if (response.data != null) {
          // Response format: {success: true, action: created/updated, beneficiary_id: 94, message: ...}
          if (response.data!['beneficiary_id'] != null) {
            beneficiaryId = response.data!['beneficiary_id'] as int?;
            developer.log('Found beneficiary_id in response: $beneficiaryId', name: 'BeneficiaryList');
          } else if (response.data!['data'] is Map) {
            // Alternative format: {success: true, data: {beneficiary_id: 94}}
            final dataMap = response.data!['data'] as Map;
            beneficiaryId = dataMap['beneficiary_id'] as int?;
            developer.log('Found beneficiary_id in data map: $beneficiaryId', name: 'BeneficiaryList');
          } else if (response.data!['data'] is List) {
            // Alternative format: {success: true, data: [{beneficiary_id: 94}]}
            final mappings = response.data!['data'] as List;
            if (mappings.isNotEmpty) {
              final mapping = mappings.first;
              beneficiaryId = mapping['beneficiary_id'] as int?;
              developer.log('Found beneficiary_id in data list: $beneficiaryId', name: 'BeneficiaryList');
            }
          }
        }
        
        // Always mark as synced after successful sync
        developer.log('Marking beneficiary as synced...', name: 'BeneficiaryList');
        
        if (beneficiary.offlineId != null && beneficiaryId != null && beneficiary.beneficiaryId == null) {
          // Has offline_id, got beneficiary_id from server, and doesn't already have beneficiary_id - update with server ID
          developer.log('Updating offline_id ${beneficiary.offlineId} with server beneficiary_id: $beneficiaryId', name: 'BeneficiaryList');
          await _beneficiaryRepo.updateWithServerId(beneficiary.offlineId!, beneficiaryId);
        } else {
          // Already has beneficiary_id or no beneficiary_id in response - just mark as synced
          developer.log('Marking as synced (beneficiary_id: ${beneficiary.beneficiaryId ?? beneficiaryId})', name: 'BeneficiaryList');
          final updatedBeneficiary = beneficiary.copyWith(
            sIsSync: 1,
            beneficiaryId: beneficiaryId ?? beneficiary.beneficiaryId,
          );
          await _beneficiaryRepo.update(updatedBeneficiary);
        }
        
        developer.log('Update complete, reloading beneficiaries...', name: 'BeneficiaryList');
        developer.log('========================================', name: 'BeneficiaryList');
        
        // Force a complete state refresh
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }
        
        // Reload beneficiaries
        await _loadBeneficiaries();
        
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
    _searchController.dispose();
    _scrollController.dispose();
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
            onPressed: _hasInitialFetch ? () async {
              await context.push(AppRoutes.beneficiary_registration);
              // Reload the list after returning from registration
              _loadBeneficiaries();
            } : null,
            backgroundColor: _hasInitialFetch ? const Color(0xFF4CAF50) : Colors.grey,
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
                        child: const Icon(Icons.question_mark, color: Colors.white, size: 12),
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
                      onChanged: (val) => setState(() => _searchQuery = val),
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
                
                // ── Records loaded indicator ──
                if (_filtered.isNotEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '• ${_filtered.length}/${_totalCount} Records Loaded',
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
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                          ),
                        )
                      : !_hasInitialFetch
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_download, size: 64, color: Colors.grey.shade300),
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
                          : _filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off, size: 64, color: Colors.grey.shade300),
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
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final beneficiary = _filtered[index];
                                return _BeneficiaryCard(
                                  beneficiary: beneficiary,
                                  onSync: () => _syncBeneficiary(beneficiary),
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
    final name = '${beneficiary.firstName ?? ''} ${beneficiary.lastName ?? ''}'.trim();
    final nationalId = beneficiary.nationalId ?? 'N/A';
    
    // Check for missing required fields from BeneficiaryRegistrationScreen
    final List<String> missing = [];
    if (beneficiary.trainingSite == null || beneficiary.trainingSite!.isEmpty) missing.add('Training Site');
    if (beneficiary.firstName == null || beneficiary.firstName!.isEmpty) missing.add('First Name');
    if (beneficiary.lastName == null || beneficiary.lastName!.isEmpty) missing.add('Last Name');
    if (beneficiary.mobileNo == null || beneficiary.mobileNo!.isEmpty) missing.add('Mobile Number');
    if (beneficiary.nationalId == null || beneficiary.nationalId!.isEmpty) missing.add('National ID');
    if (beneficiary.femalesBelow18 == null) missing.add('Females -18');
    if (beneficiary.femalesAbove18 == null) missing.add('Females +18');
    if (beneficiary.malesBelow18 == null) missing.add('Males -18');
    if (beneficiary.malesAbove18 == null) missing.add('Males +18');
    if (beneficiary.cookingMethod == null || beneficiary.cookingMethod!.isEmpty) missing.add('Cooking Method');
    if (beneficiary.language == null || beneficiary.language!.isEmpty) missing.add('Preferred Language');
    if (beneficiary.nationalIdAttachment == null || beneficiary.nationalIdAttachment!.isEmpty) missing.add('National ID Image');
    if (beneficiary.signature == null || beneficiary.signature!.isEmpty) missing.add('Signature');

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
                        if (beneficiary.offlineId != null && beneficiary.beneficiaryId == null)
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
                            // Edit Icon - only show if NOT synced with server
                            if (beneficiary.sIsSync == 0)
                              GestureDetector(
                                onTap: () async {
                                  // Navigate to edit screen
                                  await context.push(
                                    '${AppRoutes.beneficiary_registration}?beneficiaryId=${beneficiary.beneficiaryId ?? beneficiary.offlineId}',
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
