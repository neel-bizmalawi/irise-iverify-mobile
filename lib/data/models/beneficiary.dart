class Beneficiary {
  final int? beneficiaryId;
  final int? trainingPointId;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final int? age;
  final String? phoneNumber;
  final String? nationalId;
  final int? householdSize;
  final int? cookstovesReceived;
  final int sIsSync;
  final String? createdBy;
  final String? modifiedBy;
  final String? createdDate;
  final String? modifiedDate;
  final String status;
  final String? offlineId;
  final String? serverTime;

  Beneficiary({
    this.beneficiaryId,
    this.trainingPointId,
    this.firstName,
    this.lastName,
    this.gender,
    this.age,
    this.phoneNumber,
    this.nationalId,
    this.householdSize,
    this.cookstovesReceived,
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
      'beneficiary_id': beneficiaryId,
      'training_point_id': trainingPointId,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'age': age,
      'phone_number': phoneNumber,
      'national_id': nationalId,
      'household_size': householdSize,
      'cookstoves_received': cookstovesReceived,
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

  factory Beneficiary.fromMap(Map<String, dynamic> map) {
    return Beneficiary(
      beneficiaryId: map['beneficiary_id'],
      trainingPointId: map['training_point_id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      gender: map['gender'],
      age: map['age'],
      phoneNumber: map['phone_number'],
      nationalId: map['national_id'],
      householdSize: map['household_size'],
      cookstovesReceived: map['cookstoves_received'],
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

  factory Beneficiary.fromJson(Map<String, dynamic> json) => Beneficiary.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}
