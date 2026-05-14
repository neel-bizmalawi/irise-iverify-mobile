class Audit {
  final int? offlineId;
  final int? auditId;
  final String? householdName;
  final String? nationalId;
  final String? phoneNumber;
  final String? visitDate;
  final int? femalesBelow18;
  final int? femalesAbove18;
  final int? malesBelow18;
  final int? malesAbove18;
  final String? hasCookstoveObserve;
  final String? cookingMethodBefore;
  final String? fuelUsedBefore;
  final String? otherCookingDeviceBefore;
  final String? paymentRequested;
  final String? paymentRequestedBy;
  final String? trainingBeforeReceiving;
  final String? readConset;
  final String? signConsent;
  final String? deliveredCondition;
  final String? dateOfCookstoveRecieved;
  final String? whereReceived;
  final String? whereTrained;
  final String? latitude;
  final String? longitude;
  final String? photoPathCookStove;
  final String? photoPathCookStoveArea;
  final String? remarks;
  final int? sIsSync;
  final String? createdDate;
  final int? createdBy;
  final String? modifiedDate;
  final int? modifiedBy;
  final String? serverTime;
  final String? status;
  final String? createdByName;
  final String? modifiedByName;

  Audit({
    this.offlineId,
    this.auditId,
    this.householdName,
    this.nationalId,
    this.phoneNumber,
    this.visitDate,
    this.femalesBelow18,
    this.femalesAbove18,
    this.malesBelow18,
    this.malesAbove18,
    this.hasCookstoveObserve,
    this.cookingMethodBefore,
    this.fuelUsedBefore,
    this.otherCookingDeviceBefore,
    this.paymentRequested,
    this.paymentRequestedBy,
    this.trainingBeforeReceiving,
    this.readConset,
    this.signConsent,
    this.deliveredCondition,
    this.dateOfCookstoveRecieved,
    this.whereReceived,
    this.whereTrained,
    this.latitude,
    this.longitude,
    this.photoPathCookStove,
    this.photoPathCookStoveArea,
    this.remarks,
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

  factory Audit.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    return Audit(
      offlineId: parseInt(json['offline_id']),
      auditId: parseInt(json['audit_id']),
      householdName: json['household_name'] as String?,
      nationalId: json['national_id'] as String?,
      phoneNumber: json['phone_number'] as String?,
      visitDate: json['visit_date'] as String?,
      femalesBelow18: parseInt(json['females_below_18']),
      femalesAbove18: parseInt(json['females_above_18']),
      malesBelow18: parseInt(json['males_below_18']),
      malesAbove18: parseInt(json['males_above_18']),
      hasCookstoveObserve: json['has_cookstove_observe'] as String?,
      cookingMethodBefore: json['cooking_method_before'] as String?,
      fuelUsedBefore: json['fuel_used_before'] as String?,
      otherCookingDeviceBefore: json['other_cooking_device_before'] as String?,
      paymentRequested: json['payment_requested'] as String?,
      paymentRequestedBy: json['payment_requested_by'] as String?,
      trainingBeforeReceiving: json['training_before_receiving'] as String?,
      readConset: json['read_conset'] as String?,
      signConsent: json['sign_consent'] as String?,
      deliveredCondition: json['delivered_condition'] as String?,
      dateOfCookstoveRecieved: json['date_of_cookstove_recieved'] as String?,
      whereReceived: json['where_received'] as String?,
      whereTrained: json['where_trained'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      photoPathCookStove: json['photo_path_cook_stove'] as String?,
      photoPathCookStoveArea: json['photo_path_cook_stove_area'] as String?,
      remarks: json['remarks'] as String?,
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

  factory Audit.fromMap(Map<String, dynamic> map) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    return Audit(
      auditId: parseInt(map['audit_id']),
      offlineId: parseInt(map['offline_id']),
      householdName: map['household_name'] as String?,
      nationalId: map['national_id'] as String?,
      phoneNumber: map['phone_number'] as String?,
      visitDate: map['visit_date'] as String?,
      femalesBelow18: parseInt(map['females_below_18']),
      femalesAbove18: parseInt(map['females_above_18']),
      malesBelow18: parseInt(map['males_below_18']),
      malesAbove18: parseInt(map['males_above_18']),
      hasCookstoveObserve: map['has_cookstove_observe'] as String?,
      cookingMethodBefore: map['cooking_method_before'] as String?,
      fuelUsedBefore: map['fuel_used_before'] as String?,
      otherCookingDeviceBefore: map['other_cooking_device_before'] as String?,
      paymentRequested: map['payment_requested'] as String?,
      paymentRequestedBy: map['payment_requested_by'] as String?,
      trainingBeforeReceiving: map['training_before_receiving'] as String?,
      readConset: map['read_conset'] as String?,
      signConsent: map['sign_consent'] as String?,
      deliveredCondition: map['delivered_condition'] as String?,
      dateOfCookstoveRecieved: map['date_of_cookstove_recieved'] as String?,
      whereReceived: map['where_received'] as String?,
      whereTrained: map['where_trained'] as String?,
      latitude: map['latitude']?.toString(),
      longitude: map['longitude']?.toString(),
      photoPathCookStove: map['photo_path_cook_stove'] as String?,
      photoPathCookStoveArea: map['photo_path_cook_stove_area'] as String?,
      remarks: map['remarks'] as String?,
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
    final map = <String, dynamic>{
      'audit_id': auditId,
      'household_name': householdName,
      'national_id': nationalId,
      'phone_number': phoneNumber,
      'visit_date': visitDate,
      'females_below_18': femalesBelow18,
      'females_above_18': femalesAbove18,
      'males_below_18': malesBelow18,
      'males_above_18': malesAbove18,
      'has_cookstove_observe': hasCookstoveObserve,
      'cooking_method_before': cookingMethodBefore,
      'fuel_used_before': fuelUsedBefore,
      'other_cooking_device_before': otherCookingDeviceBefore,
      'payment_requested': paymentRequested,
      'payment_requested_by': paymentRequestedBy,
      'training_before_receiving': trainingBeforeReceiving,
      'read_conset': readConset,
      'sign_consent': signConsent,
      'delivered_condition': deliveredCondition,
      'date_of_cookstove_recieved': dateOfCookstoveRecieved,
      'where_received': whereReceived,
      'where_trained': whereTrained,
      'latitude': latitude,
      'longitude': longitude,
      'photo_path_cook_stove': photoPathCookStove,
      'photo_path_cook_stove_area': photoPathCookStoveArea,
      'remarks': remarks,
      's_is_sync': sIsSync,
      'created_date': createdDate,
      'created_by': createdBy,
      'modified_date': modifiedDate,
      'modified_by': modifiedBy,
      'server_time': serverTime,
      'status': status,
    };
    if (offlineId != null) {
      map['offline_id'] = offlineId;
    }
    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      'audit_id': auditId,
      'household_name': householdName,
      'national_id': nationalId,
      'phone_number': phoneNumber,
      'visit_date': visitDate,
      'females_below_18': femalesBelow18,
      'females_above_18': femalesAbove18,
      'males_below_18': malesBelow18,
      'males_above_18': malesAbove18,
      'has_cookstove_observe': hasCookstoveObserve,
      'cooking_method_before': cookingMethodBefore,
      'fuel_used_before': fuelUsedBefore,
      'other_cooking_device_before': otherCookingDeviceBefore,
      'payment_requested': paymentRequested,
      'payment_requested_by': paymentRequestedBy,
      'training_before_receiving': trainingBeforeReceiving,
      'read_conset': readConset,
      'sign_consent': signConsent,
      'delivered_condition': deliveredCondition,
      'date_of_cookstove_recieved': dateOfCookstoveRecieved,
      'where_received': whereReceived,
      'where_trained': whereTrained,
      'latitude': latitude,
      'longitude': longitude,
      'photo_path_cook_stove': photoPathCookStove,
      'photo_path_cook_stove_area': photoPathCookStoveArea,
      'remarks': remarks,
      's_is_sync': sIsSync,
      'created_date': createdDate,
      'created_by': createdBy,
      'modified_date': modifiedDate,
      'modified_by': modifiedBy,
      'server_time': serverTime,
      'status': status,
      'created_by_name': createdByName,
      'modified_by_name': modifiedByName,
    };
  }

  Audit copyWith({
    int? offlineId,
    int? auditId,
    String? householdName,
    String? nationalId,
    String? phoneNumber,
    String? visitDate,
    int? femalesBelow18,
    int? femalesAbove18,
    int? malesBelow18,
    int? malesAbove18,
    String? hasCookstoveObserve,
    String? cookingMethodBefore,
    String? fuelUsedBefore,
    String? otherCookingDeviceBefore,
    String? paymentRequested,
    String? paymentRequestedBy,
    String? trainingBeforeReceiving,
    String? readConset,
    String? signConsent,
    String? deliveredCondition,
    String? dateOfCookstoveRecieved,
    String? whereReceived,
    String? whereTrained,
    String? latitude,
    String? longitude,
    String? photoPathCookStove,
    String? photoPathCookStoveArea,
    String? remarks,
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
    return Audit(
      offlineId: offlineId ?? this.offlineId,
      auditId: auditId ?? this.auditId,
      householdName: householdName ?? this.householdName,
      nationalId: nationalId ?? this.nationalId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      visitDate: visitDate ?? this.visitDate,
      femalesBelow18: femalesBelow18 ?? this.femalesBelow18,
      femalesAbove18: femalesAbove18 ?? this.femalesAbove18,
      malesBelow18: malesBelow18 ?? this.malesBelow18,
      malesAbove18: malesAbove18 ?? this.malesAbove18,
      hasCookstoveObserve: hasCookstoveObserve ?? this.hasCookstoveObserve,
      cookingMethodBefore: cookingMethodBefore ?? this.cookingMethodBefore,
      fuelUsedBefore: fuelUsedBefore ?? this.fuelUsedBefore,
      otherCookingDeviceBefore:
          otherCookingDeviceBefore ?? this.otherCookingDeviceBefore,
      paymentRequested: paymentRequested ?? this.paymentRequested,
      paymentRequestedBy: paymentRequestedBy ?? this.paymentRequestedBy,
      trainingBeforeReceiving:
          trainingBeforeReceiving ?? this.trainingBeforeReceiving,
      readConset: readConset ?? this.readConset,
      signConsent: signConsent ?? this.signConsent,
      deliveredCondition: deliveredCondition ?? this.deliveredCondition,
      dateOfCookstoveRecieved:
          dateOfCookstoveRecieved ?? this.dateOfCookstoveRecieved,
      whereReceived: whereReceived ?? this.whereReceived,
      whereTrained: whereTrained ?? this.whereTrained,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoPathCookStove: photoPathCookStove ?? this.photoPathCookStove,
      photoPathCookStoveArea:
          photoPathCookStoveArea ?? this.photoPathCookStoveArea,
      remarks: remarks ?? this.remarks,
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
