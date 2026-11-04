class LocationEntity {
  final int? id;
  final String? userId;
  final double? longitude;
  final double? latitude;
  final String? displayName;
  final double? accuracy; //-- accuracy < 3.0/5.0 This means the location is very precise

  const LocationEntity(
      {this.id,
      this.longitude,
      this.latitude,
      this.displayName,
      this.userId,
      this.accuracy
      });

  @override
  String toString() =>
      "id: $id userId: $userId longitud: $longitude latitud: $latitude displayName: $displayName accuracy $accuracy";

  copyWith({
    int? id,
    String? userId,
    double? longitude,
    double? latitude,
    String? displayName,
  }) {
    return LocationEntity(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        longitude: longitude ?? this.longitude,
        latitude: latitude ?? this.latitude,
        displayName: displayName ?? this.displayName);
  }
}
