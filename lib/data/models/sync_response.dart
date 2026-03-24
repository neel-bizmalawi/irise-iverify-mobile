class SyncResponse {
  final bool success;
  final String? message;
  final SyncData? data;
  final String? timestamp;
  final int? syncedCount;
  final int? skippedCount;
  final int? failedCount;
  final List<dynamic>? failedRecords;
  final int? totalTraining;
  final List<Map<String, dynamic>>? mapping;

  SyncResponse({
    required this.success,
    this.message,
    this.data,
    this.timestamp,
    this.syncedCount,
    this.skippedCount,
    this.failedCount,
    this.failedRecords,
    this.totalTraining,
    this.mapping,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? SyncData.fromJson(json['data']) : null,
      timestamp: json['timestamp'],
      syncedCount: json['syncedCount'],
      skippedCount: json['skippedCount'],
      failedCount: json['failedCount'],
      failedRecords: json['failedRecords'],
      totalTraining: json['totalTraining'],
      mapping: json['mapping'] != null 
          ? (json['mapping'] as List).map((e) => e as Map<String, dynamic>).toList()
          : null,
    );
  }
}

class SyncData {
  final List<dynamic>? trainingSites;
  final List<dynamic>? beneficiaries;
  final List<dynamic>? trainings;
  final List<dynamic>? districts;
  final List<dynamic>? authorities;

  SyncData({
    this.trainingSites,
    this.beneficiaries,
    this.trainings,
    this.districts,
    this.authorities,
  });

  factory SyncData.fromJson(Map<String, dynamic> json) {
    return SyncData(
      trainingSites: json['training_sites'] ?? json['trainingSites'],
      beneficiaries: json['beneficiaries'],
      trainings: json['trainings'],
      districts: json['districts'],
      authorities: json['authorities'],
    );
  }
}
