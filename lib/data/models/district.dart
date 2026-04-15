class District {
  final int? id;
  final int? districtId;
  final String? districtName;
  final String? slug;
  final String? region;
  final String? status;

  District({
    this.id,
    this.districtId,
    this.districtName,
    this.slug,
    this.region,
    this.status,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'],
      districtId: json['district_id'],
      districtName: json['district_name'] ?? json['districtName'],
      slug: json['slug'],
      region: json['region'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'district_id': districtId,
      'district_name': districtName,
      'slug': slug,
      'region': region,
      'status': status,
    };
  }
}
