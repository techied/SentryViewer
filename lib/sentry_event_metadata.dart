class SentryEventMetadata {
  DateTime timestamp;
  String city;
  String lat;
  String long;
  String reason;
  String camera;

  SentryEventMetadata({
    required this.timestamp,
    required this.city,
    required this.lat,
    required this.long,
    required this.reason,
    required this.camera,
  });

  factory SentryEventMetadata.fromJson(Map<String, dynamic> data) {
    final timestamp = DateTime.parse(data['timestamp']);
    final city = data['city'];
    final lat = data['est_lat'];
    final long = data['est_lon'];
    final reason = data['reason'];
    final camera = data['camera'];
    return SentryEventMetadata(
      timestamp: timestamp,
      city: city,
      lat: lat,
      long: long,
      reason: reason,
      camera: camera,
    );
  }

  @override
  String toString() {
    return 'SentryEventMetadata(timestamp: $timestamp, city: $city, lat: $lat, long: $long, reason: $reason, camera: $camera)';
  }
}
