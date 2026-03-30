import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:irise/route/app_routes.dart';
import 'package:irise/providers/dashboard_provider.dart';
import 'package:irise/view/widgets/sync_data_bottom_sheet.dart';
import 'package:irise/data/services/data_service.dart';
import 'package:irise/core/services/connectivity_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hasShownConnectivitySnackbar = false;

  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen initializes
    _loadData();
    // Check connectivity and show snackbar if needed
    _checkInitialConnectivity();
  }

  void _checkInitialConnectivity() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasShownConnectivitySnackbar) {
        final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
        if (!connectivityService.isConnected) {
          _hasShownConnectivitySnackbar = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No internet connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
      }
    });
  }

  // This method is called when navigating back to this screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if this is not the initial build
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      body: Stack(
        children: [
          // ── Green quarter-circle top-right corner ──
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 90,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(90),
                ),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AppBar Row ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      InkWell(
                          onTap: () {
                            context.push(AppRoutes.modules);
                          },
                          child: const Icon(Icons.menu,
                              color: Colors.black87, size: 26)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ecook Stove',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      // Notification icon
                      // IconButton(
                      //   icon: const Icon(Icons.notifications_outlined,
                      //       color: Colors.black87),
                      //   onPressed: () {},
                      // ),
                      // Avatar sits over the green circle
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          radius: 20,
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ──
                Expanded(
                  child: Consumer<DashboardProvider>(
                    builder: (context, dashboardProvider, child) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          await dashboardProvider.refreshData();
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Greeting
                              const Text(
                                'Welcome to your Dashboard!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Show sync time only if data has been synced
                              // if (dashboardProvider.lastTrainingSiteSync != null)
                              //   Row(
                              //     children: [
                              //       const Icon(Icons.access_time,
                              //           size: 14, color: Color(0xFF4CAF50)),
                              //       const SizedBox(width: 4),
                              //       Text(
                              //         dashboardProvider.getLastSyncTimeDetailed('training'),
                              //         style: const TextStyle(
                              //             fontSize: 13, color: Color(0xFF4CAF50)),
                              //       ),
                              //     ],
                              //   ),
                              const SizedBox(height: 16),

                              // Training
                              _DataOverviewCard(
                                title: 'TRAINING DATA OVERVIEW',
                                leftIcon: Icons.check_circle_outline,
                                leftLabel: 'TOTAL TRAINING',
                                leftCount: dashboardProvider.totalTrainingSites.toString(),
                                leftSub: 'TOTAL TRAINING',
                                rightIcon: Icons.cloud_off_outlined,
                                rightLabel: 'OFFLINE TRAINING',
                                rightCount: dashboardProvider.unsyncedTrainingSites.toString(),
                                rightSub: 'SAVED WITHOUT SYNC',
                                lastSyncTime: dashboardProvider.getLastSyncTimeDetailed('training'),
                              ),
                              const SizedBox(height: 14),

                              // Beneficiary
                              _DataOverviewCard(
                                title: 'BENEFICIARY DATA OVERVIEW',
                                leftIcon: Icons.storage_rounded,
                                leftLabel: 'LOCAL SAVED',
                                leftCount: dashboardProvider.totalBeneficiaries.toString(),
                                leftSub: 'TOTAL RECORDS',
                                rightIcon: Icons.cloud_off_outlined,
                                rightLabel: 'OFFLINE SAVED',
                                rightCount: dashboardProvider.unsyncedBeneficiaries.toString(),
                                rightSub: 'SAVED WITHOUT SYNC',
                                lastSyncTime: dashboardProvider.getLastSyncTimeDetailed('beneficiary'),
                              ),
                              const SizedBox(height: 14),

                              // Monitoring
                              _DataOverviewCard(
                                title: 'MONITORING DATA OVERVIEW',
                                leftIcon: Icons.storage_rounded,
                                leftLabel: 'LOCAL SAVED',
                                leftCount: dashboardProvider.totalMonitoring.toString(),
                                leftSub: 'TOTAL RECORDS',
                                rightIcon: Icons.cloud_off_outlined,
                                rightLabel: 'OFFLINE SAVED',
                                rightCount: dashboardProvider.unsyncedMonitoring.toString(),
                                rightSub: 'SAVED WITHOUT SYNC',
                                lastSyncTime: dashboardProvider.getLastSyncTimeDetailed('monitoring'),
                              ),
                              const SizedBox(height: 14),

                              //Audit
                              _DataOverviewCard(
                                title: 'AUDIT DATA OVERVIEW',
                                leftIcon: Icons.storage_rounded,
                                leftLabel: 'LOCAL SAVED',
                                leftCount: dashboardProvider.totalAudit.toString(),
                                leftSub: 'TOTAL AUDIT',
                                rightIcon: Icons.cloud_off_outlined,
                                rightLabel: 'OFFLINE SAVED',
                                rightCount: dashboardProvider.unsyncedAudit.toString(),
                                rightSub: 'SAVED WITHOUT SYNC',
                                lastSyncTime: dashboardProvider.getLastSyncTimeDetailed('audit'),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
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
}

// ─────────────────────────────────────────────────────────────────────────────

class _DataOverviewCard extends StatelessWidget {
  final String title;
  final IconData leftIcon;
  final String leftLabel;
  final String leftCount;
  final String leftSub;
  final IconData rightIcon;
  final String rightLabel;
  final String rightCount;
  final String rightSub;
  final String lastSyncTime;

  const _DataOverviewCard({
    required this.title,
    required this.leftIcon,
    required this.leftLabel,
    required this.leftCount,
    required this.leftSub,
    required this.rightIcon,
    required this.rightLabel,
    required this.rightCount,
    required this.rightSub,
    required this.lastSyncTime,
  });

  void _handleSyncPressed(BuildContext context) async {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    
    // Determine module name
    String moduleName;
    
    if (title.contains('TRAINING')) {
      moduleName = 'Training';
    } else if (title.contains('BENEFICIARY')) {
      moduleName = 'Beneficiary';
    } else if (title.contains('MONITORING')) {
      moduleName = 'Monitoring';
    } else if (title.contains('AUDIT')) {
      moduleName = 'Audit';
    } else {
      moduleName = 'Data';
    }

    // Check if trying to sync Beneficiary without Training data
    if (title.contains('BENEFICIARY')) {
      // Check if training data has been synced
      if (dashboardProvider.lastTrainingSiteSync == null) {
        // Training data not synced yet - show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sync Training Data first before syncing Beneficiary Data'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    // Handle Training module with new sync logic
    if (title.contains('TRAINING')) {
      // Show sync bottom sheet with proper UI
      final result = await showSyncDataBottomSheet(
        context: context,
        moduleName: moduleName,
        onCheckForData: () async {
          // Get existing count from database
          final existingCount = dashboardProvider.totalTrainingSites;
          
          // Check if we have last sync date
          final hasLastSync = dashboardProvider.lastTrainingSiteSync != null;
          
          if (hasLastSync) {
            // Incremental sync - check if there are actually new records
            // We need to call the API to check for updates
            final lastSyncDate = dashboardProvider.lastTrainingSiteSync!.toUtc().toIso8601String();
            
            try {
              // Create DataService instance to check for updates
              final dataService = DataService();
              final response = await dataService.getUpdatedTrainingSites(lastSyncDate);
              
              if (response.success && response.data != null) {
                final newRecordsCount = response.data!.length;
                
                if (newRecordsCount > 0) {
                  // There are new records to download
                  return SyncCheckResult(
                    hasNewData: true,
                    newRecordsCount: newRecordsCount,
                    existingRecords: existingCount,
                    message: '$newRecordsCount new records available',
                  );
                } else {
                  // No new records - already up to date
                  return SyncCheckResult(
                    hasNewData: false,
                    newRecordsCount: 0,
                    existingRecords: existingCount,
                    message: 'All data is up to date',
                  );
                }
              } else {
                // Error checking for updates - assume there might be new data
                return SyncCheckResult(
                  hasNewData: true,
                  newRecordsCount: 0,
                  existingRecords: existingCount,
                  message: 'Checking for updates...',
                );
              }
            } catch (e) {
              // Error checking for updates - assume there might be new data
              return SyncCheckResult(
                hasNewData: true,
                newRecordsCount: 0,
                existingRecords: existingCount,
                message: 'Checking for updates...',
              );
            }
          } else {
            // Initial sync - need to download all data
            return SyncCheckResult(
              hasNewData: true,
              newRecordsCount: 0, // Will be determined during download
              existingRecords: existingCount,
              message: 'Initial sync required',
            );
          }
        },
        onDownload: (onProgress) async {
          try {
            // Get existing count before sync
            final existingCount = dashboardProvider.totalTrainingSites;
            
            // Track total records from server
            int totalRecordsFromServer = 0;
            
            // Perform sync with real-time progress updates
            final result = await dashboardProvider.syncTrainingSites(
              onProgress: (status, current, total) {
                // current = cumulative records downloaded so far
                // total = total records available on server
                
                if (total > 0) {
                  totalRecordsFromServer = total;
                  final remaining = total - current;
                  
                  // Update progress: existing, downloaded, remaining
                  onProgress(existingCount, current, remaining);
                }
              },
            );
            
            if (result.success) {
              // Save sync time
              await dashboardProvider.saveTrainingSyncTime();
              
              // Refresh dashboard data to get actual counts
              await dashboardProvider.refreshData();
              
              // Final progress update - all downloaded, 0 remaining
              if (totalRecordsFromServer > 0) {
                onProgress(existingCount, totalRecordsFromServer, 0);
              }
              
              return true;
            }
            
            return false;
          } catch (e) {
            return false;
          }
        },
      );

      // Show result message if sync was successful
      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$moduleName data synced successfully!'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (title.contains('BENEFICIARY')) {
      // Handle Beneficiary module with pagination sync
      final result = await showSyncDataBottomSheet(
        context: context,
        moduleName: moduleName,
        onCheckForData: () async {
          // Get existing count from database
          final existingCount = dashboardProvider.totalBeneficiaries;
          
          // Always show that we need to check for new data
          // The pagination will handle fetching all pages
          return SyncCheckResult(
            hasNewData: true,
            newRecordsCount: 0, // Will be determined during download
            existingRecords: existingCount,
            message: 'Checking for updates...',
          );
        },
        onDownload: (onProgress) async {
          try {
            // Get existing count before sync
            final existingCount = dashboardProvider.totalBeneficiaries;
            
            // Track total records from server
            int totalRecordsFromServer = 0;
            
            // Perform sync with real-time progress updates
            final result = await dashboardProvider.syncBeneficiaries(
              onProgress: (status, current, total) {
                if (total > 0) {
                  totalRecordsFromServer = total;
                  final remaining = total - current;
                  
                  // Update progress: existing, downloaded, remaining
                  onProgress(existingCount, current, remaining);
                }
              },
            );
            
            if (result.success) {
              // Refresh dashboard data to get actual counts
              await dashboardProvider.refreshData();
              
              // Final progress update - all downloaded, 0 remaining
              if (totalRecordsFromServer > 0) {
                onProgress(existingCount, totalRecordsFromServer, 0);
              }
              
              return true;
            }
            
            return false;
          } catch (e) {
            return false;
          }
        },
      );

      // Show result message if sync was successful
      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$moduleName data synced successfully!'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // For other modules, use the old sync bottom sheet
      final result = await showSyncDataBottomSheet(
        context: context,
        moduleName: moduleName,
        onCheckForData: () async {
          return SyncCheckResult(
            hasNewData: false,
            existingRecords: 0,
            message: '$moduleName sync not yet implemented',
          );
        },
        onDownload: (onProgress) async {
          return false;
        },
      );

      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$moduleName data synced successfully!'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              
            ],
          ),
          const SizedBox(height: 12),

          // Two stat boxes
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: leftIcon,
                  label: leftLabel,
                  count: leftCount,
                  sub: leftSub,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  icon: rightIcon,
                  label: rightLabel,
                  count: rightCount,
                  sub: rightSub,
                  isOffline: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Footer row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 13, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 4),
                  Text(
                    '$lastSyncTime',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _handleSyncPressed(context),
                    icon: const Icon(Icons.sync, size: 14),
                    label: const Text(
                      'Check For New Data',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                  // const SizedBox(height: 4),
                  // ElevatedButton.icon(
                  //   onPressed: () => _handleClearTrainingSites(context),
                  //   icon: const Icon(Icons.delete_sweep, size: 14),
                  //   label: const Text(
                  //     'Clear Training Sites',
                  //     style: TextStyle(fontSize: 10),
                  //   ),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.red.shade400,
                  //     foregroundColor: Colors.white,
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 8,
                  //       vertical: 6,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(16),
                  //     ),
                  //     elevation: 0,
                  //   ),
                  // ),
                  // const SizedBox(height: 4),
                  // ElevatedButton.icon(
                  //   onPressed: () => _handleTestConnectivity(context),
                  //   icon: const Icon(Icons.network_check, size: 14),
                  //   label: const Text(
                  //     'Test Connectivity',
                  //     style: TextStyle(fontSize: 10),
                  //   ),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.blue.shade400,
                  //     foregroundColor: Colors.white,
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 8,
                  //       vertical: 6,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(16),
                  //     ),
                  //     elevation: 0,
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final String sub;
  final bool isOffline;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.count,
    required this.sub,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOffline ? const Color(0xFFE65100) : const Color(0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOffline
            ? const Color(0xFFFFF3E0).withValues(alpha: 0.5)
            : const Color(0xFFF1F8F1),
        border: Border.all(
          color: isOffline
              ? const Color(0xFFE65100).withValues(alpha: 0.25)
              : const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black45,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}