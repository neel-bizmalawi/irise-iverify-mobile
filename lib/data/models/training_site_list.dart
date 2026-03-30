class TrainingSiteList {
  final int? id;
  final String trainingSite;

  TrainingSiteList({
    this.id,
    required this.trainingSite,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'training_site': trainingSite,
    };
  }

  factory TrainingSiteList.fromMap(Map<String, dynamic> map) {
    return TrainingSiteList(
      id: map['id'] as int?,
      trainingSite: map['training_site'] as String,
    );
  }

  factory TrainingSiteList.fromJson(Map<String, dynamic> json) {
    return TrainingSiteList(
      trainingSite: json['training_site'] as String,
    );
  }
}
