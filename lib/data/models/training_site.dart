class TrainingSite {
  final int? trainingPointId;
  final String isParent;
  final int? mTrainingPointId;
  final String? trainingSite;
  final String roadAccess;
  final String? villageHeadName;
  final String? gvhName;
  final String? district;
  final String? traditionalAuthority;
  final int? totalPeople;
  final int? houseHoldsCount;
  final int? cookstovesCount;
  final int? houseHoldRadius;
  final double? latitude;
  final double? longitude;
  final int sIsSync;
  final String? trainingStatus;
  final String? conductTrainingDate;
  final int? numberOfPeoplePresent;
  final String? createdBy;
  final String? modifiedBy;
  final String? createdDate;
  final String? modifiedDate;
  final String status;
  final int? offlineId;
  final String? serverTime;

  TrainingSite({
    this.trainingPointId,
    this.isParent = 'no',
    this.mTrainingPointId,
    this.trainingSite,
    this.roadAccess = 'no',
    this.villageHeadName,
    this.gvhName,
    this.district,
    this.traditionalAuthority,
    this.totalPeople,
    this.houseHoldsCount,
    this.cookstovesCount,
    this.houseHoldRadius,
    this.latitude,
    this.longitude,
    this.sIsSync = 0,
    this.trainingStatus,
    this.conductTrainingDate,
    this.numberOfPeoplePresent,
    this.createdBy,
    this.modifiedBy,
    this.createdDate,
    this.modifiedDate,
    this.status = 'active',
    this.offlineId,
    this.serverTime,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'training_point_id': trainingPointId,
      'is_parent': isParent,
      'm_training_point_id': mTrainingPointId,
      'training_site': trainingSite,
      'road_access': roadAccess,
      'village_head_name': villageHeadName,
      'gvh_name': gvhName,
      'district': district,
      'traditional_authority': traditionalAuthority,
      'total_people': totalPeople,
      'house_holds_count': houseHoldsCount,
      'cookstoves_count': cookstovesCount,
      'house_hold_radius': houseHoldRadius,
      'latitude': latitude,
      'longitude': longitude,
      's_is_sync': sIsSync,
      'training_status': trainingStatus,
      'conduct_training_date': conductTrainingDate,
      'number_of_people_present': numberOfPeoplePresent,
      'created_by': createdBy,
      'modified_by': modifiedBy,
      'created_date': createdDate,
      'modified_date': modifiedDate,
      'status': status,
      'server_time': serverTime,
    };
    
    // Only include offline_id if it has a value
    // This allows SQLite to auto-generate it when null
    if (offlineId != null) {
      map['offline_id'] = offlineId;
    }
    
    return map;
  }

  factory TrainingSite.fromMap(Map<String, dynamic> map) {
    return TrainingSite(
      trainingPointId: map['training_point_id'],
      isParent: map['is_parent'] ?? 'no',
      mTrainingPointId: map['m_training_point_id'],
      trainingSite: map['training_site'],
      roadAccess: map['road_access'] ?? 'no',
      villageHeadName: map['village_head_name'],
      gvhName: map['gvh_name'],
      district: map['district'],
      traditionalAuthority: map['traditional_authority'],
      totalPeople: map['total_people'],
      houseHoldsCount: map['house_holds_count'],
      cookstovesCount: map['cookstoves_count'],
      houseHoldRadius: map['house_hold_radius'],
      latitude: map['latitude'] is double 
          ? map['latitude'] 
          : (map['latitude'] != null ? double.tryParse(map['latitude'].toString()) : null),
      longitude: map['longitude'] is double 
          ? map['longitude'] 
          : (map['longitude'] != null ? double.tryParse(map['longitude'].toString()) : null),
      sIsSync: map['s_is_sync'] ?? 0,
      trainingStatus: map['training_status'],
      conductTrainingDate: map['conduct_training_date'],
      numberOfPeoplePresent: map['number_of_people_present'],
      createdBy: map['created_by']?.toString(),
      modifiedBy: map['modified_by']?.toString(),
      createdDate: map['created_date'],
      modifiedDate: map['modified_date'],
      status: map['status'] ?? 'active',
      offlineId: map['offline_id'] is int ? map['offline_id'] : (map['offline_id'] != null ? int.tryParse(map['offline_id'].toString()) : null),
      serverTime: map['server_time'],
    );
  }

  factory TrainingSite.fromJson(Map<String, dynamic> json) {
    return TrainingSite(
      trainingPointId: json['training_point_id'],
      isParent: json['is_parent'] ?? 'no',
      mTrainingPointId: json['m_training_point_id'],
      trainingSite: json['training_site'],
      roadAccess: json['road_access'] ?? 'no',
      villageHeadName: json['village_head_name'],
      gvhName: json['gvh_name'],
      district: json['district'],
      traditionalAuthority: json['traditional_authority'],
      totalPeople: json['total_people'],
      houseHoldsCount: json['house_holds_count'],
      cookstovesCount: json['cookstoves_count'],
      houseHoldRadius: json['house_hold_radius'],
      latitude: json['latitude'] is double 
          ? json['latitude'] 
          : (json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null),
      longitude: json['longitude'] is double 
          ? json['longitude'] 
          : (json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null),
      sIsSync: json['s_is_sync'] ?? 0,
      trainingStatus: json['training_status'],
      conductTrainingDate: json['conduct_training_date'],
      numberOfPeoplePresent: json['number_of_people_present'],
      createdBy: json['created_by']?.toString(),
      modifiedBy: json['modified_by']?.toString(),
      createdDate: json['created_date'],
      modifiedDate: json['modified_date'],
      status: json['status'] ?? 'active',
      offlineId: json['offline_id'] is int ? json['offline_id'] : (json['offline_id'] != null ? int.tryParse(json['offline_id'].toString()) : null),
      serverTime: json['server_time'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  /// Convert to JSON for API requests (excludes certain fields)
  Map<String, dynamic> toApiJson() {
    final json = toMap();
    // Remove fields that should not be sent to the API
    json.remove('training_point_id');
    json.remove('offline_id');
    json.remove('created_by');
    json.remove('modified_by');
    json.remove('created_date');
    json.remove('server_time');
    return json;
  }

  TrainingSite copyWith({
    int? trainingPointId,
    String? isParent,
    int? mTrainingPointId,
    String? trainingSite,
    String? roadAccess,
    String? villageHeadName,
    String? gvhName,
    String? district,
    String? traditionalAuthority,
    int? totalPeople,
    int? houseHoldsCount,
    int? cookstovesCount,
    int? houseHoldRadius,
    double? latitude,
    double? longitude,
    int? sIsSync,
    String? trainingStatus,
    String? conductTrainingDate,
    int? numberOfPeoplePresent,
    String? createdBy,
    String? modifiedBy,
    String? createdDate,
    String? modifiedDate,
    String? status,
    int? offlineId,
    String? serverTime,
  }) {
    return TrainingSite(
      trainingPointId: trainingPointId ?? this.trainingPointId,
      isParent: isParent ?? this.isParent,
      mTrainingPointId: mTrainingPointId ?? this.mTrainingPointId,
      trainingSite: trainingSite ?? this.trainingSite,
      roadAccess: roadAccess ?? this.roadAccess,
      villageHeadName: villageHeadName ?? this.villageHeadName,
      gvhName: gvhName ?? this.gvhName,
      district: district ?? this.district,
      traditionalAuthority: traditionalAuthority ?? this.traditionalAuthority,
      totalPeople: totalPeople ?? this.totalPeople,
      houseHoldsCount: houseHoldsCount ?? this.houseHoldsCount,
      cookstovesCount: cookstovesCount ?? this.cookstovesCount,
      houseHoldRadius: houseHoldRadius ?? this.houseHoldRadius,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sIsSync: sIsSync ?? this.sIsSync,
      trainingStatus: trainingStatus ?? this.trainingStatus,
      conductTrainingDate: conductTrainingDate ?? this.conductTrainingDate,
      numberOfPeoplePresent: numberOfPeoplePresent ?? this.numberOfPeoplePresent,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      createdDate: createdDate ?? this.createdDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      status: status ?? this.status,
      offlineId: offlineId ?? this.offlineId,
      serverTime: serverTime ?? this.serverTime,
    );
  }
}
