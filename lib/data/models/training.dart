class Training {
  final int? trainingId;
  final int? trainingPointId;
  final String? trainingDate;
  final String? trainerName;
  final int? participantsCount;
  final int? malesCount;
  final int? femalesCount;
  final String? trainingType;
  final String? trainingNotes;
  final int sIsSync;
  final String? createdBy;
  final String? modifiedBy;
  final String? createdDate;
  final String? modifiedDate;
  final String status;
  final String? offlineId;
  final String? serverTime;

  Training({
    this.trainingId,
    this.trainingPointId,
    this.trainingDate,
    this.trainerName,
    this.participantsCount,
    this.malesCount,
    this.femalesCount,
    this.trainingType,
    this.trainingNotes,
    this.sIsSync = 0,
    this.createdBy,
    this.modifiedBy,
    this.createdDate,
    this.modifiedDate,
    this.status = 'active',
    this.offlineId,
    this.serverTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'training_id': trainingId,
      'training_point_id': trainingPointId,
      'training_date': trainingDate,
      'trainer_name': trainerName,
      'participants_count': participantsCount,
      'males_count': malesCount,
      'females_count': femalesCount,
      'training_type': trainingType,
      'training_notes': trainingNotes,
      's_is_sync': sIsSync,
      'created_by': createdBy,
      'modified_by': modifiedBy,
      'created_date': createdDate,
      'modified_date': modifiedDate,
      'status': status,
      'offline_id': offlineId,
      'server_time': serverTime,
    };
  }

  factory Training.fromMap(Map<String, dynamic> map) {
    return Training(
      trainingId: map['training_id'],
      trainingPointId: map['training_point_id'],
      trainingDate: map['training_date'],
      trainerName: map['trainer_name'],
      participantsCount: map['participants_count'],
      malesCount: map['males_count'],
      femalesCount: map['females_count'],
      trainingType: map['training_type'],
      trainingNotes: map['training_notes'],
      sIsSync: map['s_is_sync'] ?? 0,
      createdBy: map['created_by'],
      modifiedBy: map['modified_by'],
      createdDate: map['created_date'],
      modifiedDate: map['modified_date'],
      status: map['status'] ?? 'active',
      offlineId: map['offline_id'],
      serverTime: map['server_time'],
    );
  }

  factory Training.fromJson(Map<String, dynamic> json) => Training.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
