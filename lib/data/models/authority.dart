class Authority {
  final int? id;
  final int? authorityId;
  final String? authorityName;
  final String? slug;
  final int? districtId;
  final String? status;

  Authority({
    this.id,
    this.authorityId,
    this.authorityName,
    this.slug,
    this.districtId,
    this.status,
  });

  factory Authority.fromJson(Map<String, dynamic> json) {
    return Authority(
      id: json['id'],
      authorityId: json['authority_id'],
      authorityName: json['authority_name'] ?? json['authorityName'],
      slug: json['slug'],
      districtId: json['district_id'] ?? json['districtId'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authority_id': authorityId,
      'authority_name': authorityName,
      'slug': slug,
      'district_id': districtId,
      'status': status,
    };
  }
}
