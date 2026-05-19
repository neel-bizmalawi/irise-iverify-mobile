import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/monitoring.dart';
import '../../data/repositories/monitoring_repository.dart';
import '../../route/app_routes.dart';
import 'dart:developer' as developer;

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final MonitoringRepository _repository = MonitoringRepository();
  final DioClient _dioClient = DioClient.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int? _extractDynamicInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  int? _extractMonitoringInsertId(dynamic responseData) {
    const candidateKeys = [
      'monitoring_id',
      'monitoringId',
      'id',
      'insertedId',
      'inserted_id',
      'insertId',
      'record_id',
    ];

    if (responseData is Map) {
      for (final key in candidateKeys) {
        final parsed = _extractDynamicInt(responseData[key]);
        if (parsed != null) return parsed;
      }

      final nestedData = responseData['data'];
      if (nestedData != null) {
        final parsed = _extractMonitoringInsertId(nestedData);
        if (parsed != null) return parsed;
      }
    }

    if (responseData is List && responseData.isNotEmpty) {
      return _extractMonitoringInsertId(responseData.first);
    }

    return _extractDynamicInt(responseData);
  }

  List<Monitoring> _monitoringList = [];
  List<Monitoring> _filteredMonitoringList = [];
  bool _isLoading = false;
  int _unsyncedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMonitoringList();
    _loadUnsyncedCount();
    _searchController.addListener(_filterMonitoring);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUnsyncedCount() async {
    try {
      final count = await _repository.getUnsyncedCount();
      if (!mounted) return;
      setState(() {
        _unsyncedCount = count;
      });
    } catch (e) {
      developer.log('Error loading unsynced count: $e',
          name: 'MonitoringScreen');
    }
  }

  Future<void> _loadMonitoringList() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _monitoringList = [];
      _filteredMonitoringList = [];
    });

    try {
      developer.log('Loading monitoring list from local database...',
          name: 'MonitoringScreen');

      // Load all monitoring records from local database
      final localData = await _repository.getAll();

      if (!mounted) return;

      // Sort: unsynced first (s_is_sync = 0), then by created date (newest first)
      localData.sort((a, b) {
        // First, sort by sync status (unsynced first)
        if (a.sIsSync != b.sIsSync) {
          return (a.sIsSync ?? 1).compareTo(b.sIsSync ?? 1);
        }
        // Then sort by created date (newest first)
        final dateA = DateTime.tryParse(a.createdDate ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b.createdDate ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _monitoringList = localData;
        _filteredMonitoringList = localData;
        _isLoading = false;
      });

      developer.log(
          'Loaded ${localData.length} monitoring records from local database',
          name: 'MonitoringScreen');

      // Update unsynced count
      await _loadUnsyncedCount();
    } catch (e) {
      developer.log('Error loading monitoring list: $e',
          name: 'MonitoringScreen');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading monitoring list: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncMonitoringToServer(Monitoring monitoring) async {
    if (monitoring.monitoringId == null && monitoring.offlineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Cannot sync monitoring because local record ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
        ),
      ),
    );

    try {
      final localIdentifier = monitoring.monitoringId ?? monitoring.offlineId;
      developer.log('Syncing monitoring record $localIdentifier to server...',
          name: 'MonitoringScreen');

      // Create FormData
      final formData = FormData.fromMap({
        'beneficiary_id': monitoring.beneficiaryId ?? '',
        'national_id': monitoring.nationalId ?? '',
        'new_device_serial_no': monitoring.newDeviceSerialNo ?? '',
        'hh_name_same': monitoring.hhNameSame ?? '',
        'stoves_present': monitoring.stovesPresent ?? '',
        'stove_being_used': monitoring.stoveBeingUsed ?? '',
        'times_used_today': monitoring.timesUsedToday ?? 0,
        'stove_condition': monitoring.stoveCondition ?? '',
        'user_satisfaction': monitoring.userSatisfaction ?? '',
        'fuel_type': monitoring.fuelType ?? '',
        'daily_fuel_cost': monitoring.dailyFuelCost ?? 0,
        'savings_3_months': monitoring.savings3Months ?? 0,
        'est_fuel_last3meals_kg': monitoring.estFuelLast3mealsKg ?? 0,
        'needs_training': monitoring.needsTraining ?? '',
        'training_type': monitoring.trainingType ?? '',
        'training_performed': monitoring.trainingPerformed ?? '',
        'needs_more_visits': monitoring.needsMoreVisits ?? '',
        'more_visits_reason': monitoring.moreVisitsReason ?? '',
        'health_hospital_less': monitoring.healthHospitalLess ?? '',
        'health_better_air': monitoring.healthBetterAir ?? '',
        'new_gps_lng': monitoring.newGpsLng ?? '',
        'new_gps_lat': monitoring.newGpsLat ?? '',
        'visit_at': monitoring.visitAt ?? '',
        'status': monitoring.status ?? 'active',
      });

      if (monitoring.photoPath != null && monitoring.photoPath!.isNotEmpty) {
        final file = File(monitoring.photoPath!);
        if (await file.exists()) {
          formData.files.add(MapEntry(
            'photo_path',
            await MultipartFile.fromFile(file.path),
          ));
          developer.log('Attached monitoring photo file: ${file.path}',
              name: 'MonitoringScreen');
        } else {
          developer.log(
              'Monitoring photo file not found: ${monitoring.photoPath}',
              name: 'MonitoringScreen');
        }
      }

      // Print the body being sent
      developer.log('=== MONITORING SYNC PAYLOAD ===',
          name: 'MonitoringScreen');
      developer.log('beneficiary_id: ${monitoring.beneficiaryId ?? ''}',
          name: 'MonitoringScreen');
      developer.log('national_id: ${monitoring.nationalId ?? ''}',
          name: 'MonitoringScreen');
      developer.log(
          'new_device_serial_no: ${monitoring.newDeviceSerialNo ?? ''}',
          name: 'MonitoringScreen');
      developer.log('hh_name_same: ${monitoring.hhNameSame ?? ''}',
          name: 'MonitoringScreen');
      developer.log('stoves_present: ${monitoring.stovesPresent ?? ''}',
          name: 'MonitoringScreen');
      developer.log('stove_being_used: ${monitoring.stoveBeingUsed ?? ''}',
          name: 'MonitoringScreen');
      developer.log('times_used_today: ${monitoring.timesUsedToday ?? 0}',
          name: 'MonitoringScreen');
      developer.log('stove_condition: ${monitoring.stoveCondition ?? ''}',
          name: 'MonitoringScreen');
      developer.log('photo_path: ${monitoring.photoPath ?? ''}',
          name: 'MonitoringScreen');
      developer.log('user_satisfaction: ${monitoring.userSatisfaction ?? ''}',
          name: 'MonitoringScreen');
      developer.log('fuel_type: ${monitoring.fuelType ?? ''}',
          name: 'MonitoringScreen');
      developer.log('daily_fuel_cost: ${monitoring.dailyFuelCost ?? 0}',
          name: 'MonitoringScreen');
      developer.log('savings_3_months: ${monitoring.savings3Months ?? 0}',
          name: 'MonitoringScreen');
      developer.log(
          'est_fuel_last3meals_kg: ${monitoring.estFuelLast3mealsKg ?? 0}',
          name: 'MonitoringScreen');
      developer.log('needs_training: ${monitoring.needsTraining ?? ''}',
          name: 'MonitoringScreen');
      developer.log('training_type: ${monitoring.trainingType ?? ''}',
          name: 'MonitoringScreen');
      developer.log('training_performed: ${monitoring.trainingPerformed ?? ''}',
          name: 'MonitoringScreen');
      developer.log('needs_more_visits: ${monitoring.needsMoreVisits ?? ''}',
          name: 'MonitoringScreen');
      developer.log('more_visits_reason: ${monitoring.moreVisitsReason ?? ''}',
          name: 'MonitoringScreen');
      developer.log(
          'health_hospital_less: ${monitoring.healthHospitalLess ?? ''}',
          name: 'MonitoringScreen');
      developer.log('health_better_air: ${monitoring.healthBetterAir ?? ''}',
          name: 'MonitoringScreen');
      developer.log('new_gps_lng: ${monitoring.newGpsLng ?? ''}',
          name: 'MonitoringScreen');
      developer.log('new_gps_lat: ${monitoring.newGpsLat ?? ''}',
          name: 'MonitoringScreen');
      developer.log('visit_at: ${monitoring.visitAt ?? ''}',
          name: 'MonitoringScreen');
      developer.log('status: ${monitoring.status ?? 'active'}',
          name: 'MonitoringScreen');
      developer.log('=== END PAYLOAD ===', name: 'MonitoringScreen');

      final response = await _dioClient.post(
        ApiConstants.monitoringSync,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final serverMonitoringId = _extractMonitoringInsertId(responseData);

        developer.log('Monitoring sync response: $responseData',
            name: 'MonitoringScreen');
        developer.log(
            'Extracted server monitoring_id: ${serverMonitoringId ?? 'null'} for local record $localIdentifier',
            name: 'MonitoringScreen');

        // Mark as synced in local database
        await _repository.markAsSynced(
          monitoringId: monitoring.monitoringId,
          offlineId: monitoring.offlineId,
          serverMonitoringId: serverMonitoringId,
        );

        developer.log('Successfully synced monitoring record $localIdentifier',
            name: 'MonitoringScreen');

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        // Reload monitoring list to update UI
        await _loadMonitoringList();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Monitoring synced successfully'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error syncing monitoring: $e', name: 'MonitoringScreen');

      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync monitoring: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterMonitoring() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMonitoringList = _monitoringList;
      } else {
        _filteredMonitoringList = _monitoringList.where((m) {
          final nationalId = (m.nationalId ?? '').toLowerCase();
          final agentName = (m.agentName ?? '').toLowerCase();
          return nationalId.contains(query) || agentName.contains(query);
        }).toList();

        // Maintain sorting: unsynced first, then by date
        _filteredMonitoringList.sort((a, b) {
          if (a.sIsSync != b.sIsSync) {
            return (a.sIsSync ?? 1).compareTo(b.sIsSync ?? 1);
          }
          final dateA =
              DateTime.tryParse(a.createdDate ?? '') ?? DateTime(1970);
          final dateB =
              DateTime.tryParse(b.createdDate ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
      }
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy • h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4EA),
      floatingActionButton: // Add Monitoring button
          FloatingActionButton.extended(
        heroTag: 'add_monitoring',
        onPressed: () async {
          final result = await context.push(AppRoutes.monitoringForm);
          if (result == true) {
            _loadMonitoringList(); // Reload list after successful save
          }
        },
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Monitoring',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
                  bottomLeft: Radius.circular(90),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.only(left: 30, top: 30),
                child: Icon(
                  Icons.sync,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Monitoring Queue',
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
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.question_mark,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Offline mode badge
                if (_unsyncedCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sync_problem,
                            color: Color(0xFF856404), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '$_unsyncedCount UNSYNCED RECORDS',
                          style: const TextStyle(
                            color: Color(0xFF856404),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Name or National ID...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Records count badge
                if (_filteredMonitoringList.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_filteredMonitoringList.length} Total Records',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Monitoring list
                Expanded(
                  child: _isLoading && _monitoringList.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredMonitoringList.isEmpty
                          ? const Center(
                              child: Text(
                                'No monitoring records found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredMonitoringList.length,
                              itemBuilder: (context, index) {
                                final monitoring =
                                    _filteredMonitoringList[index];
                                return _MonitoringCard(
                                  monitoring: monitoring,
                                  formatDate: _formatDate,
                                  onSyncTap: () =>
                                      _syncMonitoringToServer(monitoring),
                                  onEditTap: () async {
                                    if (monitoring.sIsSync == 1) return;
                                    final uri = Uri(
                                      path: AppRoutes.monitoringForm,
                                      queryParameters: {
                                        if (monitoring.offlineId != null)
                                          'offlineId':
                                              monitoring.offlineId.toString(),
                                        if (monitoring.monitoringId != null)
                                          'monitoringId': monitoring
                                              .monitoringId
                                              .toString(),
                                      },
                                    );

                                    final result = await context.push(
                                      uri.toString(),
                                      extra: monitoring,
                                    );
                                    if (result == true) {
                                      await _loadMonitoringList();
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),

          // Scroll to top button
          Positioned(
            bottom: 80,
            left: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.arrow_upward, color: Colors.black87),
            ),
          ),

          // Scroll to top button
          Positioned(
            bottom: 80,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'scroll_to_top_monitoring',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.arrow_upward, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoringCard extends StatelessWidget {
  final Monitoring monitoring;
  final String Function(String?) formatDate;
  final VoidCallback onSyncTap;
  final VoidCallback onEditTap;

  const _MonitoringCard({
    required this.monitoring,
    required this.formatDate,
    required this.onSyncTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSynced = monitoring.sIsSync == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isSynced ? const Color(0xFF4CAF50) : const Color(0xFFFFA726),
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSynced
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person_outline,
                color: isSynced
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFFA726),
                size: 28,
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'NATIONAL ID: ${monitoring.nationalId ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isSynced) ...[
                            GestureDetector(
                              onTap: onEditTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 12,
                                      color: Color(0xFF1976D2),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'EDIT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1976D2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          GestureDetector(
                            onTap: isSynced ? null : onSyncTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSynced
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSynced ? Icons.check_circle : Icons.sync,
                                    size: 12,
                                    color: isSynced
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFFFA726),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isSynced ? 'SYNCED' : 'NOT SYNCED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isSynced
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFFFA726),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 8,
                        color: Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatDate(monitoring.createdDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Serial No: ${monitoring.deviceSerialNo ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
