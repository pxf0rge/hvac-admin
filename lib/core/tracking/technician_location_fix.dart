class TechnicianLocationFix {
  const TechnicianLocationFix({
    required this.technicianId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracyMeters,
    this.jobId,
    this.lastAddress,
    this.id,
  });

  final String? id;
  final String technicianId;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime recordedAt;
  final String? jobId;
  final String? lastAddress;
}
