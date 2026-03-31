import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:irise/route/app_routes.dart';
import 'package:irise/data/repositories/beneficiary_repository.dart';
import 'package:irise/data/models/beneficiary.dart';
import 'package:irise/data/services/data_service.dart';
import 'package:irise/core/services/connectivity_service.dart';
import 'dart:developer' as developer;

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final BeneficiaryRepository _beneficiaryRepo = BeneficiaryRepository();
  final DataService _dataService = DataService();
  
  bool _showScrollToTop = false;
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  List<Beneficiary> _households = [];
  List<Beneficiary> _filteredHouseholds = [];

  @override
  void initState() {
    super.initState();
    _loadHouseholds();
    _searchController.addListener(_filterHouseholds);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this screen (but not on first load)
    if (_hasLoadedOnce && ModalRoute.of(context)?.isCurrent == true) {
      developer.log('Screen became active, reloading households...', name: 'HouseholdScreen');
      _loadHouseholds();
    }
  }

  Future<void> _loadHouseholds() async {
    setState(() => _isLoading = true);
    try {
      developer.log('Loading households from database...', name: 'HouseholdScreen');
      final beneficiaries = await _beneficiaryRepo.getAll();
      developer.log('Loaded ${beneficiaries.length} households', name: 'HouseholdScreen');
      
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
      
      setState(() {
        _households = beneficiaries;
        _filteredHouseholds = beneficiaries;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
      
      // Log first few for debugging
      if (beneficiaries.isNotEmpty) {
        for (var i = 0; i < (beneficiaries.length > 3 ? 3 : beneficiaries.length); i++) {
          final b = beneficiaries[i];
          developer.log(
            'Household $i: ${b.firstName} ${b.lastName}, offline_id: ${b.offlineId}, beneficiary_id: ${b.beneficiaryId}, synced: ${b.sIsSync}',
            name: 'HouseholdScreen',
          );
        }
      }
    } catch (e) {
      developer.log('Error loading households: $e', name: 'HouseholdScreen');
      setState(() {
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterHouseholds() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredHouseholds = _households;
      } else {
        _filteredHouseholds = _households.where((household) {
          final firstName = (household.firstName ?? '').toLowerCase();
          final lastName = (household.lastName ?? '').toLowerCase();
          final fullName = '$firstName $lastName'.trim();
          final nationalId = (household.nationalId ?? '').toLowerCase();
          return fullName.contains(query) || nationalId.contains(query);
        }).toList();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 200 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _syncHousehold(Beneficiary household) async {
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
      developer.log('Syncing household: ${household.firstName} ${household.lastName}', name: 'HouseholdScreen');
      
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
      
      // Reload complete beneficiary data from database using beneficiary_id or offline_id
      // IMPORTANT: Use beneficiary_id if it exists, otherwise use offline_id
      final lookupId = household.beneficiaryId ?? household.offlineId;
      if (lookupId == null) {
        throw Exception('Beneficiary has no beneficiary_id or offline_id');
      }
      
      developer.log('Reloading beneficiary for sync using ID: $lookupId (beneficiary_id: ${household.beneficiaryId}, offline_id: ${household.offlineId})', name: 'HouseholdScreen');
      
      final reloadedBeneficiary = await _beneficiaryRepo.getById(lookupId);
      if (reloadedBeneficiary == null) {
        throw Exception('Failed to reload beneficiary data for ID: $lookupId');
      }
      
      developer.log('Reloaded beneficiary - beneficiary_id: ${reloadedBeneficiary.beneficiaryId}, offline_id: ${reloadedBeneficiary.offlineId}', name: 'HouseholdScreen');
      
      // Convert beneficiary to JSON for sync (send complete data from local DB)
      final beneficiaryJson = reloadedBeneficiary.toJsonForSync();
      
      developer.log('Beneficiary sync payload (complete data from local DB): $beneficiaryJson', name: 'HouseholdScreen');
      
      // Sync to server using beneficiaryBeneSync
      final response = await _dataService.beneficiaryBeneSync(
        beneficiaries: [beneficiaryJson],
      );
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (response.success) {
        developer.log('========================================', name: 'HouseholdScreen');
        developer.log('Household synced successfully', name: 'HouseholdScreen');
        developer.log('Response data: ${response.data}', name: 'HouseholdScreen');
        developer.log('Current household - beneficiary_id: ${household.beneficiaryId}, offline_id: ${household.offlineId}, s_is_sync: ${household.sIsSync}', name: 'HouseholdScreen');
        
        // Try to extract beneficiary_id from response
        int? beneficiaryId;
        
        if (response.data != null) {
          // Response format: {success: true, action: updated, beneficiary_id: 94, message: ...}
          if (response.data!['beneficiary_id'] != null) {
            beneficiaryId = response.data!['beneficiary_id'] as int?;
            developer.log('Found beneficiary_id in response: $beneficiaryId', name: 'HouseholdScreen');
          } else if (response.data!['data'] is Map) {
            // Alternative format: {success: true, data: {beneficiary_id: 94}}
            final dataMap = response.data!['data'] as Map;
            beneficiaryId = dataMap['beneficiary_id'] as int?;
            developer.log('Found beneficiary_id in data map: $beneficiaryId', name: 'HouseholdScreen');
          } else if (response.data!['data'] is List) {
            // Alternative format: {success: true, data: [{beneficiary_id: 94}]}
            final mappings = response.data!['data'] as List;
            if (mappings.isNotEmpty) {
              final mapping = mappings.first;
              beneficiaryId = mapping['beneficiary_id'] as int?;
              developer.log('Found beneficiary_id in data list: $beneficiaryId', name: 'HouseholdScreen');
            }
          }
        }
        
        // Always mark as synced after successful sync
        developer.log('Marking household as synced...', name: 'HouseholdScreen');
        
        if (household.offlineId != null && beneficiaryId != null && household.beneficiaryId == null) {
          // Has offline_id, got beneficiary_id from server, and doesn't already have beneficiary_id - update with server ID
          developer.log('Updating offline_id ${household.offlineId} with server beneficiary_id: $beneficiaryId', name: 'HouseholdScreen');
          await _beneficiaryRepo.updateWithServerId(household.offlineId!, beneficiaryId);
        } else {
          // Already has beneficiary_id or no beneficiary_id in response - just mark as synced
          developer.log('Marking as synced (beneficiary_id: ${household.beneficiaryId ?? beneficiaryId})', name: 'HouseholdScreen');
          final updatedHousehold = household.copyWith(
            sIsSync: 1,
            beneficiaryId: beneficiaryId ?? household.beneficiaryId,
          );
          await _beneficiaryRepo.update(updatedHousehold);
        }
        
        developer.log('Update complete, reloading households...', name: 'HouseholdScreen');
        developer.log('========================================', name: 'HouseholdScreen');
        
        // Reload households
        await _loadHouseholds();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Household synced successfully!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } else {
        // Extract user-friendly error message from response
        String errorMessage = response.message ?? 'Sync failed';
        
        // Log the full error for debugging
        developer.log('Sync failed with message: $errorMessage', name: 'HouseholdScreen');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error syncing household: $e', name: 'HouseholdScreen');
      
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Extract user-friendly error message
      String errorMessage = 'Error syncing household';
      
      // Try to extract message from error string if it contains JSON-like structure
      final errorStr = e.toString();
      if (errorStr.contains('message')) {
        // This might be a structured error, try to extract the message
        errorMessage = errorStr;
      } else {
        errorMessage = 'Error syncing: $errorStr';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4EA),
      body: Stack(
        children: [
          // Green quarter-circle top-right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 90,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(120),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
                      ),
                      const Expanded(
                        child: Text(
                          'House Hold Distribution',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _loadHouseholds,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sync, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      cursorColor: Colors.green,
                      decoration: InputDecoration(
                        hintText: 'Search by Name or National ID...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Records Count Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_filteredHouseholds.length}/${_households.length} Records Loaded',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Household List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                          ),
                        )
                      : _filteredHouseholds.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No households found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredHouseholds.length,
                              itemBuilder: (context, index) {
                                final household = _filteredHouseholds[index];
                                final name = '${household.firstName ?? ''} ${household.lastName ?? ''}'.trim();
                                final nationalId = household.nationalId ?? 'N/A';
                                final isSynced = household.sIsSync == 1;
                                final householdId = household.beneficiaryId?.toString() ?? household.offlineId?.toString() ?? nationalId;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _HouseholdTile(
                                    name: name.isNotEmpty ? name : 'Unknown',
                                    nationalId: nationalId,
                                    isSynced: isSynced,
                                    household: household,
                                    onTap: () async {
                                      await context.push('${AppRoutes.editHousehold}?householdId=$householdId');
                                      // Reload households after returning from edit screen
                                      developer.log('Returned from EditHouseholdScreen, reloading households...', name: 'HouseholdScreen');
                                      await _loadHouseholds();
                                    },
                                    onSync: () => _syncHousehold(household),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),

          // Scroll to Top Button
          if (_showScrollToTop)
            Positioned(
              bottom: 20,
              left: 20,
              child: GestureDetector(
                onTap: _scrollToTop,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HouseholdTile extends StatelessWidget {
  final String name;
  final String nationalId;
  final bool isSynced;
  final Beneficiary household;
  final VoidCallback onTap;
  final VoidCallback onSync;

  const _HouseholdTile({
    required this.name,
    required this.nationalId,
    required this.isSynced,
    required this.household,
    required this.onTap,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    // Check for missing household data - only fields from EditHouseholdScreen
    final List<String> missing = [];
    if (household.deviceSerialNo == null || household.deviceSerialNo!.isEmpty) missing.add('Device Serial No');
    if (household.latitude == null || household.longitude == null) missing.add('GPS Location');
    if (household.housePic == null || household.housePic!.isEmpty) missing.add('House Image');
    if (household.cookstovePic == null || household.cookstovePic!.isEmpty) missing.add('Cookstove Image');
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isSynced ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSynced 
                      ? const Color(0xFFE8F5E9) 
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSynced 
                      ? Icons.cloud : Icons.cloud_off,
                  color: isSynced 
                      ? const Color(0xFF4CAF50) 
                      : const Color(0xFFFF9800),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Name and National ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NATIONAL ID: $nationalId',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Sync Status Badge and Edit Icon
              Column(
                children: [
                  GestureDetector(
                    onTap: isSynced ? null : onSync,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSynced 
                            ? const Color(0xFFE8F5E9) 
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSynced ? Icons.cloud_done : Icons.sync,
                            size: 14,
                            color: isSynced 
                                ? const Color(0xFF4CAF50) 
                                : const Color(0xFFFF9800),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSynced ? 'SYNCED' : 'NOT SYNCED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSynced 
                                  ? const Color(0xFF4CAF50) 
                                  : const Color(0xFFFF9800),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Edit Icon (only show if NOT synced with server)
                  if (household.sIsSync == 0)
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Color(0xFF4CAF50),
                          size: 15,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Missing tags
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
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
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
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
    );
  }
}
