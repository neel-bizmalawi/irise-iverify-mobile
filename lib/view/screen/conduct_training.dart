import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:irise/route/app_routes.dart';
import 'package:irise/view/screen/conduct_training_sheet.dart';
import 'package:irise/data/repositories/training_site_repository.dart';
import 'package:irise/data/models/training_site.dart';
import 'package:irise/data/services/data_service.dart';
import 'package:irise/core/services/connectivity_service.dart';
import 'package:irise/view/screen/_sync_badge.dart';
import 'package:map_launcher/map_launcher.dart';
import 'dart:developer' as developer;

// ── Move this function to TOP LEVEL (outside all classes) ──
Future<bool?> showConductTrainingSheet(
  BuildContext context,
  String siteName,
  String trainingPointId, // Changed to String to support prefixed IDs (t_123 or o_456)
) async {
  // Verify data has been fetched and persisted before allowing training
  try {
    final dataService = DataService();
    final verificationResult = await dataService.verifyDataPersistence();
    
    if (!verificationResult.success || verificationResult.data == false) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(verificationResult.message ?? 'Please sync data from the dashboard first'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return null;
    }
  } catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to verify data: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    return null;
  }

  // Data is verified, show the training sheet
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: false,
    builder: (_) => ConductTrainingSheet(
      siteName: siteName,
      trainingPointId: trainingPointId,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class ConductTrainingScreen extends StatefulWidget {
  const ConductTrainingScreen({super.key});

  @override
  State<ConductTrainingScreen> createState() => _ConductTrainingScreenState();
}

class _ConductTrainingScreenState extends State<ConductTrainingScreen> {
  final TrainingSiteRepository _repository = TrainingSiteRepository();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<TrainingSite> _trainingSites = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTrainingSites();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen becomes visible again
    // This ensures fresh data after syncing from dashboard
    if (mounted) {
      _loadTrainingSites();
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 10 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 10 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  Future<void> _loadTrainingSites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      developer.log('========================================', name: 'ConductTraining');
      developer.log('LOADING TRAINING SITES', name: 'ConductTraining');
      developer.log('========================================', name: 'ConductTraining');
      
      final sites = await _repository.getAll();
      
      developer.log('Loaded ${sites.length} training sites from repository', name: 'ConductTraining');
      
      // Log first 5 for debugging
      final sampleCount = sites.length > 5 ? 5 : sites.length;
      for (int i = 0; i < sampleCount; i++) {
        final site = sites[i];
        developer.log('  Site ${i + 1}: ${site.trainingSite} (training_point_id: ${site.trainingPointId}, offline_id: ${site.offlineId}, s_is_sync: ${site.sIsSync})', name: 'ConductTraining');
      }
      
      setState(() {
        _trainingSites = sites;
      });
      
      developer.log('State updated with ${_trainingSites.length} training sites', name: 'ConductTraining');
      developer.log('========================================', name: 'ConductTraining');
    } catch (e) {
      developer.log('Error loading training sites: $e', name: 'ConductTraining');
      _showErrorSnackBar('Error loading training sites: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TrainingSite> get _filteredSites {
    final filtered = _trainingSites
        .where((site) => 
            (site.trainingSite ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (site.district ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (site.traditionalAuthority ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    
    // Sort: unsynced sites first, then synced sites by training_point_id in descending order
    filtered.sort((a, b) {
      // If one is unsynced and the other is synced, unsynced comes first
      if (a.sIsSync == 0 && b.sIsSync == 1) return -1;
      if (a.sIsSync == 1 && b.sIsSync == 0) return 1;
      
      // If both are unsynced, sort by offline_id in descending order (newer items first)
      if (a.sIsSync == 0 && b.sIsSync == 0) {
        final aId = a.offlineId ?? 0;
        final bId = b.offlineId ?? 0;
        return bId.compareTo(aId); // Descending order
      }
      
      // If both are synced, sort by training_point_id in descending order
      final aId = a.trainingPointId ?? 0;
      final bId = b.trainingPointId ?? 0;
      return bId.compareTo(aId); // Descending order
    });
    
    return filtered;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF4CAF50),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Training Sites Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add training sites from Training Point\nIdentification to see them here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingSitesList() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadTrainingSites,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: _filteredSites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final site = _filteredSites[index];
              return _TrainingCard(trainingSite: site);
            },
          ),
        ),
        // ── Records loaded pill (bottom position when scrolled) ──
        if (_isScrolled)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '• ${_filteredSites.length}/${_trainingSites.length} Training Sites',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4EA),
      floatingActionButton: FloatingActionButton(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
                        onTap: () => context.go(AppRoutes.modules),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.black87, size: 20),
                      ),
                      const Expanded(
                        child: Text(
                          'Conduct Training',
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
                          color: Colors.black.withValues(alpha: 0.05),
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
                        hintText: 'Search training sites...',
                        hintStyle:
                            TextStyle(color: Colors.black38, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.black38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Records loaded pill (top position when not scrolled) ──
                if (!_isScrolled)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '• ${_filteredSites.length}/${_trainingSites.length} Training Sites',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),

                // ── Content ──
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4CAF50),
                          ),
                        )
                      : _trainingSites.isEmpty
                          ? _buildEmptyState()
                          : _buildTrainingSitesList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TrainingCard extends StatefulWidget {
  final TrainingSite trainingSite;

  const _TrainingCard({required this.trainingSite});

  @override
  State<_TrainingCard> createState() => _TrainingCardState();
}

class _TrainingCardState extends State<_TrainingCard> {
  late TrainingSite _currentSite;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _currentSite = widget.trainingSite;
  }

  @override
  void didUpdateWidget(_TrainingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trainingSite != widget.trainingSite) {
      _currentSite = widget.trainingSite;
    }
  }

  Future<void> _syncSingleSite() async {
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
    
    if (_currentSite.sIsSync == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This training site is already synced'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      return;
    }

    // Verify data has been fetched and persisted before allowing sync
    try {
      final dataService = DataService();
      final verificationResult = await dataService.verifyDataPersistence();
      
      if (!verificationResult.success || verificationResult.data == false) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verificationResult.message ?? 'Please sync data from the dashboard first'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to verify data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        final dataService = DataService();
        
        final siteData = _currentSite.toApiJson();
        
        // IMPORTANT: Only include training_point_id for UPDATES (not for initial creation)
        // A training site is an UPDATE if it has a training_point_id (was previously synced to server)
        // A training site is a CREATE if it only has offline_id (never synced before)
        if (_currentSite.trainingPointId != null) {
          // This is an update - include training_point_id so server knows which record to update
          siteData['training_point_id'] = _currentSite.trainingPointId;
          developer.log('Syncing UPDATE for training site with training_point_id: ${_currentSite.trainingPointId}', name: 'ConductTraining');
        } else {
          // This is a new creation - include created_date
          if (_currentSite.createdDate != null) {
            siteData['created_date'] = _currentSite.createdDate;
          }
          developer.log('Syncing NEW training site with offline_id: ${_currentSite.offlineId}', name: 'ConductTraining');
        }
        
        // Include training completion fields if they exist
        if (_currentSite.conductTrainingDate != null) {
          siteData['conduct_training_date'] = _currentSite.conductTrainingDate;
        }
        if (_currentSite.numberOfPeoplePresent != null) {
          siteData['number_of_people_present'] = _currentSite.numberOfPeoplePresent;
        }
        
        developer.log('Sync payload: ${siteData.toString()}', name: 'ConductTraining');
        
        final response = await dataService.syncTrainingSites([siteData]);
        
        if (response.success) {
          // Extract training_point_id from mapping if available
          int? serverTrainingPointId;
          if (response.data?.mapping != null && response.data!.mapping!.isNotEmpty) {
            final mapping = response.data!.mapping!.first;
            serverTrainingPointId = mapping['training_point_id'] as int?;
            developer.log('Server assigned training_point_id: $serverTrainingPointId', name: 'ConductTraining');
          }
          
          final repository = TrainingSiteRepository();
          
          // Update local record with server ID and mark as synced
          final updatedSite = _currentSite.copyWith(
            sIsSync: 1,
            trainingPointId: serverTrainingPointId ?? _currentSite.trainingPointId,
          );
          
          await repository.update(updatedSite);
          
          setState(() {
            _currentSite = updatedSite;
            _isSyncing = false;
          });
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(serverTrainingPointId != null 
                  ? 'Training site synced successfully! ID: $serverTrainingPointId'
                  : 'Training site synced successfully!'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 2),
            ),
          );
          
          final state = context.findAncestorStateOfType<_ConductTrainingScreenState>();
          state?._loadTrainingSites();
          return; // Success, exit retry loop
        } else {
          // Check if error is due to concurrency/conflict
          if (_isConflictError(response.message)) {
            retryCount++;
            if (retryCount < maxRetries) {
              // Wait before retrying with exponential backoff
              await Future.delayed(retryDelay * retryCount);
              continue; // Retry
            }
          }
          
          // Non-retryable error or max retries reached
          setState(() {
            _isSyncing = false;
          });
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync failed: ${response.message ?? "Unknown error"}${retryCount > 0 ? " (after $retryCount retries)" : ""}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      } catch (e) {
        retryCount++;
        if (retryCount < maxRetries) {
          // Wait before retrying
          await Future.delayed(retryDelay * retryCount);
          continue; // Retry
        }
        
        setState(() {
          _isSyncing = false;
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing: $e (after $retryCount retries)'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }
  }

  // Check if error is due to concurrency/conflict
  bool _isConflictError(String? message) {
    if (message == null) return false;
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains('conflict') ||
           lowerMessage.contains('concurrent') ||
           lowerMessage.contains('duplicate') ||
           lowerMessage.contains('already exists') ||
           lowerMessage.contains('timeout') ||
           lowerMessage.contains('locked');
  }

  Future<void> _openInMap() async {
    final latitude = _currentSite.latitude;
    final longitude = _currentSite.longitude;
    
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS location not available for this training site'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final availableMaps = await MapLauncher.installedMaps;
      
      if (availableMaps.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No map applications found on this device'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final coords = Coords(latitude, longitude);
      final title = _currentSite.trainingSite ?? 'Training Site';
      
      // If only one map app is available, open it directly
      if (availableMaps.length == 1) {
        await availableMaps.first.showMarker(
          coords: coords,
          title: title,
          description: '${_currentSite.district ?? ''} • ${_currentSite.traditionalAuthority ?? ''}',
        );
      } else {
        // Show a dialog to choose which map app to use
        if (!mounted) return;
        await showModalBottomSheet(
          context: context,
          useSafeArea: false,
          builder: (BuildContext context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Open in Maps',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...availableMaps.map((map) {
                    return ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        map.showMarker(
                          coords: coords,
                          title: title,
                          description: '${_currentSite.district ?? ''} • ${_currentSite.traditionalAuthority ?? ''}',
                        );
                      },
                      title: Text(map.mapName),
                      leading: Image.asset(
                        map.icon,
                        width: 30,
                        height: 30,
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening map: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _hasEmptyFields() {
    return _currentSite.trainingSite == null || _currentSite.trainingSite!.isEmpty ||
           _currentSite.district == null || _currentSite.district!.isEmpty ||
           _currentSite.villageHeadName == null || _currentSite.villageHeadName!.isEmpty ||
           _currentSite.gvhName == null || _currentSite.gvhName!.isEmpty ||
           _currentSite.traditionalAuthority == null || _currentSite.traditionalAuthority!.isEmpty ||
           _currentSite.houseHoldsCount == null ||
           _currentSite.cookstovesCount == null ||
           _currentSite.houseHoldRadius == null ||
           _currentSite.totalPeople == null ||
           _currentSite.latitude == null ||
           _currentSite.longitude == null;
  }

  void _editTrainingSite() {
    context.push(
      '${AppRoutes.training_point_identification}?trainingPointId=${_currentSite.trainingPointId ?? _currentSite.offlineId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool synced = _currentSite.sIsSync == 1;
    final bool hasEmptyFields = _hasEmptyFields();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: synced ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name + Edit Icon + Sync Badge ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _currentSite.trainingSite ?? 'Unnamed Site',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (hasEmptyFields)
                  GestureDetector(
                    onTap: _editTrainingSite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                SyncBadge(
                  synced: synced,
                  isSyncing: _isSyncing,
                  onSyncTap: _syncSingleSite,
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            // ── Location info ──
            Text(
              '${_currentSite.district ?? 'Unknown District'} • ${_currentSite.traditionalAuthority ?? 'Unknown Authority'}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),

            // ── Stats row ──
            Row(
              children: [
                _StatChip(
                  icon: Icons.kitchen,
                  value: _currentSite.cookstovesCount?.toString() ?? '00',
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.directions_car_outlined,
                  value: (_currentSite.roadAccess == 'yes') ? 'YES' : 'NO',
                  isRoad: true,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.people_outline,
                  value: _currentSite.numberOfPeoplePresent?.toString() ?? '--',
                ),
                Spacer(),
                Text(
              'Training Done: ${(_currentSite.numberOfPeoplePresent != null) ? 'YES' : 'NO'}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
              ],
            ),
            // const SizedBox(height: 6),
            
            // ── Training Done Status ──
            
            const SizedBox(height: 8),

            // ── Action buttons ──
            Row(
              children: [
                // Only show "Conduct Training" button if training hasn't been completed
                if (_currentSite.numberOfPeoplePresent == null) ...[
                  Expanded(
                    child: _ActionButton(
                      label: 'Conduct Training',
                      icon: Icons.play_arrow,
                      filled: true,
                      synced: synced,
                      onTap: () async {
                        // CRITICAL: Use prefixed ID to prevent collision
                        // t_ prefix = trainingPointId (server), o_ prefix = offline_id (local)
                        final idParam = _currentSite.trainingPointId != null
                            ? 't_${_currentSite.trainingPointId}'
                            : 'o_${_currentSite.offlineId}';
                        
                        final result = await showConductTrainingSheet(
                          context,
                          _currentSite.trainingSite ?? 'Unnamed Site',
                          idParam,
                        );
                        
                        // If training was completed successfully, refresh the training site
                        if (result == true) {
                          final repository = TrainingSiteRepository();
                          
                          // Use specific lookup method based on ID type
                          TrainingSite? updatedSite;
                          if (_currentSite.trainingPointId != null) {
                            updatedSite = await repository.getByTrainingPointId(_currentSite.trainingPointId!);
                          } else if (_currentSite.offlineId != null) {
                            updatedSite = await repository.getByOfflineId(_currentSite.offlineId!);
                          }
                          
                          if (updatedSite != null && mounted) {
                            setState(() {
                              _currentSite = updatedSite!; // Add ! to assert non-null
                            });
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _ActionButton(
                    label: 'On Map',
                    icon: Icons.navigation_outlined,
                    filled: false,
                    synced: synced,
                    onTap: _openInMap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isRoad;

  const _StatChip({
    required this.icon,
    required this.value,
    this.isRoad = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool synced;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.synced,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF4CAF50);
    final inactiveColor = const Color(0xFFFF9800);
    final color = synced ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: filled ? null : Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: filled ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
