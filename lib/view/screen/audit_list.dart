import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:irise/core/constants/api_constants.dart';
import 'package:irise/core/network/dio_client.dart';
import 'package:irise/data/models/audit.dart';
import 'package:irise/data/repositories/audit_repository.dart';
import 'package:irise/providers/dashboard_provider.dart';
import 'package:irise/route/app_routes.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:developer' as developer;

class AuditListScreen extends StatefulWidget {
  const AuditListScreen({super.key});

  @override
  State<AuditListScreen> createState() => _AuditListScreenState();
}

class _AuditListScreenState extends State<AuditListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final DioClient _dioClient = DioClient.instance;
  final AuditRepository _auditRepository = AuditRepository();

  List<Audit> _audits = [];
  List<Audit> _filteredAudits = [];
  bool _isLoading = false;
  bool _isSyncingFromServer = false;
  int _unsyncedCount = 0;

  int? _extractDynamicInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  int? _extractAuditInsertId(dynamic responseData) {
    const candidateKeys = [
      'audit_id',
      'auditId',
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
        final parsed = _extractAuditInsertId(nestedData);
        if (parsed != null) return parsed;
      }
    }

    if (responseData is List && responseData.isNotEmpty) {
      return _extractAuditInsertId(responseData.first);
    }

    return _extractDynamicInt(responseData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUnsyncedCount() async {
    try {
      final count = await _auditRepository.getUnsyncedCount();
      setState(() {
        _unsyncedCount = count;
      });
    } catch (e) {
      developer.log('Error loading unsynced count: $e', name: 'AuditList');
    }
  }

  Future<void> _loadAudits() async {
    setState(() {
      _isLoading = true;
      _audits = [];
      _filteredAudits = [];
    });

    try {
      developer.log('Loading audits from local database...', name: 'AuditList');

      // Load all audits from local database
      final audits = await _auditRepository.getAll();

      // Sort: unsynced first (s_is_sync = 0), then by created date (newest first)
      audits.sort((a, b) {
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
        _audits = audits;
        _filteredAudits = audits;
        _isLoading = false;
      });

      developer.log('Loaded ${audits.length} audits from local database',
          name: 'AuditList');

      // Update unsynced count
      await _loadUnsyncedCount();
    } catch (e) {
      developer.log('Error loading audits: $e', name: 'AuditList');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load audits: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterAudits(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAudits = _audits;
      } else {
        _filteredAudits = _audits.where((audit) {
          final householdName = audit.householdName?.toLowerCase() ?? '';
          final nationalId = audit.nationalId?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return householdName.contains(searchLower) ||
              nationalId.contains(searchLower);
        }).toList();

        // Maintain sorting: unsynced first, then by date
        _filteredAudits.sort((a, b) {
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

  Future<void> _syncFromServer() async {
    setState(() => _isSyncingFromServer = true);
    try {
      final dashboardProvider =
          Provider.of<DashboardProvider>(context, listen: false);
      final result = await dashboardProvider.syncAudit(
        onProgress: (status, current, total) {
          developer.log('Audit sync progress: $status ($current/$total)',
              name: 'AuditList');
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor:
                result.success ? const Color(0xFF4CAF50) : Colors.red,
          ),
        );
        if (result.success) {
          await _loadAudits();
        }
      }
    } catch (e) {
      developer.log('Error syncing from server: $e', name: 'AuditList');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync from server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingFromServer = false);
    }
  }

  Future<void> _syncAuditToServer(Audit audit) async {
    if (audit.auditId == null && audit.offlineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sync audit: no local or server ID found'),
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
      developer.log(
          'Syncing audit auditId=${audit.auditId} offlineId=${audit.offlineId} to server...',
          name: 'AuditList');

      // Create FormData
      final formData = FormData.fromMap({
        'household_name': audit.householdName ?? '',
        'national_id': audit.nationalId ?? '',
        'phone_number': audit.phoneNumber ?? '',
        'visit_date': audit.visitDate ?? '',
        'females_below_18': audit.femalesBelow18 ?? 0,
        'females_above_18': audit.femalesAbove18 ?? 0,
        'males_below_18': audit.malesBelow18 ?? 0,
        'males_above_18': audit.malesAbove18 ?? 0,
        'has_cookstove_observe': audit.hasCookstoveObserve ?? '',
        'cooking_method_before': audit.cookingMethodBefore ?? '',
        'fuel_used_before': audit.fuelUsedBefore ?? '',
        'other_cooking_device_before': audit.otherCookingDeviceBefore ?? '',
        'payment_requested': audit.paymentRequested ?? '',
        'payment_requested_by': audit.paymentRequestedBy ?? '',
        'training_before_receiving': audit.trainingBeforeReceiving ?? '',
        'where_trained': audit.whereTrained ?? '',
        'date_of_cookstove_recieved': audit.dateOfCookstoveRecieved ?? '',
        'where_received': audit.whereReceived ?? '',
        'read_conset': audit.readConset ?? '',
        'sign_consent': audit.signConsent ?? '',
        'delivered_condition': audit.deliveredCondition ?? '',
        'latitude': audit.latitude ?? '',
        'longitude': audit.longitude ?? '',
        'status': audit.status ?? 'active',
      });

      // Add images if they exist
      if (audit.photoPathCookStove != null &&
          audit.photoPathCookStove!.isNotEmpty) {
        final file = File(audit.photoPathCookStove!);
        if (await file.exists()) {
          formData.files.add(MapEntry(
            'cook_stove_img',
            await MultipartFile.fromFile(file.path),
          ));
        }
      }

      if (audit.photoPathCookStoveArea != null &&
          audit.photoPathCookStoveArea!.isNotEmpty) {
        final file = File(audit.photoPathCookStoveArea!);
        if (await file.exists()) {
          formData.files.add(MapEntry(
            'cook_stove_area_img',
            await MultipartFile.fromFile(file.path),
          ));
        }
      }

      final response = await _dioClient.post(
        ApiConstants.auditSync,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final serverAuditId = _extractAuditInsertId(response.data);
        // Mark as synced in local database
        await _auditRepository.markAsSynced(
          auditId: audit.auditId,
          offlineId: audit.offlineId,
          serverAuditId: serverAuditId,
        );

        developer.log(
            'Successfully synced audit auditId=${audit.auditId} offlineId=${audit.offlineId} serverAuditId=$serverAuditId',
            name: 'AuditList');

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        // Reload audits to update UI
        await _loadAudits();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audit synced successfully'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error syncing audit: $e', name: 'AuditList');

      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync audit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
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
                  bottomLeft: Radius.circular(90),
                ),
              ),
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.sync, color: Colors.white, size: 24),
                  onPressed: _loadAudits,
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
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.black87, size: 20),
                      ),
                      const Expanded(
                        child: Text(
                          'Audit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _isSyncingFromServer ? null : _syncFromServer,
                        child: _isSyncingFromServer
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF4CAF50)),
                                ),
                              )
                            : const Icon(Icons.cloud_download,
                                color: Color(0xFF4CAF50), size: 24),
                      ),
                    ],
                  ),
                ),

                // Offline mode indicator
                if (_unsyncedCount > 0)
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                // Search bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterAudits,
                    decoration: InputDecoration(
                      hintText: 'Search by Name or National ID...',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                // Records count
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_filteredAudits.length} Total Records',
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Audit list
                Expanded(
                  child: _isLoading && _audits.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF4CAF50)))
                      : _filteredAudits.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No audits found',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredAudits.length,
                              itemBuilder: (context, index) {
                                final audit = _filteredAudits[index];
                                return _AuditCard(
                                  audit: audit,
                                  formatDate: _formatDate,
                                  onSyncTap: () => _syncAuditToServer(audit),
                                  onEditTap: () async {
                                    final result = await context.push(
                                      AppRoutes.auditForm,
                                      extra: audit,
                                    );
                                    if (result == true) _loadAudits();
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),

          // Add Audit button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final result = await context.push(AppRoutes.auditForm);
                if (result == true) {
                  _loadAudits(); // Reload list after successful save
                }
              },
              backgroundColor: const Color(0xFF4CAF50),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Audit',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  final Audit audit;
  final String Function(String?) formatDate;
  final VoidCallback onSyncTap;
  final VoidCallback onEditTap;

  const _AuditCard({
    required this.audit,
    required this.formatDate,
    required this.onSyncTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSynced = audit.sIsSync == 1;

    return GestureDetector(
      onTap: onEditTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color:
                  isSynced ? const Color(0xFF4CAF50) : const Color(0xFFFFA726),
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Placeholder icon
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
                  Icons.home_outlined,
                  color: isSynced
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFFA726),
                  size: 24,
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
                        const Text(
                          'HOUSEHOLD NAME:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),
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
                    const SizedBox(height: 4),
                    Text(
                      audit.householdName ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 12, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 4),
                        Text(
                          'VISIT: ${formatDate(audit.visitDate)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
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
      ),
    );
  }
}
