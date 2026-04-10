class Monitoring {
  final int? monitoringId;
  final int? userId;
  final int? beneficiaryId;
  final String? nationalId;
  final String? agentName;
  final String? visitAt;
  final String? oldGpsLat;
  final String? oldGpsLng;
  final String? newGpsLat;
  final String? newGpsLng;
  final String? deviceSerialNo;
  final String? newDeviceSerialNo;
  final String? hhNameSame;
  final String? stovesPresent;
  final String? stoveBeingUsed;
  final int? timesUsedToday;
  final String? stoveCondition;
  final String? photoUrl;
  final String? nfcTagStatus;
  final String? userSatisfaction;
  final String? fuelType;
  final int? dailyFuelCost;
  final int? savings3Months;
  final int? estFuelLast3mealsKg;
  final String? needsTraining;
  final String? trainingType;
  final String? trainingPerformed;
  final String? trainingNotDoneReason;
  final String? needsMoreVisits;
  final String? moreVisitsReason;
  final String? healthHospitalLess;
  final String? healthBetterAir;
  final String? photoPath;
  final int? sIsSync;
  final String? createdDate;
  final int? createdBy;
  final String? modifiedDate;
  final int? modifiedBy;
  final String? serverTime;
  final String? status;
  final String? createdByName;
  final String? modifiedByName;

  Monitoring({
    this.monitoringId,
    this.userId,
    this.beneficiaryId,
    this.nationalId,
    this.agentName,
    this.visitAt,
    this.oldGpsLat,
    this.oldGpsLng,
    this.newGpsLat,
    this.newGpsLng,
    this.deviceSerialNo,
    this.newDeviceSerialNo,
    this.hhNameSame,
    this.stovesPresent,
    this.stoveBeingUsed,
    this.timesUsedToday,
    this.stoveCondition,
    this.photoUrl,
    this.nfcTagStatus,
    this.userSatisfaction,
    this.fuelType,
    this.dailyFuelCost,
    this.savings3Months,
    this.estFuelLast3mealsKg,
    this.needsTraining,
    this.trainingType,
    this.trainingPerformed,
    this.trainingNotDoneReason,
    this.needsMoreVisits,
    this.moreVisitsReason,
    this.healthHospitalLess,
    this.healthBetterAir,
    this.photoPath,
    this.sIsSync,
    this.createdDate,
    this.createdBy,
    this.modifiedDate,
    this.modifiedBy,
    this.serverTime,
    this.status,
    this.createdByName,
    this.modifiedByName,
  });

  factory Monitoring.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    return Monitoring(
      monitoringId: parseInt(json['monitoring_id']),
      userId: parseInt(json['user_id']),
      beneficiaryId: parseInt(json['beneficiary_id']),
      nationalId: json['national_id'] as String?,
      agentName: json['agent_name'] as String?,
      visitAt: json['visit_at'] as String?,
      oldGpsLat: json['old_gps_lat'] as String?,
      oldGpsLng: json['old_gps_lng'] as String?,
      newGpsLat: json['new_gps_lat'] as String?,
      newGpsLng: json['new_gps_lng'] as String?,
      deviceSerialNo: json['device_serial_no'] as String?,
      newDeviceSerialNo: json['new_device_serial_no'] as String?,
      hhNameSame: json['hh_name_same'] as String?,
      stovesPresent: json['stoves_present'] as String?,
      stoveBeingUsed: json['stove_being_used'] as String?,
      timesUsedToday: parseInt(json['times_used_today']),
      stoveCondition: json['stove_condition'] as String?,
      photoUrl: json['photo_url'] as String?,
      nfcTagStatus: json['nfc_tag_status'] as String?,
      userSatisfaction: json['user_satisfaction'] as String?,
      fuelType: json['fuel_type'] as String?,
      dailyFuelCost: parseInt(json['daily_fuel_cost']),
      savings3Months: parseInt(json['savings_3_months']),
      estFuelLast3mealsKg: parseInt(json['est_fuel_last3meals_kg']),
      needsTraining: json['needs_training'] as String?,
      trainingType: json['training_type'] as String?,
      trainingPerformed: json['training_performed'] as String?,
      trainingNotDoneReason: json['training_not_done_reason'] as String?,
      needsMoreVisits: json['needs_more_visits'] as String?,
      moreVisitsReason: json['more_visits_reason'] as String?,
      healthHospitalLess: json['health_hospital_less'] as String?,
      healthBetterAir: json['health_better_air'] as String?,
      photoPath: json['photo_path'] as String?,
      sIsSync: parseInt(json['s_is_sync']),
      createdDate: json['created_date'] as String?,
      createdBy: parseInt(json['created_by']),
      modifiedDate: json['modified_date'] as String?,
      modifiedBy: parseInt(json['modified_by']),
      serverTime: json['server_time'] as String?,
      status: json['status'] as String?,
      createdByName: json['created_by_name'] as String?,
      modifiedByName: json['modified_by_name'] as String?,
    );
  }

  factory Monitoring.fromMap(Map<String, dynamic> map) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    return Monitoring(
      monitoringId: parseInt(map['monitoring_id']),
      userId: parseInt(map['user_id']),
      beneficiaryId: parseInt(map['beneficiary_id']),
      nationalId: map['national_id'] as String?,
      agentName: map['agent_name'] as String?,
      visitAt: map['visit_at'] as String?,
      oldGpsLat: map['old_gps_lat']?.toString(),
      oldGpsLng: map['old_gps_lng']?.toString(),
      newGpsLat: map['new_gps_lat']?.toString(),
      newGpsLng: map['new_gps_lng']?.toString(),
      deviceSerialNo: map['device_serial_no'] as String?,
      newDeviceSerialNo: map['new_device_serial_no'] as String?,
      hhNameSame: map['hh_name_same'] as String?,
      stovesPresent: map['stoves_present'] as String?,
      stoveBeingUsed: map['stove_being_used'] as String?,
      timesUsedToday: parseInt(map['times_used_today']),
      stoveCondition: map['stove_condition'] as String?,
      photoUrl: map['photo_url'] as String?,
      nfcTagStatus: map['nfc_tag_status'] as String?,
      userSatisfaction: map['user_satisfaction'] as String?,
      fuelType: map['fuel_type'] as String?,
      dailyFuelCost: parseInt(map['daily_fuel_cost']),
      savings3Months: parseInt(map['savings_3_months']),
      estFuelLast3mealsKg: parseInt(map['est_fuel_last3meals_kg']),
      needsTraining: map['needs_training'] as String?,
      trainingType: map['training_type'] as String?,
      trainingPerformed: map['training_performed'] as String?,
      trainingNotDoneReason: map['training_not_done_reason'] as String?,
      needsMoreVisits: map['needs_more_visits'] as String?,
      moreVisitsReason: map['more_visits_reason'] as String?,
      healthHospitalLess: map['health_hospital_less'] as String?,
      healthBetterAir: map['health_better_air'] as String?,
      photoPath: map['photo_path'] as String?,
      sIsSync: parseInt(map['s_is_sync']),
      createdDate: map['created_date'] as String?,
      createdBy: parseInt(map['created_by']),
      modifiedDate: map['modified_date'] as String?,
      modifiedBy: parseInt(map['modified_by']),
      serverTime: map['server_time'] as String?,
      status: map['status'] as String?,
      createdByName: map['created_by_name'] as String?,
      modifiedByName: map['modified_by_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monitoring_id': monitoringId,
      'user_id': userId,
      'beneficiary_id': beneficiaryId,
      'national_id': nationalId,
      'agent_name': agentName,
      'visit_at': visitAt,
      'old_gps_lat': oldGpsLat,
      'old_gps_lng': oldGpsLng,
      'new_gps_lat': newGpsLat,
      'new_gps_lng': newGpsLng,
      'device_serial_no': deviceSerialNo,
      'new_device_serial_no': newDeviceSerialNo,
      'hh_name_same': hhNameSame,
      'stoves_present': stovesPresent,
      'stove_being_used': stoveBeingUsed,
      'times_used_today': timesUsedToday,
      'stove_condition': stoveCondition,
      'photo_url': photoUrl,
      'nfc_tag_status': nfcTagStatus,
      'user_satisfaction': userSatisfaction,
      'fuel_type': fuelType,
      'daily_fuel_cost': dailyFuelCost,
      'savings_3_months': savings3Months,
      'est_fuel_last3meals_kg': estFuelLast3mealsKg,
      'needs_training': needsTraining,
      'training_type': trainingType,
      'training_performed': trainingPerformed,
      'training_not_done_reason': trainingNotDoneReason,
      'needs_more_visits': needsMoreVisits,
      'more_visits_reason': moreVisitsReason,
      'health_hospital_less': healthHospitalLess,
      'health_better_air': healthBetterAir,
      'photo_path': photoPath,
      's_is_sync': sIsSync,
      'created_date': createdDate,
      'created_by': createdBy,
      'modified_date': modifiedDate,
      'modified_by': modifiedBy,
      'server_time': serverTime,
      'status': status,
    };
  }

  Monitoring copyWith({
    int? monitoringId,
    int? userId,
    int? beneficiaryId,
    String? nationalId,
    String? agentName,
    String? visitAt,
    String? oldGpsLat,
    String? oldGpsLng,
    String? newGpsLat,
    String? newGpsLng,
    String? deviceSerialNo,
    String? newDeviceSerialNo,
    String? hhNameSame,
    String? stovesPresent,
    String? stoveBeingUsed,
    int? timesUsedToday,
    String? stoveCondition,
    String? photoUrl,
    String? nfcTagStatus,
    String? userSatisfaction,
    String? fuelType,
    int? dailyFuelCost,
    int? savings3Months,
    int? estFuelLast3mealsKg,
    String? needsTraining,
    String? trainingType,
    String? trainingPerformed,
    String? trainingNotDoneReason,
    String? needsMoreVisits,
    String? moreVisitsReason,
    String? healthHospitalLess,
    String? healthBetterAir,
    String? photoPath,
    int? sIsSync,
    String? createdDate,
    int? createdBy,
    String? modifiedDate,
    int? modifiedBy,
    String? serverTime,
    String? status,
    String? createdByName,
    String? modifiedByName,
  }) {
    return Monitoring(
      monitoringId: monitoringId ?? this.monitoringId,
      userId: userId ?? this.userId,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      nationalId: nationalId ?? this.nationalId,
      agentName: agentName ?? this.agentName,
      visitAt: visitAt ?? this.visitAt,
      oldGpsLat: oldGpsLat ?? this.oldGpsLat,
      oldGpsLng: oldGpsLng ?? this.oldGpsLng,
      newGpsLat: newGpsLat ?? this.newGpsLat,
      newGpsLng: newGpsLng ?? this.newGpsLng,
      deviceSerialNo: deviceSerialNo ?? this.deviceSerialNo,
      newDeviceSerialNo: newDeviceSerialNo ?? this.newDeviceSerialNo,
      hhNameSame: hhNameSame ?? this.hhNameSame,
      stovesPresent: stovesPresent ?? this.stovesPresent,
      stoveBeingUsed: stoveBeingUsed ?? this.stoveBeingUsed,
      timesUsedToday: timesUsedToday ?? this.timesUsedToday,
      stoveCondition: stoveCondition ?? this.stoveCondition,
      photoUrl: photoUrl ?? this.photoUrl,
      nfcTagStatus: nfcTagStatus ?? this.nfcTagStatus,
      userSatisfaction: userSatisfaction ?? this.userSatisfaction,
      fuelType: fuelType ?? this.fuelType,
      dailyFuelCost: dailyFuelCost ?? this.dailyFuelCost,
      savings3Months: savings3Months ?? this.savings3Months,
      estFuelLast3mealsKg: estFuelLast3mealsKg ?? this.estFuelLast3mealsKg,
      needsTraining: needsTraining ?? this.needsTraining,
      trainingType: trainingType ?? this.trainingType,
      trainingPerformed: trainingPerformed ?? this.trainingPerformed,
      trainingNotDoneReason: trainingNotDoneReason ?? this.trainingNotDoneReason,
      needsMoreVisits: needsMoreVisits ?? this.needsMoreVisits,
      moreVisitsReason: moreVisitsReason ?? this.moreVisitsReason,
      healthHospitalLess: healthHospitalLess ?? this.healthHospitalLess,
      healthBetterAir: healthBetterAir ?? this.healthBetterAir,
      photoPath: photoPath ?? this.photoPath,
      sIsSync: sIsSync ?? this.sIsSync,
      createdDate: createdDate ?? this.createdDate,
      createdBy: createdBy ?? this.createdBy,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      serverTime: serverTime ?? this.serverTime,
      status: status ?? this.status,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
    );
  }
}

class MonitoringListResponse {
  final int currentPage;
  final int limit;
  final int start;
  final int end;
  final int totalRecords;
  final int totalPages;
  final int? nextPage;
  final int? previousPage;
  final List<Monitoring> data;

  MonitoringListResponse({
    required this.currentPage,
    required this.limit,
    required this.start,
    required this.end,
    required this.totalRecords,
    required this.totalPages,
    this.nextPage,
    this.previousPage,
    required this.data,
  });

  factory MonitoringListResponse.fromJson(Map<String, dynamic> json) {
    return MonitoringListResponse(
      currentPage: json['currentPage'] as int,
      limit: json['limit'] as int,
      start: json['start'] as int,
      end: json['end'] as int,
      totalRecords: json['totalRecords'] as int,
      totalPages: json['totalPages'] as int,
      nextPage: json['nextPage'] as int?,
      previousPage: json['previousPage'] as int?,
      data: (json['data'] as List<dynamic>)
          .map((item) => Monitoring.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
