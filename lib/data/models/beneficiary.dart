class Beneficiary {
  final int? id;
  final int? beneficiaryId;
  final String? trainingSite;
  final int? mUserId;
  final int? mSiteId;
  final String? firstName;
  final String? lastName;
  final String? mobileNo;
  final String? otherCookstove;
  final int? femalesBelow18;
  final int? femalesAbove18;
  final int? malesBelow18;
  final int? malesAbove18;
  final String? cookingMethod;
  final String? districtName;
  final String? nationalId;
  final String? nationalIdAttachment;
  final String? housePic;
  final String? cookstovePic;
  final String? signature;
  final int? empId;
  final String? language;
  final String? readDoc;
  final String? understoodDoc;
  final String? empSign;
  final String? readToYou;
  final String? stoveStatusDelivery;
  final String? noOtherCookStovePresent;
  final String? primaryResidenceConfirmation;
  final String? cookstovePicTimestamp;
  final String? housePicTimestamp;
  final String? nationalIdTimestamp;
  final String? signatureTimestamp;
  final String? deviceSerialNo;
  final double? latitude;
  final double? longitude;
  final String? geoAddress;
  final String? createdDate;
  final int? createdBy;
  final String? modifiedDate;
  final int? modifiedBy;
  final String? status;
  final int? sIsSync;
  final int? offlineId;
  final String? serverTime;

  Beneficiary({
    this.id,
    this.beneficiaryId,
    this.trainingSite,
    this.mUserId,
    this.mSiteId,
    this.firstName,
    this.lastName,
    this.mobileNo,
    this.otherCookstove,
    this.femalesBelow18,
    this.femalesAbove18,
    this.malesBelow18,
    this.malesAbove18,
    this.cookingMethod,
    this.districtName,
    this.nationalId,
    this.nationalIdAttachment,
    this.housePic,
    this.cookstovePic,
    this.signature,
    this.empId,
    this.language,
    this.readDoc,
    this.understoodDoc,
    this.empSign,
    this.readToYou,
    this.stoveStatusDelivery,
    this.noOtherCookStovePresent,
    this.primaryResidenceConfirmation,
    this.cookstovePicTimestamp,
    this.housePicTimestamp,
    this.nationalIdTimestamp,
    this.signatureTimestamp,
    this.deviceSerialNo,
    this.latitude,
    this.longitude,
    this.geoAddress,
    this.createdDate,
    this.createdBy,
    this.modifiedDate,
    this.modifiedBy,
    this.status,
    this.sIsSync,
    this.offlineId,
    this.serverTime,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'beneficiary_id': beneficiaryId,
      'training_site': trainingSite,
      'm_user_id': mUserId,
      'm_site_id': mSiteId,
      'first_name': firstName,
      'last_name': lastName,
      'mobile_no': mobileNo,
      'other_cookstove': otherCookstove,
      'females_below_18': femalesBelow18,
      'females_above_18': femalesAbove18,
      'males_below_18': malesBelow18,
      'males_above_18': malesAbove18,
      'cooking_method': cookingMethod,
      'district_name': districtName,
      'national_id': nationalId,
      'national_id_attachment': nationalIdAttachment,
      'house_pic': housePic,
      'cookstove_pic': cookstovePic,
      'signature': signature,
      'emp_id': empId,
      'language': language,
      'read_doc': readDoc,
      'understood_doc': understoodDoc,
      'emp_sign': empSign,
      'read_to_you': readToYou,
      'stove_status_delivery': stoveStatusDelivery,
      'no_other_cook_stove_present': noOtherCookStovePresent,
      'primary_residence_confirmation': primaryResidenceConfirmation,
      'cookstove_pic_timestamp': cookstovePicTimestamp,
      'house_pic_timestamp': housePicTimestamp,
      'national_id_timestamp': nationalIdTimestamp,
      'signature_timestamp': signatureTimestamp,
      'device_serial_no': deviceSerialNo,
      'latitude': latitude,
      'longitude': longitude,
      'geo_address': geoAddress,
      'created_date': createdDate,
      'created_by': createdBy,
      'modified_date': modifiedDate,
      'modified_by': modifiedBy,
      'status': status,
      's_is_sync': sIsSync,
      'offline_id': offlineId,
      'server_time': serverTime,
    };
  }

  factory Beneficiary.fromMap(Map<String, dynamic> map) {
    return Beneficiary(
      id: map['id'] as int?,
      beneficiaryId: map['beneficiary_id'] as int?,
      trainingSite: map['training_site'] as String?,
      mUserId: map['m_user_id'] as int?,
      mSiteId: map['m_site_id'] as int?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      mobileNo: map['mobile_no'] as String?,
      otherCookstove: map['other_cookstove'] as String?,
      femalesBelow18: map['females_below_18'] as int?,
      femalesAbove18: map['females_above_18'] as int?,
      malesBelow18: map['males_below_18'] as int?,
      malesAbove18: map['males_above_18'] as int?,
      cookingMethod: map['cooking_method'] as String?,
      districtName: map['district_name'] as String?,
      nationalId: map['national_id'] as String?,
      nationalIdAttachment: map['national_id_attachment'] as String?,
      housePic: map['house_pic'] as String?,
      cookstovePic: map['cookstove_pic'] as String?,
      signature: map['signature'] as String?,
      empId: map['emp_id'] as int?,
      language: map['language'] as String?,
      readDoc: map['read_doc'] as String?,
      understoodDoc: map['understood_doc'] as String?,
      empSign: map['emp_sign'] as String?,
      readToYou: map['read_to_you'] as String?,
      stoveStatusDelivery: map['stove_status_delivery'] as String?,
      noOtherCookStovePresent: map['no_other_cook_stove_present'] as String?,
      primaryResidenceConfirmation: map['primary_residence_confirmation'] as String?,
      cookstovePicTimestamp: map['cookstove_pic_timestamp'] as String?,
      housePicTimestamp: map['house_pic_timestamp'] as String?,
      nationalIdTimestamp: map['national_id_timestamp'] as String?,
      signatureTimestamp: map['signature_timestamp'] as String?,
      deviceSerialNo: map['device_serial_no'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      geoAddress: map['geo_address'] as String?,
      createdDate: map['created_date'] as String?,
      createdBy: map['created_by'] as int?,
      modifiedDate: map['modified_date'] as String?,
      modifiedBy: map['modified_by'] as int?,
      status: map['status'] as String?,
      sIsSync: map['s_is_sync'] as int?,
      offlineId: map['offline_id'] as int?,
      serverTime: map['server_time'] as String?,
    );
  }

  // Convert to JSON for API sync (exclude offline_id)
  Map<String, dynamic> toJsonForSync() {
    return {
      if (beneficiaryId != null) 'beneficiary_id': beneficiaryId,
      'training_site': trainingSite,
      'm_user_id': mUserId,
      'm_site_id': mSiteId,
      'first_name': firstName,
      'last_name': lastName,
      'mobile_no': mobileNo,
      'other_cookstove': otherCookstove,
      'females_below_18': femalesBelow18,
      'females_above_18': femalesAbove18,
      'males_below_18': malesBelow18,
      'males_above_18': malesAbove18,
      'cooking_method': cookingMethod,
      'district_name': districtName,
      'national_id': nationalId,
      'national_id_attachment': nationalIdAttachment,
      'house_pic': housePic,
      'cookstove_pic': cookstovePic,
      'signature': signature,
      'emp_id': empId,
      'language': language,
      'read_doc': readDoc,
      'understood_doc': understoodDoc,
      'emp_sign': empSign,
      'read_to_you': readToYou,
      'stove_status_delivery': stoveStatusDelivery,
      'no_other_cook_stove_present': noOtherCookStovePresent,
      'primary_residence_confirmation': primaryResidenceConfirmation,
      'cookstove_pic_timestamp': cookstovePicTimestamp,
      'house_pic_timestamp': housePicTimestamp,
      'national_id_timestamp': nationalIdTimestamp,
      'signature_timestamp': signatureTimestamp,
      'device_serial_no': deviceSerialNo,
      'latitude': latitude,
      'longitude': longitude,
      'geo_address': geoAddress,
      'created_date': createdDate,
      'created_by': createdBy,
      'modified_date': modifiedDate,
      'modified_by': modifiedBy,
      'status': status,
      's_is_sync': sIsSync,
      // Exclude offline_id from sync - it's only for local tracking
    };
  }

  // Convert to JSON for household sync (only fields updated on EditHouseholdScreen)
  Map<String, dynamic> toJsonForHouseholdSync() {
    return {
      if (beneficiaryId != null) 'beneficiary_id': beneficiaryId,
      // Household-specific fields (updated on EditHouseholdScreen)
      'device_serial_no': deviceSerialNo,
      'latitude': latitude,
      'longitude': longitude,
      'house_pic': housePic,
      'house_pic_timestamp': housePicTimestamp,
      'cookstove_pic': cookstovePic,
      'cookstove_pic_timestamp': cookstovePicTimestamp,
      'stove_status_delivery': stoveStatusDelivery,
      'no_other_cook_stove_present': noOtherCookStovePresent,
      'primary_residence_confirmation': primaryResidenceConfirmation,
      'modified_date': modifiedDate,
      'modified_by': modifiedBy,
      'status': status,
      // Exclude offline_id from sync - it's only for local tracking
    };
  }

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int from dynamic value
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }
    
    // Helper function to safely parse double from dynamic value
    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    
    return Beneficiary(
      beneficiaryId: _parseInt(json['beneficiary_id']),
      trainingSite: json['training_site'] as String?,
      mUserId: _parseInt(json['m_user_id']),
      mSiteId: _parseInt(json['m_site_id']),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      mobileNo: json['mobile_no'] as String?,
      otherCookstove: json['other_cookstove'] as String?,
      femalesBelow18: _parseInt(json['females_below_18']),
      femalesAbove18: _parseInt(json['females_above_18']),
      malesBelow18: _parseInt(json['males_below_18']),
      malesAbove18: _parseInt(json['males_above_18']),
      cookingMethod: json['cooking_method'] as String?,
      districtName: json['district_name'] as String?,
      nationalId: json['national_id'] as String?,
      nationalIdAttachment: json['national_id_attachment'] as String?,
      housePic: json['house_pic'] as String?,
      cookstovePic: json['cookstove_pic'] as String?,
      signature: json['signature'] as String?,
      empId: _parseInt(json['emp_id']),
      language: json['language'] as String?,
      readDoc: json['read_doc'] as String?,
      understoodDoc: json['understood_doc'] as String?,
      empSign: json['emp_sign'] as String?,
      readToYou: json['read_to_you'] as String?,
      stoveStatusDelivery: json['stove_status_delivery'] as String?,
      noOtherCookStovePresent: json['no_other_cook_stove_present'] as String?,
      primaryResidenceConfirmation: json['primary_residence_confirmation'] as String?,
      cookstovePicTimestamp: json['cookstove_pic_timestamp'] as String?,
      housePicTimestamp: json['house_pic_timestamp'] as String?,
      nationalIdTimestamp: json['national_id_timestamp'] as String?,
      signatureTimestamp: json['signature_timestamp'] as String?,
      deviceSerialNo: json['device_serial_no'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      geoAddress: json['geo_address'] as String?,
      createdDate: json['created_date'] as String?,
      createdBy: _parseInt(json['created_by']),
      modifiedDate: json['modified_date'] as String?,
      modifiedBy: _parseInt(json['modified_by']),
      status: json['status'] as String?,
      sIsSync: _parseInt(json['s_is_sync']),
      serverTime: json['server_time'] as String?,
    );
  }

  Beneficiary copyWith({
    int? id,
    int? beneficiaryId,
    String? trainingSite,
    int? mUserId,
    int? mSiteId,
    String? firstName,
    String? lastName,
    String? mobileNo,
    String? otherCookstove,
    int? femalesBelow18,
    int? femalesAbove18,
    int? malesBelow18,
    int? malesAbove18,
    String? cookingMethod,
    String? districtName,
    String? nationalId,
    String? nationalIdAttachment,
    String? housePic,
    String? cookstovePic,
    String? signature,
    int? empId,
    String? language,
    String? readDoc,
    String? understoodDoc,
    String? empSign,
    String? readToYou,
    String? stoveStatusDelivery,
    String? noOtherCookStovePresent,
    String? primaryResidenceConfirmation,
    String? cookstovePicTimestamp,
    String? housePicTimestamp,
    String? nationalIdTimestamp,
    String? signatureTimestamp,
    String? deviceSerialNo,
    double? latitude,
    double? longitude,
    String? geoAddress,
    String? createdDate,
    int? createdBy,
    String? modifiedDate,
    int? modifiedBy,
    String? status,
    int? sIsSync,
    int? offlineId,
    String? serverTime,
  }) {
    return Beneficiary(
      id: id ?? this.id,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      trainingSite: trainingSite ?? this.trainingSite,
      mUserId: mUserId ?? this.mUserId,
      mSiteId: mSiteId ?? this.mSiteId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobileNo: mobileNo ?? this.mobileNo,
      otherCookstove: otherCookstove ?? this.otherCookstove,
      femalesBelow18: femalesBelow18 ?? this.femalesBelow18,
      femalesAbove18: femalesAbove18 ?? this.femalesAbove18,
      malesBelow18: malesBelow18 ?? this.malesBelow18,
      malesAbove18: malesAbove18 ?? this.malesAbove18,
      cookingMethod: cookingMethod ?? this.cookingMethod,
      districtName: districtName ?? this.districtName,
      nationalId: nationalId ?? this.nationalId,
      nationalIdAttachment: nationalIdAttachment ?? this.nationalIdAttachment,
      housePic: housePic ?? this.housePic,
      cookstovePic: cookstovePic ?? this.cookstovePic,
      signature: signature ?? this.signature,
      empId: empId ?? this.empId,
      language: language ?? this.language,
      readDoc: readDoc ?? this.readDoc,
      understoodDoc: understoodDoc ?? this.understoodDoc,
      empSign: empSign ?? this.empSign,
      readToYou: readToYou ?? this.readToYou,
      stoveStatusDelivery: stoveStatusDelivery ?? this.stoveStatusDelivery,
      noOtherCookStovePresent: noOtherCookStovePresent ?? this.noOtherCookStovePresent,
      primaryResidenceConfirmation: primaryResidenceConfirmation ?? this.primaryResidenceConfirmation,
      cookstovePicTimestamp: cookstovePicTimestamp ?? this.cookstovePicTimestamp,
      housePicTimestamp: housePicTimestamp ?? this.housePicTimestamp,
      nationalIdTimestamp: nationalIdTimestamp ?? this.nationalIdTimestamp,
      signatureTimestamp: signatureTimestamp ?? this.signatureTimestamp,
      deviceSerialNo: deviceSerialNo ?? this.deviceSerialNo,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geoAddress: geoAddress ?? this.geoAddress,
      createdDate: createdDate ?? this.createdDate,
      createdBy: createdBy ?? this.createdBy,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      status: status ?? this.status,
      sIsSync: sIsSync ?? this.sIsSync,
      offlineId: offlineId ?? this.offlineId,
      serverTime: serverTime ?? this.serverTime,
    );
  }
}
